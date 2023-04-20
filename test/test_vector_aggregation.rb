# frozen_string_literal: true

require 'test_helper'

class VectorFunctionTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case('unary aggregations') do
    setup do
      @boolean = Vector.new([true, true, nil])
      @boolean2 = Vector.new([true, false, nil])
      @boolean3 = Vector.new(Arrow::BooleanArray.new([nil, nil]))
      @integer = Vector.new([1, 2, 3])
      @integer2 = Vector.new([1, 2, nil])
      @double = Vector.new([1.0, -2, 3])
      @double2 = Vector.new([1, 0 / 0.0, -1 / 0.0, 1 / 0.0, nil, ''])
      @string = Vector.new(%w[A B A])
      @string2 = Vector.new(['A', 'B', nil])
    end

    test '#all' do
      assert_true @boolean.all
      assert_false @boolean.all(skip_nulls: false)
      assert_false @boolean3.all
      assert_raise(Arrow::Error::NotImplemented) { @integer.all }
      assert_raise(Arrow::Error::NotImplemented) { @double.all }
      assert_raise(Arrow::Error::NotImplemented) { @string.all }
    end

    test '#any' do
      assert_true @boolean2.any
      assert_true @boolean2.any(skip_nulls: false)
      assert_false @boolean3.any
      assert_raise(Arrow::Error::NotImplemented) { @integer.any }
      assert_raise(Arrow::Error::NotImplemented) { @double.any }
      assert_raise(Arrow::Error::NotImplemented) { @string.any }
    end

    test '#approximate_median' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.approximate_median }
      assert_equal 2, @integer.approximate_median
      assert_equal 1, @integer2.approximate_median
      assert_equal 0.0, @integer2.approximate_median(skip_nulls: false)
      assert_equal 1, @double.approximate_median
      assert_equal 0.5, @double2.approximate_median
      assert_equal 0.0, @double2.approximate_median(skip_nulls: false)
      assert_raise(Arrow::Error::NotImplemented) { @string.approximate_median }
    end

    test '#count' do
      assert_equal 2, @boolean.count
      assert_equal 2, @boolean.count(mode: :only_valid)
      assert_equal 1, @boolean.count(mode: :only_null)
      assert_equal 3, @boolean.count(mode: :all)
      assert_equal 3, @integer.count
      assert_equal 2, @integer2.count(mode: :only_valid)
      assert_equal 1, @integer2.count(mode: :only_null)
      assert_equal 3, @integer2.count(mode: :all)
      assert_equal 3, @double.count
      assert_equal 5, @double2.count(mode: :only_valid)
      assert_equal 1, @double2.count(mode: :only_null)
      assert_equal 6, @double2.count(mode: :all)
      assert_equal 3, @string.count
      assert_equal 2, @string2.count(mode: :only_valid)
      assert_equal 1, @string2.count(mode: :only_null)
      assert_equal 3, @string2.count(mode: :all)
    end

    test '#count_uniq' do
      assert_equal 1, @boolean.count_uniq
      assert_equal 1, @boolean.count_uniq(mode: :only_valid)
      assert_equal 1, @boolean.count_uniq(mode: :only_null)
      assert_equal 2, @boolean.count_uniq(mode: :all)
      assert_equal 3, @integer.count_uniq
      assert_equal 2, @integer2.count_uniq(mode: :only_valid)
      assert_equal 1, @integer2.count_uniq(mode: :only_null)
      assert_equal 3, @integer2.count_uniq(mode: :all)
      assert_equal 3, @double.count_uniq
      assert_equal 5, @double2.count_uniq(mode: :only_valid)
      assert_equal 1, @double2.count_uniq(mode: :only_null)
      assert_equal 6, @double2.count_uniq(mode: :all)
      assert_equal 2, @string.count_uniq
      assert_equal 2, @string2.count_uniq(mode: :only_valid)
      assert_equal 1, @string2.count_uniq(mode: :only_null)
      assert_equal 3, @string2.count_uniq(mode: :all)
    end

    test '#max' do
      assert_equal true, @boolean.max
      assert_equal false, @boolean.max(skip_nulls: false)
      assert_equal 3, @integer.max
      assert_equal 0, @integer2.max(skip_nulls: false)
      assert_equal 3, @double.max
      assert_equal Float::INFINITY, @double2.max
      assert_equal 0.0, @double2.max(skip_nulls: false)
      assert_equal 'B', @string.max
      assert_equal 'null', @string2.max(skip_nulls: false)
    end

    test '#mean' do
      assert_equal 1, @boolean.mean
      assert_equal 0.0, @boolean.mean(skip_nulls: false)
      assert_equal 2, @integer.mean
      assert_equal 0, @integer2.mean(skip_nulls: false)
      assert_equal 0.6666666666666666, @double.mean
      assert_true @double2.mean.nan?
      assert_equal 0.0, @double2.mean(skip_nulls: false)
      assert_raise(Arrow::Error::NotImplemented) { @string.mean }
    end

    test '#min' do
      assert_equal true, @boolean.min
      assert_equal false, @boolean.min(skip_nulls: false)
      assert_equal 1, @integer.min
      assert_equal 0, @integer2.min(skip_nulls: false)
      assert_equal(-2, @double.min)
      assert_equal(-Float::INFINITY, @double2.min)
      assert_equal 0.0, @double2.min(skip_nulls: false)
      assert_equal 'A', @string.min
      assert_equal 'null', @string2.min(skip_nulls: false)
    end

    test '#min_max' do
      assert_equal [true, true], @boolean.min_max
      assert_equal [false, false], @boolean.min_max(skip_nulls: false)
      assert_equal [1, 3], @integer.min_max
      assert_equal [0, 0], @integer2.min_max(skip_nulls: false)
      assert_equal([-2, 3], @double.min_max)
      assert_equal([-Float::INFINITY, Float::INFINITY], @double2.min_max)
      assert_equal [0.0, 0.0], @double2.min_max(skip_nulls: false)
      assert_equal %w[A B], @string.min_max
      assert_equal %w[null null], @string2.min_max(skip_nulls: false)
    end

    test '#mode' do
      assert_equal({ 'mode' => true, 'count' => 2 }, @boolean.mode)
      assert_equal({ 'mode' => 1, 'count' => 1 }, @integer.mode)
      assert_equal({ 'mode' => -2.0, 'count' => 1 }, @double.mode)
      assert_equal({ 'mode' => -Float::INFINITY, 'count' => 1 }, @double2.mode)
      assert_raise(Arrow::Error::NotImplemented) { @string.mode }
    end

    test '#product' do
      assert_equal 1, @boolean.product
      assert_equal 0, @boolean.product(skip_nulls: false)
      assert_equal 6, @integer.product
      assert_equal 0, @integer2.product(skip_nulls: false)
      assert_equal(-6, @double.product)
      assert_equal 0.0, @double2.product(skip_nulls: false)
      assert_raise(Arrow::Error::NotImplemented) { @string.product }
    end

    test '#stddev' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.stddev }
      assert_equal 0.816496580927726, @integer.stddev
      assert_equal 0.0, @integer2.stddev(skip_nulls: false)
      assert_equal 2.0548046676563256, @double.stddev
      assert_true @double2.stddev.nan?
      assert_equal 0.0, @double2.stddev(skip_nulls: false)
      assert_raise(Arrow::Error::NotImplemented) { @string.stddev }
    end

    test '#sd (unbiased version of stddev)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.sd }
      assert_equal 1.0, @integer.sd
      assert_equal 2.5166114784235836, @double.sd
      assert_true @double2.sd.nan?
      assert_raise(Arrow::Error::NotImplemented) { @string.sd }
    end

    test '#sum' do
      assert_equal 2, @boolean.sum
      assert_equal 0, @boolean.sum(skip_nulls: false)
      assert_equal 6, @integer.sum
      assert_equal 3, @integer2.sum
      assert_equal 0, @integer2.sum(skip_nulls: false)
      assert_equal 2, @double.sum
      assert_true @double2.sum.nan?
      assert_equal 0.0, @double2.sum(skip_nulls: false)
      assert_raise(Arrow::Error::NotImplemented) { @string.sum }
    end

    test '#variance' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.variance }
      assert_equal 0.6666666666666666, @integer.variance
      assert_equal 0.0, @integer2.variance(skip_nulls: false)
      assert_equal 4.222222222222222, @double.variance
      assert_true @double2.variance.nan?
      assert_equal 0.0, @double2.variance(skip_nulls: false)
      assert_raise(Arrow::Error::NotImplemented) { @string.variance }
    end

    test '#var (==unbiased_variance)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.var }
      assert_equal 1.0, @integer.var
      assert_equal 6.333333333333334, @double.var
      assert_true @double2.var.nan?
      assert_raise(Arrow::Error::NotImplemented) { @string.var }
    end
  end

  sub_test_case '#one' do
    test 'one' do
      vector = Vector.new([nil, 1, 3])
      assert_equal 1, vector.one
    end

    test 'one for nils' do
      vector = Vector.new([nil, nil, nil])
      assert_nil vector.one
    end
  end

  sub_test_case 'Quantile' do
    setup do
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, nil])
      @double = Vector.new([1.0, -2, 3])
      @double2 = Vector.new([1, 0 / 0.0, -1 / 0.0, 1 / 0.0, nil, ''])
      @string = Vector.new(%w[A B A])
    end

    test '#quantile @integer' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.quantile }
      assert_raise(Arrow::Error::NotImplemented) { @string.quantile }
      assert_equal 1.5, @integer.quantile
      assert_equal 1.5, @integer.quantile(0.5)
      assert_equal 1.0, @integer.quantile(0)
      assert_equal 2.0, @integer.quantile(1)
      assert_equal 1.75, @integer.quantile(0.75)
      assert_raise(VectorArgumentError) { @integer.quantile(1.5) }
      assert_nil @integer.quantile(skip_nulls: false)
    end

    test '#quantile @double' do
      assert_equal 2.0, @double.quantile(0.75)
      assert_equal Float::INFINITY, @double2.quantile(0.75)
      assert_nil @double2.quantile(0.75, skip_nulls: false)
      assert_equal 0.5, @double2.quantile(0.5, interpolation: :linear)
      assert_equal 0.0, @double2.quantile(0.5, interpolation: :lower)
      assert_equal 1.0, @double2.quantile(0.5, interpolation: :higher)
      assert_equal 1.0, @double2.quantile(0.5, interpolation: :nearest)
      assert_equal 0.5, @double2.quantile(0.5, interpolation: :midpoint)
    end
  end

  sub_test_case 'Quantiles' do
    setup do
      @vector = Vector.new([2, 3, 5, 7])
    end

    test '#quantiles' do
      assert_raise(VectorArgumentError) { @vector.quantiles([]) }
      assert_raise(VectorArgumentError) { @vector.quantiles([1.2]) }
      assert_equal <<~STR, @vector.quantiles.tdr_str
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 2 numeric
        # key        type   level data_preview
        0 :probs     double     5 [0.0, 0.25, 0.5, 0.75, 1.0]
        1 :quantiles double     5 [2.0, 2.75, 4.0, 5.5, 7.0]
      STR

      assert_equal <<~STR, @vector.quantiles([0.3], interpolation: :midpoint).tdr_str
        RedAmber::DataFrame : 1 x 2 Vectors
        Vectors : 2 numeric
        # key        type   level data_preview
        0 :probs     double     1 [0.3]
        1 :quantiles double     1 [2.5]
      STR
    end
  end
end
