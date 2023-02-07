# frozen_string_literal: true

require 'test_helper'

class VectorFunctionTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

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
end
