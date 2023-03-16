# frozen_string_literal: true

require 'test_helper'

class VectorFunctionTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case 'class method' do
    setup do
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '.atan2(y, x)' do
      assert_raise(Arrow::Error::NotImplemented) { Vector.atan2(@boolean, @boolean) }
      assert_equal_array_in_delta [0.7853981633974483, 0.7853981633974483, 0.7853981633974483], Vector.atan2(@integer, @integer), delta = 1e-15
      assert_equal_array_in_delta [0.7853981633974483, -2.356194490192345, 0.7853981633974483], Vector.atan2(@double, @double), delta = 1e-15
      assert_raise(Arrow::Error::NotImplemented) { Vector.atan2(@string, @boolean) }
    end
  end

  sub_test_case 'binary element-wise' do
    setup do
      @boolean = Vector.new([true, true, nil])
      @integer = Vector.new([1, 2, 3])
      @double = Vector.new([1.0, -2, 3])
      @string = Vector.new(%w[A B A])
    end

    test '#and_not(vector)' do
      assert_equal_array [false, false, nil], @boolean.and_not(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_not(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_not(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_not(@string) }
    end

    test '#and_not(scalar)' do
      assert_equal_array [false, false, nil], @boolean.and_not(true)
      assert_equal_array [true, true, nil], @boolean.and_not(false)
      assert_equal_array [nil, nil, nil], @boolean.and_not(nil)
    end

    test '#and_not_kleene(vector)' do
      assert_equal_array [false, false, nil], @boolean.and_not_kleene(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_not_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_not_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_not_kleene(@string) }
    end

    test '#and_not_kleene(scalar)' do
      assert_equal_array [false, false, false], @boolean.and_not_kleene(true)
      assert_equal_array [true, true, nil], @boolean.and_not_kleene(false)
      assert_equal_array [nil, nil, nil], @boolean.and_not_kleene(nil)
    end

    test '#bit_wise_and(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_and(@boolean) }
      assert_equal_array [1, 2, 3], @integer.bit_wise_and(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_and(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_and(@string) }
    end

    test '#bit_wise_and(scalar)' do
      assert_equal_array [0, 2, 2], @integer.bit_wise_and(2)
    end

    test '#bit_wise_or(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_or(@boolean) }
      assert_equal_array [1, 2, 3], @integer.bit_wise_or(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_or(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_or(@string) }
    end

    test '#bit_wise_or(scalar)' do
      assert_equal_array [3, 2, 3], @integer.bit_wise_or(2)
    end

    test '#bit_wise_xor(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.bit_wise_xor(@boolean) }
      assert_equal_array [0, 0, 0], @integer.bit_wise_xor(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.bit_wise_xor(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.bit_wise_xor(@string) }
    end

    test '#bit_wise_xor(scalar)' do
      assert_equal_array [3, 0, 1], @integer.bit_wise_xor(2)
    end

    test '#logb(base)' do
      boolean = Vector.new([true, false, nil])
      integer = Vector.new([-1, 0, 1, 2])
      double = Vector.new([-1.0, 0.0, 1.0, 2])
      string = Vector.new(%w[A B C])
      assert_raise(Arrow::Error::NotImplemented) { boolean.logb(2) }
      assert_equal_array_with_nan integer.log2, integer.logb(2)
      assert_equal_array_with_nan double.log2, double.logb(2)
      assert_equal_array_with_nan [Float::NAN, Float::NAN, -0.0, -0.0], double.logb(0)
      assert_raise(Arrow::Error::NotImplemented) { string.logb(2) }
    end

    test '#logb_checked(base)' do
      integer = Vector.new([-1, 0, 1, 2])
      double = Vector.new([-1.0, 0.0, 1.0, 2])
      assert_raise(Arrow::Error::Invalid) { integer.logb_checked(2) }
      assert_raise(Arrow::Error::Invalid) { double.logb_checked(2) }
    end
  end

  sub_test_case 'binary element-wise with operator' do
    setup do
      @bool_self = Vector.new(true, true, true, false, false, false, nil, nil, nil)
      @bool_self3 = Vector.new(true, false, nil)
      @bool_other = Vector.new(true, false, nil, true, false, nil, true, false, nil)
      @integer = Vector.new(1, 2, 3)
      @double = Vector.new(1.0, -2, 3)
      @string = Vector.new(%w[A B A])
    end

    test '#&' do
      assert_equal_array([true, false, nil, false, false, false, nil, false, nil],
                         @bool_self & @bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer & @integer }
      assert_raise(Arrow::Error::NotImplemented) { @double & @double }
      assert_raise(Arrow::Error::NotImplemented) { @string & @string }
    end

    test '#and_kleene(vector)' do
      assert_equal_array([true, false, nil, false, false, false, nil, false, nil],
                         @bool_self.and_kleene(@bool_other))
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_kleene(@string) }
    end

    test '#and_kleene(scalar)' do
      assert_equal_array [true, false, nil], @bool_self3.and_kleene(true)
      assert_equal_array [false, false, false], @bool_self3.and_kleene(false)
      assert_equal_array [nil, false, nil], @bool_self3.and_kleene(nil)
    end

    test '#and_org(vector)' do
      assert_equal_array([true, false, nil, false, false, nil, nil, nil, nil],
                         @bool_self.and_org(@bool_other))
      assert_raise(Arrow::Error::NotImplemented) { @integer.and_org(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.and_org(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.and_org(@string) }
    end

    test '#and_org(scalar)' do
      assert_equal_array [true, false, nil], @bool_self3.and_org(true)
      assert_equal_array [false, false, nil], @bool_self3.and_org(false)
      assert_equal_array [nil, nil, nil], @bool_self3.and_org(nil)
    end

    test '#|' do
      assert_equal_array([true, true, true, true, false, nil, true, nil, nil],
                         @bool_self | @bool_other)
      assert_raise(Arrow::Error::NotImplemented) { @integer | @integer }
      assert_raise(Arrow::Error::NotImplemented) { @double | @double }
      assert_raise(Arrow::Error::NotImplemented) { @string | @string }
    end

    test '#or_kleene(vector)' do
      assert_equal_array([true, true, true, true, false, nil, true, nil, nil],
                         @bool_self.or_kleene(@bool_other))
      assert_raise(Arrow::Error::NotImplemented) { @integer.or_kleene(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.or_kleene(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.or_kleene(@string) }
    end

    test '#or_kleene(scalar)' do
      assert_equal_array [true, true, true], @bool_self3.or_kleene(true)
      assert_equal_array [true, false, nil], @bool_self3.or_kleene(false)
      assert_equal_array [true, nil, nil], @bool_self3.or_kleene(nil)
    end

    test '#or_org(vector)' do
      assert_equal_array([true, true, nil, true, false, nil, nil, nil, nil],
                         @bool_self.or_org(@bool_other))
      assert_raise(Arrow::Error::NotImplemented) { @integer.or_org(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.or_org(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.or_org(@string) }
    end

    test '#or_org(scalar)' do
      assert_equal_array [true, true, nil], @bool_self3.or_org(true)
      assert_equal_array [true, false, nil], @bool_self3.or_org(false)
      assert_equal_array [nil, nil, nil], @bool_self3.or_org(nil)
    end
  end

  sub_test_case 'binary element-wise with operator' do
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

    test '#add(scalar)' do
      assert_equal_array [3, 4, 5], @integer.add(2)
      assert_equal_array [3.0, 4.0, 5.0], @integer.add(2.0)
      assert_equal_array [3.0, 0.0, 5.0], @double.add(2)
    end

    test '#+' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean + @boolean }
      assert_equal_array [2, 4, 6], @integer + @integer
      assert_equal_array [2.0, -4.0, 6.0], @double + @double
      assert_raise(Arrow::Error::NotImplemented) { @string + @string }
    end

    test '#add overflow' do
      assert_equal_array [0, 1, 2], @integer.add(255)
    end

    test '#add_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.add_checked(255) }
    end

    test '#divide(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.divide(@boolean) }
      assert_equal_array [1, 1, 1], @integer.divide(@integer)
      assert_equal_array [1.0, 1.0, 1.0], @double.divide(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.divide(@string) }
    end

    test '#divide(scalar)' do
      assert_equal_array [0, 1, 1], @integer.divide(2)
      assert_equal_array [0.5, 1.0, 1.5], @integer.divide(2.0)
      assert_equal_array [-0.5, 1.0, -1.5], @double.divide(-2)
    end

    test '#/' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean / @boolean }
      assert_equal_array [1, 1, 1], @integer / @integer
      assert_equal_array [1.0, 1.0, 1.0], @double / @double
      assert_raise(Arrow::Error::NotImplemented) { @string / @string }
    end

    test '#divide_checked' do
      assert_equal_array [0, 1, 1], @integer.divide_checked(2)
      assert_equal_array [-0.5, 1.0, -1.5], @double.divide_checked(-2)
    end

    test '#fdiv(vector)' do
      divisor = Vector.new(2, 2, 2)
      float_divisor = Vector.new(-2, 1.0, 3)
      assert_raise(TypeError) { @boolean.fdiv(@boolean) }
      assert_equal_array [0.5, 1.0, 1.5], @integer.fdiv(divisor)
      assert_equal_array [0.5, -1.0, 1.5], @double.fdiv(divisor)
      assert_equal_array [-0.5, -2.0, 1.0], @double.fdiv(float_divisor)
      assert_raise(Arrow::Error::NotImplemented) { @string.fdiv(@string) }
    end

    test '#fdiv(scalar)' do
      assert_equal_array [0.5, 1.0, 1.5], @integer.fdiv(2.0)
      assert_equal_array [-0.5, 1.0, -1.5], @double.fdiv(-2)
    end

    test '#fdiv_checked' do
      assert_equal_array [0.5, 1.0, 1.5], @integer.fdiv_checked(2.0)
      assert_equal_array [-0.5, 1.0, -1.5], @double.fdiv_checked(-2)
    end

    test '#modulo(vector)' do
      integer = Vector.new(-5, -3, 3, 5)
      float = Vector.new(-5.0, -3, 3, 5)
      divisor = Vector.new(-3, 3, -5, 5)
      float_divisor = Vector.new(-3.0, 3.0, -5.0, 5.0)
      assert_raise(Arrow::Error::NotImplemented) { @boolean.modulo(@boolean) }
      assert_equal_array [-2, 0, 3, 0], integer.modulo(divisor)
      assert_equal_array [-2.0, 0.0, -2.0, 0.0], float.modulo(divisor)
      assert_equal_array [-2.0, 0.0, -2.0, 0.0], float.modulo(float_divisor)
      assert_raise(Arrow::Error::NotImplemented) { @string.modulo(@string) }
    end

    test '#modulo(scalar)' do
      assert_equal_array [1.0, 0.0, 1.0], @integer.modulo(2.0)
      assert_equal_array [-1.0, 0.0, -1.0], @double.modulo(-2)
    end

    test '#%' do
      divisor = Vector.new(2, 2, 2)
      float_divisor = Vector.new(-2, 1.0, 3)
      assert_raise(Arrow::Error::NotImplemented) { @boolean % @boolean }
      assert_equal_array [1, 0, 1], @integer % divisor
      assert_equal_array [1.0, 0.0, 1.0], @double % divisor
      assert_equal_array [-1.0, 0.0, 0.0], @double % float_divisor
      assert_raise(Arrow::Error::NotImplemented) { @string % @string }
    end

    test '#modulo_checked' do
      assert_equal_array [1.0, 0.0, 1.0], @integer.modulo_checked(2.0)
      assert_equal_array [-1.0, 0.0, -1.0], @double.modulo_checked(-2)
    end

    test '#multiply(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.multiply(@boolean) }
      assert_equal_array [1, 4, 9], @integer.multiply(@integer)
      assert_equal_array [1.0, 4.0, 9.0], @double.multiply(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.multiply(@string) }
    end

    test '#multiply(scalar)' do
      assert_equal_array [2, 4, 6], @integer.multiply(2)
      assert_equal_array [2.0, 4.0, 6.0], @integer.multiply(2.0)
      assert_equal_array [-2.0, 4.0, -6.0], @double.multiply(-2)
    end

    test '#*' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean * @boolean }
      assert_equal_array [1, 4, 9], @integer * @integer
      assert_equal_array [1.0, 4.0, 9.0], @double * @double
      assert_raise(Arrow::Error::NotImplemented) { @string * @string }
    end

    test '#multiply overflow' do
      assert_equal_array [86, 172, 2], @integer.multiply(86)
    end

    test '#multiply_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.multiply_checked(86) }
    end

    test '#power(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.power(@boolean) }
      assert_equal_array [1, 4, 27], @integer.power(@integer)
      assert_equal_array [1.0, 0.25, 27.0], @double.power(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.power(@string) }
    end

    test '#power(scalar)' do
      assert_equal_array [1, 4, 9], @integer.power(2)
      assert_equal_array [1.0, 4.0, 9.0], @integer.power(2.0)
      assert_equal_array [1.0, 0.25, 0.1111111111111111], @double.power(-2)
    end

    test '#**' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean**@boolean }
      assert_equal_array [1, 4, 27], @integer**@integer
      assert_equal_array [1.0, 0.25, 27.0], @double**@double
      assert_raise(Arrow::Error::NotImplemented) { @string**@string }
    end

    test '#power overflow' do
      assert_equal_array [1, 64, 217], @integer.power(6)
    end

    test '#power_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.power_checked(6) }
    end

    test '#remainder(vector)' do
      integer = Vector.new(-5, -3, 3, 5)
      float = Vector.new(-5.0, -3, 3, 5)
      divisor = Vector.new(-3, 3, -5, 5)
      float_divisor = Vector.new(-3.0, 3.0, -5.0, 5.0)
      assert_raise(Arrow::Error::NotImplemented) { @boolean.remainder(@boolean) }
      assert_equal_array [-2, 0, 3, 0], integer.remainder(divisor)
      assert_equal_array [-2.0, 0.0, 3.0, 0.0], float.remainder(divisor)
      assert_equal_array [-2.0, 0.0, 3.0, 0.0], float.remainder(float_divisor)
      assert_raise(Arrow::Error::NotImplemented) { @string.remainder(@string) }
    end

    test '#remainder(scalar)' do
      assert_equal_array [1.0, 0.0, 1.0], @integer.remainder(2.0)
      assert_equal_array [1.0, 0.0, 1.0], @double.remainder(-2)
    end

    test '#remainder_checked' do
      assert_equal_array [1.0, 0.0, 1.0], @integer.remainder_checked(2.0)
      assert_equal_array [1.0, 0.0, 1.0], @double.remainder_checked(-2)
    end

    test '#subtract(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.subtract(@boolean) }
      assert_equal_array [0, 0, 0], @integer.subtract(@integer)
      assert_equal_array [0.0, 0.0, 0.0], @double.subtract(@double)
      assert_raise(Arrow::Error::NotImplemented) { @string.subtract(@string) }
    end

    test '#subtract(scalar)' do
      assert_equal_array [255, 0, 1], @integer.subtract(2)
      assert_equal_array [-1.0, 0.0, 1.0], @integer.subtract(2.0)
      assert_equal_array [3.0, 0.0, 5.0], @double.subtract(-2)
    end

    test '#-' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean - @boolean }
      assert_equal_array [0, 0, 0], @integer - @integer
      assert_equal_array [0.0, 0.0, 0.0], @double - @double
      assert_raise(Arrow::Error::NotImplemented) { @string - @string }
    end

    test '#subtract overflow' do
      assert_equal_array [255, 0, 1], @integer.subtract(2)
    end

    test '#subtract_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.subtract_checked(2) }
    end

    test '#shift_left(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.shift_left(@boolean) }
      assert_equal_array [2, 8, 24], @integer.shift_left(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.shift_left(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.shift_left(@string) }
    end

    test '#shift_left(scalar)' do
      assert_equal_array [4, 8, 12], @integer.shift_left(2)
      assert_equal_array [1, 2, 3], @integer.shift_left(-2)
    end

    test '#<<' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.<<(@boolean) }
      assert_equal_array [2, 8, 24], @integer << @integer
      assert_raise(Arrow::Error::NotImplemented) { @double.<<(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.<<(@string) }
    end

    test '#shift_left overflow' do
      assert_equal_array [1, 2, 3], @integer.shift_left(8)
    end

    test '#shift_left_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.shift_left_checked(8) }
    end

    test '#shift_right(vector)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.shift_right(@boolean) }
      assert_equal_array [0, 0, 0], @integer.shift_right(@integer)
      assert_raise(Arrow::Error::NotImplemented) { @double.shift_right(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.shift_right(@string) }
    end

    test '#shift_right(scalar)' do
      assert_equal_array [0, 0, 0], @integer.shift_right(2)
      assert_equal_array [1, 2, 3], @integer.shift_right(-2)
    end

    test '#>>' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean >> @boolean }
      assert_equal_array [0, 0, 0], @integer >> @integer
      assert_raise(Arrow::Error::NotImplemented) { @double >> @double }
      assert_raise(Arrow::Error::NotImplemented) { @string >> @string }
    end

    test '#shift_right overflow' do
      assert_equal_array [1, 2, 3], @integer.shift_right(8)
    end

    test '#shift_right_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.shift_right_checked(8) }
    end

    test '#xor(vector)' do
      assert_equal_array [false, false, nil], @boolean.xor(@boolean)
      assert_raise(Arrow::Error::NotImplemented) { @integer.xor(@integer) }
      assert_raise(Arrow::Error::NotImplemented) { @double.xor(@double) }
      assert_raise(Arrow::Error::NotImplemented) { @string.xor(@string) }
    end

    test '#xor(scalar)' do
      assert_equal_array [false, false, nil], @boolean.xor(true)
      assert_equal_array [true, true, nil], @boolean.xor(false)
      assert_equal_array [nil, nil, nil], @boolean.xor(nil)
    end

    test '#^' do
      assert_equal_array [false, false, nil], @boolean ^ @boolean
      assert_raise(Arrow::Error::NotImplemented) { @integer ^ @integer }
      assert_raise(Arrow::Error::NotImplemented) { @double ^ @double }
      assert_raise(Arrow::Error::NotImplemented) { @string ^ @string }
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
      assert_equal_array [nil, nil, nil], @boolean.equal(nil)
      assert_equal_array [true, false, false], @integer.equal(1)
      assert_equal_array [true, false, false], @double.equal(1.0)
      assert_equal_array [true, false, true], @string.equal('A')
    end

    test '#eq' do
      assert_equal_array [true, true, nil], @boolean.eq(@boolean)
      assert_equal_array [true, true, true], @integer.eq(@integer)
      assert_equal_array [true, true, true], @double.eq(@double)
      assert_equal_array [true, true, true], @string.eq(@string)
    end

    test '#==' do
      assert_equal_array [true, true, nil], @boolean == @boolean
      assert_equal_array [true, true, true], @integer == @integer
      assert_equal_array [true, true, true], @double == @double
      assert_equal_array [true, true, true], @string == @string
    end

    test '#greater(vector)' do
      assert_equal_array [false, false, nil], @boolean.greater(@boolean)
      assert_equal_array [false, false, false], @integer.greater(@integer)
      assert_equal_array [false, false, false], @double.greater(@double)
      assert_equal_array [false, false, false], @string.greater(@string)
    end

    test '#greater(scalar)' do
      assert_equal_array [false, false, nil], @boolean.greater(true)
      assert_equal_array [true, true, nil], @boolean.greater(false)
      assert_equal_array [nil, nil, nil], @boolean.greater(nil)
      assert_equal_array [false, true, true], @integer.greater(1)
      assert_equal_array [false, false, true], @double.greater(1.0)
      assert_equal_array [false, true, false], @string.greater('A')
    end

    test '#gt' do
      assert_equal_array [false, false, nil], @boolean.gt(@boolean)
      assert_equal_array [false, false, false], @integer.gt(@integer)
      assert_equal_array [false, false, false], @double.gt(@double)
      assert_equal_array [false, false, false], @string.gt(@string)
    end

    test '#>' do
      assert_equal_array [false, false, nil], @boolean > @boolean
      assert_equal_array [false, false, false], @integer > @integer
      assert_equal_array [false, false, false], @double > @double
      assert_equal_array [false, false, false], @string > @string
    end

    test '#greater_equal(vector)' do
      assert_equal_array [true, true, nil], @boolean.greater_equal(@boolean)
      assert_equal_array [true, true, true], @integer.greater_equal(@integer)
      assert_equal_array [true, true, true], @double.greater_equal(@double)
      assert_equal_array [true, true, true], @string.greater_equal(@string)
    end

    test '#greater_equal(scalar)' do
      assert_equal_array [true, true, nil], @boolean.greater_equal(true)
      assert_equal_array [true, true, nil], @boolean.greater_equal(false)
      assert_equal_array [nil, nil, nil], @boolean.greater_equal(nil)
      assert_equal_array [true, true, true], @integer.greater_equal(1)
      assert_equal_array [true, false, true], @double.greater_equal(1.0)
      assert_equal_array [true, true, true], @string.greater_equal('A')
    end

    test '#ge' do
      assert_equal_array [true, true, nil], @boolean.ge(@boolean)
      assert_equal_array [true, true, true], @integer.ge(@integer)
      assert_equal_array [true, true, true], @double.ge(@double)
      assert_equal_array [true, true, true], @string.ge(@string)
    end

    test '#>=' do
      assert_equal_array [true, true, nil], @boolean >= @boolean
      assert_equal_array [true, true, true], @integer >= @integer
      assert_equal_array [true, true, true], @double >= @double
      assert_equal_array [true, true, true], @string >= @string
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
      assert_equal_array [nil, nil, nil], @boolean.less(nil)
      assert_equal_array [true, false, false], @integer.less(2)
      assert_equal_array [true, true, false], @double.less(2.0)
      assert_equal_array [true, false, true], @string.less('B')
    end

    test '#lt' do
      assert_equal_array [false, false, nil], @boolean.lt(@boolean)
      assert_equal_array [false, false, false], @integer.lt(@integer)
      assert_equal_array [false, false, false], @double.lt(@double)
      assert_equal_array [false, false, false], @string.lt(@string)
    end

    test '#<' do
      assert_equal_array [false, false, nil], @boolean < @boolean
      assert_equal_array [false, false, false], @integer < @integer
      assert_equal_array [false, false, false], @double < @double
      assert_equal_array [false, false, false], @string < @string
    end

    test '#less_equal(vector)' do
      assert_equal_array [true, true, nil], @boolean.less_equal(@boolean)
      assert_equal_array [true, true, true], @integer.less_equal(@integer)
      assert_equal_array [true, true, true], @double.less_equal(@double)
      assert_equal_array [true, true, true], @string.less_equal(@string)
    end

    test '#less_equal(scalar)' do
      assert_equal_array [true, true, nil], @boolean.less_equal(true)
      assert_equal_array [false, false, nil], @boolean.less_equal(false)
      assert_equal_array [nil, nil, nil], @boolean.less_equal(nil)
      assert_equal_array [true, true, false], @integer.less_equal(2)
      assert_equal_array [true, true, false], @double.less_equal(2.0)
      assert_equal_array [true, true, true], @string.less_equal('B')
    end

    test '#le' do
      assert_equal_array [true, true, nil], @boolean.le(@boolean)
      assert_equal_array [true, true, true], @integer.le(@integer)
      assert_equal_array [true, true, true], @double.le(@double)
      assert_equal_array [true, true, true], @string.le(@string)
    end

    test '#<=' do
      assert_equal_array [true, true, nil], @boolean <= @boolean
      assert_equal_array [true, true, true], @integer <= @integer
      assert_equal_array [true, true, true], @double <= @double
      assert_equal_array [true, true, true], @string <= @string
    end

    test '#not_equal(vector)' do
      assert_equal_array [false, false, nil], @boolean.not_equal(@boolean)
      assert_equal_array [false, false, false], @integer.not_equal(@integer)
      assert_equal_array [false, false, false], @double.not_equal(@double)
      assert_equal_array [false, false, false], @string.not_equal(@string)
    end

    test '#not_equal(scalar)' do
      assert_equal_array [false, false, nil], @boolean.not_equal(true)
      assert_equal_array [true, true, nil], @boolean.not_equal(false)
      assert_equal_array [nil, nil, nil], @boolean.not_equal(nil)
      assert_equal_array [true, false, true], @integer.not_equal(2)
      assert_equal_array [true, true, true], @double.not_equal(2.0)
      assert_equal_array [true, false, true], @string.not_equal('B')
    end

    test '#ne' do
      assert_equal_array [false, false, nil], @boolean.ne(@boolean)
      assert_equal_array [false, false, false], @integer.ne(@integer)
      assert_equal_array [false, false, false], @double.ne(@double)
      assert_equal_array [false, false, false], @string.ne(@string)
    end

    test '#!=' do
      assert_equal_array [false, false, nil], @boolean != @boolean
      assert_equal_array [false, false, false], @integer != @integer
      assert_equal_array [false, false, false], @double != @double
      assert_equal_array [false, false, false], @string != @string
    end
  end
end
