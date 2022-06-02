# frozen_string_literal: true

require 'test_helper'

class VectorFunctionTest < Test::Unit::TestCase
  include Helper
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
      assert_false @boolean.all(opts: { skip_nulls: false })
      assert_false @boolean3.all
      assert_raise(Arrow::Error::NotImplemented) { @integer.all }
      assert_raise(Arrow::Error::NotImplemented) { @double.all }
      assert_raise(Arrow::Error::NotImplemented) { @string.all }
    end

    test '#any' do
      assert_true @boolean2.any
      assert_true @boolean2.any(opts: { skip_nulls: false })
      assert_false @boolean3.any
      assert_raise(Arrow::Error::NotImplemented) { @integer.any }
      assert_raise(Arrow::Error::NotImplemented) { @double.any }
      assert_raise(Arrow::Error::NotImplemented) { @string.any }
    end

    test '#approximate_median' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.approximate_median }
      assert_equal 2, @integer.approximate_median
      assert_equal 1, @integer2.approximate_median
      assert_equal 0.0, @integer2.approximate_median(opts: { skip_nulls: false })
      assert_equal 1, @double.approximate_median
      assert_equal 0.5, @double2.approximate_median
      assert_equal 0.0, @double2.approximate_median(opts: { skip_nulls: false })
      assert_raise(Arrow::Error::NotImplemented) { @string.approximate_median }
    end

    test '#count' do
      assert_equal 2, @boolean.count
      assert_equal 2, @boolean.count(opts: { mode: :only_valid })
      assert_equal 1, @boolean.count(opts: { mode: :only_null })
      assert_equal 3, @boolean.count(opts: { mode: :all })
      assert_equal 3, @integer.count
      assert_equal 2, @integer2.count(opts: { mode: :only_valid })
      assert_equal 1, @integer2.count(opts: { mode: :only_null })
      assert_equal 3, @integer2.count(opts: { mode: :all })
      assert_equal 3, @double.count
      assert_equal 5, @double2.count(opts: { mode: :only_valid })
      assert_equal 1, @double2.count(opts: { mode: :only_null })
      assert_equal 6, @double2.count(opts: { mode: :all })
      assert_equal 3, @string.count
      assert_equal 2, @string2.count(opts: { mode: :only_valid })
      assert_equal 1, @string2.count(opts: { mode: :only_null })
      assert_equal 3, @string2.count(opts: { mode: :all })
    end

    test '#count_uniq' do
      assert_equal 1, @boolean.count_uniq
      assert_equal 1, @boolean.count_uniq(opts: { mode: :only_valid })
      assert_equal 1, @boolean.count_uniq(opts: { mode: :only_null })
      assert_equal 2, @boolean.count_uniq(opts: { mode: :all })
      assert_equal 3, @integer.count_uniq
      assert_equal 2, @integer2.count_uniq(opts: { mode: :only_valid })
      assert_equal 1, @integer2.count_uniq(opts: { mode: :only_null })
      assert_equal 3, @integer2.count_uniq(opts: { mode: :all })
      assert_equal 3, @double.count_uniq
      assert_equal 5, @double2.count_uniq(opts: { mode: :only_valid })
      assert_equal 1, @double2.count_uniq(opts: { mode: :only_null })
      assert_equal 6, @double2.count_uniq(opts: { mode: :all })
      assert_equal 2, @string.count_uniq
      assert_equal 2, @string2.count_uniq(opts: { mode: :only_valid })
      assert_equal 1, @string2.count_uniq(opts: { mode: :only_null })
      assert_equal 3, @string2.count_uniq(opts: { mode: :all })
    end

    test '#max' do
      assert_equal true, @boolean.max
      assert_equal false, @boolean.max(opts: { skip_nulls: false })
      assert_equal 3, @integer.max
      assert_equal 0, @integer2.max(opts: { skip_nulls: false })
      assert_equal 3, @double.max
      assert_equal Float::INFINITY, @double2.max
      assert_equal 0.0, @double2.max(opts: { skip_nulls: false })
      assert_equal 'B', @string.max
      assert_equal 'null', @string2.max(opts: { skip_nulls: false })
    end

    test '#mean' do
      assert_equal 1, @boolean.mean
      assert_equal 0.0, @boolean.mean(opts: { skip_nulls: false })
      assert_equal 2, @integer.mean
      assert_equal 0, @integer2.mean(opts: { skip_nulls: false })
      assert_equal 0.6666666666666666, @double.mean
      assert_true @double2.mean.nan?
      assert_equal 0.0, @double2.mean(opts: { skip_nulls: false })
      assert_raise(Arrow::Error::NotImplemented) { @string.mean }
    end

    test '#min' do
      assert_equal true, @boolean.min
      assert_equal false, @boolean.min(opts: { skip_nulls: false })
      assert_equal 1, @integer.min
      assert_equal 0, @integer2.min(opts: { skip_nulls: false })
      assert_equal(-2, @double.min)
      assert_equal(-Float::INFINITY, @double2.min)
      assert_equal 0.0, @double2.min(opts: { skip_nulls: false })
      assert_equal 'A', @string.min
      assert_equal 'null', @string2.min(opts: { skip_nulls: false })
    end

    test '#min_max' do
      assert_equal [true, true], @boolean.min_max
      assert_equal [false, false], @boolean.min_max(opts: { skip_nulls: false })
      assert_equal [1, 3], @integer.min_max
      assert_equal [0, 0], @integer2.min_max(opts: { skip_nulls: false })
      assert_equal([-2, 3], @double.min_max)
      assert_equal([-Float::INFINITY, Float::INFINITY], @double2.min_max)
      assert_equal [0.0, 0.0], @double2.min_max(opts: { skip_nulls: false })
      assert_equal %w[A B], @string.min_max
      assert_equal %w[null null], @string2.min_max(opts: { skip_nulls: false })
    end

    test '#product' do
      assert_equal 1, @boolean.product
      assert_equal 0, @boolean.product(opts: { skip_nulls: false })
      assert_equal 6, @integer.product
      assert_equal 0, @integer2.product(opts: { skip_nulls: false })
      assert_equal(-6, @double.product)
      assert_equal 0.0, @double2.product(opts: { skip_nulls: false })
      assert_raise(Arrow::Error::NotImplemented) { @string.product }
    end

    test '#stddev' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.stddev }
      assert_equal 0.816496580927726, @integer.stddev
      assert_equal 0.0, @integer2.stddev(opts: { skip_nulls: false })
      assert_equal 2.0548046676563256, @double.stddev
      assert_true @double2.stddev.nan?
      assert_equal 0.0, @double2.stddev(opts: { skip_nulls: false })
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
      assert_equal 0, @boolean.sum(opts: { skip_nulls: false })
      assert_equal 6, @integer.sum
      assert_equal 3, @integer2.sum
      assert_equal 0, @integer2.sum(opts: { skip_nulls: false })
      assert_equal 2, @double.sum
      assert_true @double2.sum.nan?
      assert_equal 0.0, @double2.sum(opts: { skip_nulls: false })
      assert_raise(Arrow::Error::NotImplemented) { @string.sum }
    end

    test '#variance' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.variance }
      assert_equal 0.6666666666666666, @integer.variance
      assert_equal 0.0, @integer2.variance(opts: { skip_nulls: false })
      assert_equal 4.222222222222222, @double.variance
      assert_true @double2.variance.nan?
      assert_equal 0.0, @double2.variance(opts: { skip_nulls: false })
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

  sub_test_case('unary element-wise') do
    setup do
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '#-@' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.-@ }
      assert_equal_array [255, 254, 253], -@integer
      assert_equal_array [-1.0, 2.0, -3.0], -@double
      assert_raise(Arrow::Error::NotImplemented) { @string.-@ }
    end

    test '#negate' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.negate }
      assert_equal_array [255, 254, 253], @integer.negate
      assert_equal_array [-1.0, 2.0, -3.0], @double.negate
      assert_raise(Arrow::Error::NotImplemented) { @string.negate }
    end

    test '#!' do
      assert_equal_array [false, false, nil], !@boolean
      assert_raise(Arrow::Error::NotImplemented) { @integer.! }
      assert_raise(Arrow::Error::NotImplemented) { @double.! }
      assert_raise(Arrow::Error::NotImplemented) { @string.! }
    end

    test '#invert' do
      assert_equal_array [false, false, nil], @boolean.invert
      assert_raise(Arrow::Error::NotImplemented) { @integer.invert }
      assert_raise(Arrow::Error::NotImplemented) { @double.invert }
      assert_raise(Arrow::Error::NotImplemented) { @string.invert }
    end

    test '#not' do
      assert_equal_array [false, false, nil], @boolean.not
      assert_raise(Arrow::Error::NotImplemented) { @integer.not }
      assert_raise(Arrow::Error::NotImplemented) { @double.not }
      assert_raise(Arrow::Error::NotImplemented) { @string.not }
    end

    test '#abs' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.abs }
      assert_equal_array [1, 2, 3], @integer.abs
      assert_equal_array [1.0, 2.0, 3.0], @double.abs
      assert_raise(Arrow::Error::NotImplemented) { @string.abs }
    end

    test '#atan' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.atan }
      assert_equal_array_in_delta [0.7853981633974483, 1.1071487177940906, 1.2490457723982544], @integer.atan, delta = 1e-15
      assert_equal_array_in_delta [0.7853981633974483, -1.1071487177940906, 1.2490457723982544], @double.atan, delta = 1e-15
      assert_raise(Arrow::Error::NotImplemented) { @string.atan }
    end

    test '#bit_wise_not' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_not }
      assert_equal_array [254, 253, 252], @integer.bit_wise_not
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_not }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_not }
    end

    test '#cos' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.cos }
      assert_equal_array [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @integer.cos
      assert_equal_array [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @double.cos
      assert_raise(Arrow::Error::NotImplemented) { @string.cos }
    end

    test '#sign' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.sign }
      assert_equal_array [1, 1, 1], @integer.sign
      assert_equal_array [1.0, -1.0, 1.0], @double.sign
      assert_raise(Arrow::Error::NotImplemented) { @string.sign }
    end

    test '#sin' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.sin }
      assert_equal_array [0.8414709848078965, 0.9092974268256817, 0.1411200080598672], @integer.sin
      assert_equal_array [0.8414709848078965, -0.9092974268256817, 0.1411200080598672], @double.sin
      assert_raise(Arrow::Error::NotImplemented) { @string.sin }
    end

    test '#tan' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.tan }
      assert_equal_array_in_delta [1.557407724654902, -2.185039863261519, -0.1425465430742778], @integer.tan, delta = 1e-15
      assert_equal_array_in_delta [1.557407724654902, 2.185039863261519, -0.1425465430742778], @double.tan, delta = 1e-15
      assert_raise(Arrow::Error::NotImplemented) { @string.tan }
    end
  end

  sub_test_case('unary element-wise rounding') do
    setup do
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([15.15, 2.5, 3.5, -4.5, -5.5])
      @string = Vector.new(%w[A B A])
    end

    test '#ceil' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.ceil }
      assert_equal_array [1, 2, 3], @integer.ceil
      assert_equal_array [16.0, 3.0, 4.0, -4.0, -5.0], @double.ceil
      assert_equal_array @double.ceil, @double.round(opts: { mode: :up })
      assert_raise(Arrow::Error::NotImplemented) { @string.ceil }
    end

    test '#floor' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.floor }
      assert_equal_array [1, 2, 3], @integer.floor
      assert_equal_array [15.0, 2.0, 3.0, -5.0, -6.0], @double.floor
      assert_equal_array @double.floor, @double.round(opts: { mode: :down })
      assert_equal_array @double.floor, @double.round(opts: { mode: :half_down })
      assert_raise(Arrow::Error::NotImplemented) { @string.floor }
    end

    test '#round' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.round }
      assert_equal_array [1, 2, 3], @integer.round

      assert_equal_array [15.0, 2.0, 4.0, -4.0, -6.0], @double.round
      assert_equal_array @double.round, @double.round(opts: { mode: :half_to_even })
      assert_equal_array [16.0, 3.0, 4.0, -5.0, -6.0], @double.round(opts: { mode: :towards_infinity })
      assert_equal_array [15.0, 3.0, 4.0, -4.0, -5.0], @double.round(opts: { mode: :half_up })
      assert_equal_array [15.0, 2.0, 3.0, -4.0, -5.0], @double.round(opts: { mode: :half_towards_zero })
      assert_equal_array [15.0, 3.0, 4.0, -5.0, -6.0], @double.round(opts: { mode: :half_towards_infinity })
      assert_equal_array [15.0, 3.0, 3.0, -5.0, -5.0], @double.round(opts: { mode: :half_to_odd })

      assert_equal_array @double.round, @double.round(opts: { n_digits: 0 })
      assert_equal_array [15.2, 2.5, 3.5, -4.5, -5.5], @double.round(opts: { n_digits: 1 })
      assert_equal_array [20.0, 0.0, 0.0, -0.0, -10.0], @double.round(opts: { n_digits: -1 })

      assert_raise(Arrow::Error::NotImplemented) { @string.round }
    end

    test '#round_to_multiple' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.round_to_multiple }
      assert_equal_array [1, 2, 3], @integer.round_to_multiple
      assert_equal_array @double.round, @double.round_to_multiple
      multiple = Arrow::DoubleScalar.new(1)
      assert_equal_array @double.round_to_multiple, @double.round_to_multiple(opts: { multiple: multiple })
      multiple = Arrow::DoubleScalar.new(0.1)
      assert_equal_array [15.200000000000001, 2.5, 3.5, -4.5, -5.5], @double.round_to_multiple(opts: { multiple: multiple })
      multiple = Arrow::DoubleScalar.new(10)
      assert_equal_array [20.0, 0.0, 0.0, -0.0, -10.0], @double.round_to_multiple(opts: { multiple: multiple })
      multiple = Arrow::DoubleScalar.new(2)
      assert_equal_array [16.0, 2.0, 4.0, -4.0, -6.0], @double.round_to_multiple(opts: { multiple: multiple })
      assert_raise(Arrow::Error::NotImplemented) { @string.round_to_multiple }
    end

    test '#trunc' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.trunc }
      assert_equal_array [1, 2, 3], @integer.trunc
      assert_equal_array [15.0, 2.0, 3.0, -4.0, -5.0], @double.trunc
      assert_equal_array @double.trunc, @double.round(opts: { mode: :towards_zero })
      assert_raise(Arrow::Error::NotImplemented) { @string.trunc }
    end
  end

  sub_test_case('unary element-wise categorizations') do
    setup do
      @boolean = Vector.new([true, false, true, false, nil])
      @integer = Vector.new([0, 1, -2, 3, nil])
      @double = Vector.new([Math::PI, Float::INFINITY, -Float::INFINITY, Float::NAN, nil])
      @string = Vector.new(['A', 'B', ' ', '', nil])
    end

    test '#is_finite' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.is_finite }
      assert_equal_array [true, true, true, true, nil], @integer.is_finite
      assert_equal_array [true, false, false, false, nil], @double.is_finite
      assert_raise(Arrow::Error::NotImplemented) { @string.is_finite }
    end

    test '#is_inf' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.is_inf }
      assert_equal_array [false, false, false, false, nil], @integer.is_inf
      assert_equal_array [false, true, true, false, nil], @double.is_inf
      assert_raise(Arrow::Error::NotImplemented) { @string.is_inf }
    end

    test '#is_na' do
      assert_equal_array [false, false, false, false, true], @boolean.is_na
      assert_equal_array [false, false, false, false, true], @integer.is_na
      assert_equal_array [false, false, false, true, true], @double.is_na
      assert_equal_array [false, false, false, false, true], @string.is_na
    end

    test '#is_nan' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.is_nan }
      assert_equal_array [false, false, false, false, nil], @integer.is_nan
      assert_equal_array [false, false, false, true, nil], @double.is_nan
      assert_raise(Arrow::Error::NotImplemented) { @string.is_nan }
    end

    test '#is_nil' do
      assert_equal_array [false, false, false, false, true], @boolean.is_nil
      assert_equal_array [false, false, false, false, true], @integer.is_nil
      assert_equal_array [false, false, false, false, true], @double.is_nil
      assert_equal_array [false, false, false, false, true], @string.is_nil
    end

    test '#is_valid' do
      assert_equal_array [true, true, true, true, false], @boolean.is_valid
      assert_equal_array [true, true, true, true, false], @integer.is_valid
      assert_equal_array [true, true, true, true, false], @double.is_valid
      assert_equal_array [true, true, true, true, false], @string.is_valid
    end
  end

  sub_test_case('binary element-wise') do
    setup do
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '#atan2(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.atan2(@boolean) }
      assert_equal_array_in_delta [0.7853981633974483, 0.7853981633974483, 0.7853981633974483], @integer.atan2(@integer), delta = 1e-15
      assert_equal_array_in_delta [0.7853981633974483, -2.356194490192345, 0.7853981633974483], @double.atan2(@double), delta = 1e-15
      assert_raise(Arrow::Error::NotImplemented) { @string.atan2(@string) }
    end

    test '#and_not(vector)' do
      assert_equal_array [false, false, nil], @boolean.and_not(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_not(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_not(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_not(@string) }
    end

    test '#and_not_kleene(vector)' do
      assert_equal_array [false, false, nil], @boolean.and_not_kleene(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_not_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_not_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_not_kleene(@string) }
    end

    test '#bit_wise_and(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_and(@boolean) }
      assert_equal_array [1, 2, 3], @integer.bit_wise_and(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_and(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_and(@string) }
    end

    test '#bit_wise_or(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_or(@boolean) }
      assert_equal_array [1, 2, 3], @integer.bit_wise_or(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_or(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_or(@string) }
    end

    test '#bit_wise_xor(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_xor(@boolean) }
      assert_equal_array [0, 0, 0], @integer.bit_wise_xor(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_xor(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_xor(@string) }
    end
  end

  sub_test_case('binary element-wise with operator') do
    setup do
      @bool_self = Vector.new([true, true, true, false, false, false, nil, nil, nil])
      @bool_other = Vector.new([true, false, nil, true, false, nil, true, false, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '#&(vector)' do
      assert_equal_array([true, false, nil, false, false, false, nil, false, nil],
                         @bool_self & @bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer & @integer }
      assert_raise(Arrow::Error::NotImplemented) { @double & @double }
      assert_raise(Arrow::Error::NotImplemented) { @string & @string }
    end

    test '#and_kleene(vector)' do
      assert_equal_array [true, false, nil, false, false, false, nil, false, nil],
                         @bool_self.and_kleene(@bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_kleene(@string) }
    end

    test '#and_org(vector)' do
      assert_equal_array [true, false, nil, false, false, nil, nil, nil, nil],
                         @bool_self.and_org(@bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_org(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_org(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_org(@string) }
    end

    test '#|(vector)' do
      assert_equal_array([true, true, true, true, false, nil, true, nil, nil],
                         @bool_self | @bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer | @integer }
      assert_raise(Arrow::Error::NotImplemented) { @double | @double }
      assert_raise(Arrow::Error::NotImplemented) { @string | @string }
    end

    test '#or_kleene(vector)' do
      assert_equal_array [true, true, true, true, false, nil, true, nil, nil],
                         @bool_self.or_kleene(@bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer.or_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.or_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.or_kleene(@string) }
    end

    test '#or_org(vector)' do
      assert_equal_array [true, true, nil, true, false, nil, nil, nil, nil],
                         @bool_self.or_org(@bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer.or_org(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.or_org(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.or_org(@string) }
    end
  end

  sub_test_case('binary element-wise with operator') do
    setup do
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '#add(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.add(@boolean) }
      assert_equal_array [2, 4, 6], @integer.add(@integer)
      assert_equal_array [2.0, -4.0, 6.0], @double.add(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.add(@string) }
    end

    test '#+(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.+(@boolean) }
      assert_equal_array [2, 4, 6], @integer.+(@integer)
      assert_equal_array [2.0, -4.0, 6.0], @double.+(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.+(@string) }
    end

    test '#divide(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.divide(@boolean) }
      assert_equal_array [1, 1, 1], @integer.divide(@integer)
      assert_equal_array [1.0, 1.0, 1.0], @double.divide(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.divide(@string) }
    end

    test '#/(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean./(@boolean) }
      assert_equal_array [1, 1, 1], @integer./(@integer)
      assert_equal_array [1.0, 1.0, 1.0], @double./(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string./(@string) }
    end

    test '#multiply(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.multiply(@boolean) }
      assert_equal_array [1, 4, 9], @integer.multiply(@integer)
      assert_equal_array [1.0, 4.0, 9.0], @double.multiply(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.multiply(@string) }
    end

    test '#*(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.*(@boolean) }
      assert_equal_array [1, 4, 9], @integer.*(@integer)
      assert_equal_array [1.0, 4.0, 9.0], @double.*(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.*(@string) }
    end

    test '#power(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.power(@boolean) }
      assert_equal_array [1, 4, 27], @integer.power(@integer)
      assert_equal_array [1.0, 0.25, 27.0], @double.power(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.power(@string) }
    end

    test '#**(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.**(@boolean) }
      assert_equal_array [1, 4, 27], @integer.**(@integer)
      assert_equal_array [1.0, 0.25, 27.0], @double.**(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.**(@string) }
    end

    test '#subtract(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.subtract(@boolean) }
      assert_equal_array [0, 0, 0], @integer.subtract(@integer)
      assert_equal_array [0.0, 0.0, 0.0], @double.subtract(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.subtract(@string) }
    end

    test '#-(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.-(@boolean) }
      assert_equal_array [0, 0, 0], @integer.-(@integer)
      assert_equal_array [0.0, 0.0, 0.0], @double.-(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.-(@string) }
    end

    test '#shift_left(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.shift_left(@boolean) }
      assert_equal_array [2, 8, 24], @integer.shift_left(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.shift_left(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.shift_left(@string) }
    end

    test '#<<(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.<<(@boolean) }
      assert_equal_array [2, 8, 24], @integer.<<(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.<<(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.<<(@string) }
    end

    test '#shift_right(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.shift_right(@boolean) }
      assert_equal_array [0, 0, 0], @integer.shift_right(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.shift_right(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.shift_right(@string) }
    end

    test '#>>(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.>>(@boolean) }
      assert_equal_array [0, 0, 0], @integer.>>(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.>>(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.>>(@string) }
    end

    test '#xor(vector)' do
      assert_equal_array [false, false, nil], @boolean.xor(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.xor(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.xor(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.xor(@string) }
    end

    test '#^(vector)' do
      assert_equal_array [false, false, nil], @boolean.xor(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.xor(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.xor(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.xor(@string) }
    end

    test '#equal(vector)' do
      assert_equal_array [true, true, nil], @boolean.equal(@boolean)
      assert_equal_array [true, true, true], @integer.equal(@integer)
      assert_equal_array [true, true, true], @double.equal(@double)
      assert_equal_array [true, true, true], @string.equal(@string)
    end

    test '#equal(scalar)' do
      assert_equal_array [true, true, nil], @boolean.equal(true)
      assert_equal_array [false, false, nil], @boolean.equal(false)
      assert_equal_array [true, false, false], @integer.equal(1)
      assert_equal_array [true, false, false], @double.equal(1.0)
      assert_equal_array [true, false, true], @string.equal('A')
    end

    test '#eq(vector)' do
      assert_equal_array [true, true, nil], @boolean.eq(@boolean)
      assert_equal_array [true, true, true], @integer.eq(@integer)
      assert_equal_array [true, true, true], @double.eq(@double)
      assert_equal_array [true, true, true], @string.eq(@string)
    end

    test '#==(vector)' do
      assert_equal_array [true, true, nil], @boolean.==(@boolean)
      assert_equal_array [true, true, true], @integer.==(@integer)
      assert_equal_array [true, true, true], @double.==(@double)
      assert_equal_array [true, true, true], @string.==(@string)
    end

    test '#greater(vector)' do
      assert_equal_array [false, false, nil], @boolean.greater(@boolean)
      assert_equal_array [false, false, false], @integer.greater(@integer)
      assert_equal_array [false, false, false], @double.greater(@double)
      assert_equal_array [false, false, false], @string.greater(@string)
    end

    test '#gt(vector)' do
      assert_equal_array [false, false, nil], @boolean.gt(@boolean)
      assert_equal_array [false, false, false], @integer.gt(@integer)
      assert_equal_array [false, false, false], @double.gt(@double)
      assert_equal_array [false, false, false], @string.gt(@string)
    end

    test '#>(vector)' do
      assert_equal_array [false, false, nil], @boolean.>(@boolean)
      assert_equal_array [false, false, false], @integer.>(@integer)
      assert_equal_array [false, false, false], @double.>(@double)
      assert_equal_array [false, false, false], @string.>(@string)
    end

    test '#greater_equal(vector)' do
      assert_equal_array [true, true, nil], @boolean.greater_equal(@boolean)
      assert_equal_array [true, true, true], @integer.greater_equal(@integer)
      assert_equal_array [true, true, true], @double.greater_equal(@double)
      assert_equal_array [true, true, true], @string.greater_equal(@string)
    end

    test '#ge(vector)' do
      assert_equal_array [true, true, nil], @boolean.ge(@boolean)
      assert_equal_array [true, true, true], @integer.ge(@integer)
      assert_equal_array [true, true, true], @double.ge(@double)
      assert_equal_array [true, true, true], @string.ge(@string)
    end

    test '#>=(vector)' do
      assert_equal_array [true, true, nil], @boolean.>=(@boolean)
      assert_equal_array [true, true, true], @integer.>=(@integer)
      assert_equal_array [true, true, true], @double.>=(@double)
      assert_equal_array [true, true, true], @string.>=(@string)
    end

    test '#less(vector)' do
      assert_equal_array [false, false, nil], @boolean.less(@boolean)
      assert_equal_array [false, false, false], @integer.less(@integer)
      assert_equal_array [false, false, false], @double.less(@double)
      assert_equal_array [false, false, false], @string.less(@string)
    end

    test '#less(scalar)' do
      assert_equal_array [false, false, nil], @boolean.less(true)
      assert_equal_array [false, false, nil], @boolean.less(false)
      assert_equal_array [true, false, false], @integer.less(2)
      assert_equal_array [true, true, false], @double.less(2.0)
      assert_equal_array [true, false, true], @string.less('B')
    end

    test '#lt(vector)' do
      assert_equal_array [false, false, nil], @boolean.lt(@boolean)
      assert_equal_array [false, false, false], @integer.lt(@integer)
      assert_equal_array [false, false, false], @double.lt(@double)
      assert_equal_array [false, false, false], @string.lt(@string)
    end

    test '#<(vector)' do
      assert_equal_array [false, false, nil], @boolean.<(@boolean)
      assert_equal_array [false, false, false], @integer.<(@integer)
      assert_equal_array [false, false, false], @double.<(@double)
      assert_equal_array [false, false, false], @string.<(@string)
    end

    test '#less_equal(vector)' do
      assert_equal_array [true, true, nil], @boolean.less_equal(@boolean)
      assert_equal_array [true, true, true], @integer.less_equal(@integer)
      assert_equal_array [true, true, true], @double.less_equal(@double)
      assert_equal_array [true, true, true], @string.less_equal(@string)
    end

    test '#le(vector)' do
      assert_equal_array [true, true, nil], @boolean.le(@boolean)
      assert_equal_array [true, true, true], @integer.le(@integer)
      assert_equal_array [true, true, true], @double.le(@double)
      assert_equal_array [true, true, true], @string.le(@string)
    end

    test '#<=(vector)' do
      assert_equal_array [true, true, nil], @boolean.<=(@boolean)
      assert_equal_array [true, true, true], @integer.<=(@integer)
      assert_equal_array [true, true, true], @double.<=(@double)
      assert_equal_array [true, true, true], @string.<=(@string)
    end

    test '#not_equal(vector)' do
      assert_equal_array [false, false, nil], @boolean.not_equal(@boolean)
      assert_equal_array [false, false, false], @integer.not_equal(@integer)
      assert_equal_array [false, false, false], @double.not_equal(@double)
      assert_equal_array [false, false, false], @string.not_equal(@string)
    end

    test '#ne(vector)' do
      assert_equal_array [false, false, nil], @boolean.ne(@boolean)
      assert_equal_array [false, false, false], @integer.ne(@integer)
      assert_equal_array [false, false, false], @double.ne(@double)
      assert_equal_array [false, false, false], @string.ne(@string)
    end

    test '#!=(vector)' do
      assert_equal_array [false, false, nil], @boolean != @boolean
      assert_equal_array [false, false, false], @integer != @integer
      assert_equal_array [false, false, false], @double != @double
      assert_equal_array [false, false, false], @string != @string
    end
  end

  sub_test_case('module_function .arrow_doc') do
    test 'add' do
      expected = <<~OUT
        add(x, y): Add the arguments element-wise
        ---
        Results will wrap around on integer overflow.
        Use function \"add_checked\" if you want overflow
        to return an error.
      OUT
      assert_equal expected.chomp, VectorFunctions.arrow_doc(:add).to_s
    end
  end
end
