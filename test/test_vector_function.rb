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
      assert_true @boolean.all.value
      assert_raise(Arrow::Error::NotImplemented) { @integer.all }
      assert_raise(Arrow::Error::NotImplemented) { @double.all }
      assert_raise(Arrow::Error::NotImplemented) { @string.all }
    end

    test '#any' do
      assert_true @boolean.any.value
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

    test '#count_uniq' do
      assert_equal 1, @boolean.count_uniq.value
      assert_equal 3, @integer.count_uniq.value
      assert_equal 3, @double.count_uniq.value
      assert_equal 2, @string.count_uniq.value
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

    test '#ceil' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.ceil }
      assert_equal_array [1.0, 2.0, 3.0], @integer.ceil
      assert_equal_array [1.0, -2.0, 3.0], @double.ceil
      assert_raise(Arrow::Error::NotImplemented) { @string.ceil }
    end

    test '#cos' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.cos }
      assert_equal_array [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @integer.cos
      assert_equal_array [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @double.cos
      assert_raise(Arrow::Error::NotImplemented) { @string.cos }
    end

    test '#floor' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.floor }
      assert_equal_array [1.0, 2.0, 3.0], @integer.floor
      assert_equal_array [1.0, -2.0, 3.0], @double.floor
      assert_raise(Arrow::Error::NotImplemented) { @string.floor }
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

    test '#trunc' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.trunc }
      assert_equal_array [1.0, 2.0, 3.0], @integer.trunc
      assert_equal_array [1.0, -2.0, 3.0], @double.trunc
      assert_raise(Arrow::Error::NotImplemented) { @string.trunc }
    end
  end

  sub_test_case('binary element-wise') do
    def setup
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

    test '#and(vector)' do
      assert_equal_array [true, true, nil], @boolean.and(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and(@string) }
    end

    test '#and_kleene(vector)' do
      assert_equal_array [true, true, nil], @boolean.and_kleene(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_kleene(@string) }
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

    test '#or(vector)' do
      assert_equal_array [true, true, nil], @boolean.or(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.or(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.or(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.or(@string) }
    end

    test '#or_kleene(vector)' do
      assert_equal_array [true, true, nil], @boolean.or_kleene(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.or_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.or_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.or_kleene(@string) }
    end

    test '#xor(vector)' do
      assert_equal_array [false, false, nil], @boolean.xor(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.xor(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.xor(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.xor(@string) }
    end
  end

  sub_test_case('binary element-wise with operator') do
    def setup
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

    test '#bit_wise_and(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_and(@boolean) }
      assert_equal_array [1, 2, 3], @integer.bit_wise_and(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_and(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_and(@string) }
    end

    test '#&(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.&(@boolean) }
      assert_equal_array [1, 2, 3], @integer.&(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.&(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.&(@string) }
    end

    test '#bit_wise_or(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_or(@boolean) }
      assert_equal_array [1, 2, 3], @integer.bit_wise_or(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_or(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_or(@string) }
    end

    test '#|(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.|(@boolean) }
      assert_equal_array [1, 2, 3], @integer.|(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.|(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.|(@string) }
    end

    test '#bit_wise_xor(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_xor(@boolean) }
      assert_equal_array [0, 0, 0], @integer.bit_wise_xor(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_xor(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_xor(@string) }
    end

    test '#^(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.^(@boolean) }
      assert_equal_array [0, 0, 0], @integer.^(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.^(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.^(@string) }
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

    test '#equal(vector)' do
      assert_equal_array [true, true, nil], @boolean.equal(@boolean)
      assert_equal_array [true, true, true], @integer.equal(@integer)
      assert_equal_array [true, true, true], @double.equal(@double)
      assert_equal_array [true, true, true], @string.equal(@string)
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
end
