# frozen_string_literal: true

require 'test_helper'

class VectorFunctionTest < Test::Unit::TestCase
  include Helper
  include RedAmber

  sub_test_case('unary aggregations') do
    def setup
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '#all' do
      assert_equal true, @boolean.all.value
      assert_raise(Arrow::Error::NotImplemented) { @integer.all }
      assert_raise(Arrow::Error::NotImplemented) { @double.all }
      assert_raise(Arrow::Error::NotImplemented) { @string.all }
    end

    test '#any' do
      assert_equal true, @boolean.any.value
      assert_raise(Arrow::Error::NotImplemented) { @integer.any }
      assert_raise(Arrow::Error::NotImplemented) { @double.any }
      assert_raise(Arrow::Error::NotImplemented) { @string.any }
    end

    test '#approximate_median' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.approximate_median }
      assert_equal 2, @integer.approximate_median.value
      assert_equal 1, @double.approximate_median.value
      assert_raise(Arrow::Error::NotImplemented) { @string.approximate_median }
    end

    test '#count' do
      assert_equal 2, @boolean.count.value
      assert_equal 3, @integer.count.value
      assert_equal 3, @double.count.value
      assert_equal 3, @string.count.value
    end

    test '#count_distinct' do
      assert_equal 1, @boolean.count_distinct.value
      assert_equal 3, @integer.count_distinct.value
      assert_equal 3, @double.count_distinct.value
      assert_equal 2, @string.count_distinct.value
    end

    test '#max' do
      assert_equal true, @boolean.max.value
      assert_equal 3, @integer.max.value
      assert_equal 3, @double.max.value
      assert_equal 'B', @string.max.to_s
    end

    test '#mean' do
      assert_equal 1, @boolean.mean.value
      assert_equal 2, @integer.mean.value
      assert_equal 0.6666666666666666, @double.mean.value
      assert_raise(Arrow::Error::NotImplemented) { @string.mean }
    end

    test '#min' do
      assert_equal true, @boolean.min.value
      assert_equal 1, @integer.min.value
      assert_equal(-2, @double.min.value)
      assert_equal 'A', @string.min.to_s
    end

    test '#product' do
      assert_equal 1, @boolean.product.value
      assert_equal 6, @integer.product.value
      assert_equal(-6, @double.product.value)
      assert_raise(Arrow::Error::NotImplemented) { @string.product }
    end

    test '#stddev' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.stddev }
      assert_equal 0.816496580927726, @integer.stddev.value
      assert_equal 2.0548046676563256, @double.stddev.value
      assert_raise(Arrow::Error::NotImplemented) { @string.stddev }
    end

    test '#sum' do
      assert_equal 2, @boolean.sum.value
      assert_equal 6, @integer.sum.value
      assert_equal 2, @double.sum.value
      assert_raise(Arrow::Error::NotImplemented) { @string.sum }
    end

    test '#variance' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.variance }
      assert_equal 0.6666666666666666, @integer.variance.value
      assert_equal 4.222222222222222, @double.variance.value
      assert_raise(Arrow::Error::NotImplemented) { @string.variance }
    end
  end

  sub_test_case('unary element-wise') do
    def setup
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '#-@' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.-@ }
      assert_equal [255, 254, 253], @integer.-@.to_a
      assert_equal [-1.0, 2.0, -3.0], @double.-@.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.-@ }
    end

    test '#negate' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.negate }
      assert_equal [255, 254, 253], @integer.negate.to_a
      assert_equal [-1.0, 2.0, -3.0], @double.negate.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.negate }
    end

    test '#abs' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.abs }
      assert_equal [1, 2, 3], @integer.abs.to_a
      assert_equal [1.0, 2.0, 3.0], @double.abs.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.abs }
    end

    test '#atan' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.atan }
      assert_equal_array_in_delta [0.7853981633974483, 1.1071487177940906, 1.2490457723982544], @integer.atan, delta = 1e-15
      assert_equal_array_in_delta [0.7853981633974483, -1.1071487177940906, 1.2490457723982544], @double.atan, delta = 1e-15
      assert_raise(Arrow::Error::NotImplemented) { @string.atan }
    end

    test '#ceil' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.ceil }
      assert_equal [1.0, 2.0, 3.0], @integer.ceil.to_a
      assert_equal [1.0, -2.0, 3.0], @double.ceil.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.ceil }
    end

    test '#cos' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.cos }
      assert_equal [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @integer.cos.to_a
      assert_equal [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @double.cos.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.cos }
    end

    test '#floor' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.floor }
      assert_equal [1.0, 2.0, 3.0], @integer.floor.to_a
      assert_equal [1.0, -2.0, 3.0], @double.floor.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.floor }
    end

    test '#sign' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.sign }
      assert_equal [1, 1, 1], @integer.sign.to_a
      assert_equal [1.0, -1.0, 1.0], @double.sign.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.sign }
    end

    test '#sin' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.sin }
      assert_equal [0.8414709848078965, 0.9092974268256817, 0.1411200080598672], @integer.sin.to_a
      assert_equal [0.8414709848078965, -0.9092974268256817, 0.1411200080598672], @double.sin.to_a
      assert_raise(Arrow::Error::NotImplemented) { @string.sin }
    end

    test '#tan' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.tan }
      assert_equal_array_in_delta [1.557407724654902, -2.185039863261519, -0.1425465430742778], @integer.tan, delta = 1e-15
      assert_equal_array_in_delta [1.557407724654902, 2.185039863261519, -0.1425465430742778], @double.tan, delta = 1e-15
      assert_raise(Arrow::Error::NotImplemented) { @string.tan }
    end
  end
end
