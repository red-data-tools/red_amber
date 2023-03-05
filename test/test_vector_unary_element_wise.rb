# frozen_string_literal: true

require 'test_helper'

class VectorFunctionTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case 'unary element-wise' do
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

    test '#negate_checked' do
      assert_raise(Arrow::Error::NotImplemented) { @integer.negate_checked }
      assert_equal_array [-1.0, 2.0, -3.0], @double.negate_checked
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

    test '#abs_checked' do
      assert_equal_array [1, 2, 3], @integer.abs_checked
      assert_equal_array [1.0, 2.0, 3.0], @double.abs_checked
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

    test '#cos_checked' do
      assert_equal_array [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @integer.cos_checked
      assert_equal_array [0.5403023058681398, -0.4161468365471424, -0.9899924966004454], @double.cos_checked
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

    test '#sin_checked' do
      assert_equal_array [0.8414709848078965, 0.9092974268256817, 0.1411200080598672], @integer.sin_checked
      assert_equal_array [0.8414709848078965, -0.9092974268256817, 0.1411200080598672], @double.sin_checked
    end

    test '#sqrt' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.sqrt }
      assert_equal_array [1.0, 1.4142135623730951, 1.7320508075688772], @integer.sqrt
      assert_equal_array_with_nan [1.0, Float::NAN, 1.7320508075688772], @double.sqrt
      assert_raise(Arrow::Error::NotImplemented) { @string.sqrt }
    end

    test '#sqrt_checked' do
      assert_equal_array [1.0, 1.4142135623730951, 1.7320508075688772], @integer.sqrt_checked
      assert_raise(Arrow::Error::Invalid) { @double.sqrt_checked }
    end

    test '#tan' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.tan }
      assert_equal_array_in_delta [1.557407724654902, -2.185039863261519, -0.1425465430742778], @integer.tan, delta = 1e-15
      assert_equal_array_in_delta [1.557407724654902, 2.185039863261519, -0.1425465430742778], @double.tan, delta = 1e-15
      assert_raise(Arrow::Error::NotImplemented) { @string.tan }
    end

    test '#tan_checked' do
      assert_equal_array_in_delta [1.557407724654902, -2.185039863261519, -0.1425465430742778], @integer.tan_checked, delta = 1e-15
      assert_equal_array_in_delta [1.557407724654902, 2.185039863261519, -0.1425465430742778], @double.tan_checked, delta = 1e-15
    end

    test `#sort_indexes` do # alias sort_indices, array_sort_indices
      boolean = Vector.new([false, nil, true])
      integer = Vector.new([3, 1, nil, 2])
      double = Vector.new([1.0, 1.0 / 0, 0.0 / 0, nil, -2])
      string = Vector.new(%w[C A B D] << nil)
      assert_equal_array [0, 2, 1], boolean.sort_indexes
      assert_equal_array [2, 0, 1], boolean.sort_indexes(order: :descending)
      assert_equal_array [1, 3, 0, 2], integer.sort_indexes
      assert_equal_array [4, 0, 1, 2, 3], double.sort_indexes
      assert_equal_array [1, 0, 4, 2, 3], double.sort_indexes(order: :descending)
      assert_equal_array [1, 2, 0, 3, 4], string.sort_indexes
    end
  end

  sub_test_case 'element-wise with NaN or Infinity' do
    setup do
      @boolean = Vector.new([true, false, nil])
      @integer = Vector.new([-1, 0, 1, 2])
      @double = Vector.new([-1.0, 0.0, 1.0, 2])
      @string = Vector.new(%w[A B C])
    end

    test '#acos' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.acos }
      expected = [Math::PI, Math.acos(0), 0.0, Float::NAN]
      assert_equal_array_with_nan expected, @integer.acos
      assert_equal_array_with_nan expected, @double.acos
      assert_raise(Arrow::Error::NotImplemented) { @string.acos }
    end

    test '#acos_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.acos_checked }
      assert_raise(Arrow::Error::Invalid) { @double.acos_checked }
    end

    test '#asin' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.asin }
      expected = [Math.asin(-1), 0.0, Math.asin(1), Float::NAN]
      assert_equal_array_with_nan expected, @integer.asin
      assert_equal_array_with_nan expected, @double.asin
      assert_raise(Arrow::Error::NotImplemented) { @string.asin }
    end

    test '#asin_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.asin_checked }
      assert_raise(Arrow::Error::Invalid) { @double.asin_checked }
    end

    test '#ln' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.ln }
      expected = [Float::NAN, -Float::INFINITY, 0.0, Math.log(2)]
      assert_equal_array_with_nan expected, @integer.ln
      assert_equal_array_with_nan expected, @double.ln
      assert_raise(Arrow::Error::NotImplemented) { @string.ln }
    end

    test '#ln_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.ln_checked }
      assert_raise(Arrow::Error::Invalid) { @double.ln_checked }
    end

    test '#log10' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.log10 }
      expected = [Float::NAN, -Float::INFINITY, 0.0, Math.log10(2)]
      assert_equal_array_with_nan expected, @integer.log10
      assert_equal_array_with_nan expected, @double.log10
      assert_raise(Arrow::Error::NotImplemented) { @string.log10 }
    end

    test '#log10_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.log10_checked }
      assert_raise(Arrow::Error::Invalid) { @double.log10_checked }
    end

    test '#log1p' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.log1p }
      expected = [-Float::INFINITY, 0.0, Math.log(2), Math.log(3)]
      assert_equal_array_with_nan expected, @integer.log1p
      assert_equal_array_with_nan expected, @double.log1p
      assert_raise(Arrow::Error::NotImplemented) { @string.log1p }
    end

    test '#log1p_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.log1p_checked }
      assert_raise(Arrow::Error::Invalid) { @double.log1p_checked }
    end

    test '#log2' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.log2 }
      expected = [Float::NAN, -Float::INFINITY, 0.0, 1.0]
      assert_equal_array_with_nan expected, @integer.log2
      assert_equal_array_with_nan expected, @double.log2
      assert_raise(Arrow::Error::NotImplemented) { @string.log2 }
    end

    test '#log2_checked' do
      assert_raise(Arrow::Error::Invalid) { @integer.log2_checked }
      assert_raise(Arrow::Error::Invalid) { @double.log2_checked }
    end
  end

  sub_test_case 'unary element-wise rounding' do
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
      assert_equal_array @double.ceil, @double.round(mode: :up)
      assert_raise(Arrow::Error::NotImplemented) { @string.ceil }
    end

    test '#floor' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.floor }
      assert_equal_array [1, 2, 3], @integer.floor
      assert_equal_array [15.0, 2.0, 3.0, -5.0, -6.0], @double.floor
      assert_equal_array @double.floor, @double.round(mode: :down)
      assert_equal_array @double.floor, @double.round(mode: :half_down)
      assert_raise(Arrow::Error::NotImplemented) { @string.floor }
    end

    test '#round' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.round }
      assert_equal_array [1, 2, 3], @integer.round

      assert_equal_array [15.0, 2.0, 4.0, -4.0, -6.0], @double.round
      assert_equal_array @double.round, @double.round(mode: :half_to_even)
      assert_equal_array [16.0, 3.0, 4.0, -5.0, -6.0], @double.round(mode: :towards_infinity)
      assert_equal_array [15.0, 3.0, 4.0, -4.0, -5.0], @double.round(mode: :half_up)
      assert_equal_array [15.0, 2.0, 3.0, -4.0, -5.0], @double.round(mode: :half_towards_zero)
      assert_equal_array [15.0, 3.0, 4.0, -5.0, -6.0], @double.round(mode: :half_towards_infinity)
      assert_equal_array [15.0, 3.0, 3.0, -5.0, -5.0], @double.round(mode: :half_to_odd)

      assert_equal_array @double.round, @double.round(n_digits: 0)
      assert_equal_array [15.2, 2.5, 3.5, -4.5, -5.5], @double.round(n_digits: 1)
      assert_equal_array [20.0, 0.0, 0.0, -0.0, -10.0], @double.round(n_digits: -1)

      assert_raise(Arrow::Error::NotImplemented) { @string.round }
    end

    test '#round_to_multiple' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.round_to_multiple }
      assert_equal_array [1, 2, 3], @integer.round_to_multiple
      assert_equal_array @double.round, @double.round_to_multiple
      assert_equal_array @double.round_to_multiple, @double.round_to_multiple(multiple: 1)
      assert_equal_array [15.200000000000001, 2.5, 3.5, -4.5, -5.5], @double.round_to_multiple(multiple: 0.1)
      assert_equal_array [20.0, 0.0, 0.0, -0.0, -10.0], @double.round_to_multiple(multiple: 10)
      assert_equal_array [16.0, 2.0, 4.0, -4.0, -6.0], @double.round_to_multiple(multiple: 2)
      assert_raise(Arrow::Error::NotImplemented) { @string.round_to_multiple }
    end

    test '#trunc' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.trunc }
      assert_equal_array [1, 2, 3], @integer.trunc
      assert_equal_array [15.0, 2.0, 3.0, -4.0, -5.0], @double.trunc
      assert_equal_array @double.trunc, @double.round(mode: :towards_zero)
      assert_raise(Arrow::Error::NotImplemented) { @string.trunc }
    end
  end

  sub_test_case 'unary output vector' do
    setup do
      @boolean = Vector.new([true, true, nil, false, nil])
      @integer = Vector.new([1, 2, 1, nil])
      @double = Vector.new([1.0, -2, -2.0, 0.0 / 0, Float::NAN])
      @string = Vector.new(%w[A B A])
    end

    test '#uniq' do
      assert_equal_array [true, nil, false], @boolean.uniq
      assert_equal_array [1, 2, nil], @integer.uniq
      assert_equal_array_with_nan [1.0, -2.0, Float::NAN], @double.uniq
      assert_equal_array %w[A B], @string.uniq
    end

    test '#tally/value_count' do
      assert_equal({ true => 2, nil => 2, false => 1 }, @boolean.tally)
      assert_equal @boolean.tally, @boolean.value_counts
      assert_equal({ 1 => 2, 2 => 1, nil => 1 }, @integer.tally)
      assert_equal @integer.tally, @integer.value_counts
      assert_equal({ 1.0 => 1, -2.0 => 2, Float::NAN => 2 }.to_s, @double.tally.to_s)
      assert_equal @double.tally.to_s, @double.value_counts.to_s
      assert_equal({ 'A' => 2, 'B' => 1 }, @string.tally)
      assert_equal @string.tally, @string.value_counts
    end
  end

  sub_test_case 'unary element-wise categorizations' do
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

  sub_test_case 'unary element-wise fill_nil_forward/backward' do
    setup do
      @boolean = Vector.new([true, false, nil, true, nil])
      @integer = Vector.new([0, 1, nil, 3, nil])
      @double = Vector.new([Math::PI, Float::INFINITY, nil, Float::NAN, nil])
      @string = Vector.new(['A', 'B', nil, '', nil])
    end

    test '#fill_nil_backward' do
      assert_equal_array [true, false, true, true, nil], @boolean.fill_nil_backward
      assert_equal_array [0, 1, 3, 3, nil], @integer.fill_nil_backward
      assert_equal_array_with_nan [Math::PI, Float::INFINITY, Float::NAN, Float::NAN, nil], @double.fill_nil_backward
      assert_equal_array ['A', 'B', '', '', nil], @string.fill_nil_backward
    end

    test '#fill_nil_forward' do
      assert_equal_array [true, false, false, true, true], @boolean.fill_nil_forward
      assert_equal_array [0, 1, 1, 3, 3], @integer.fill_nil_forward
      assert_equal_array_with_nan [Math::PI, Float::INFINITY, Float::INFINITY, Float::NAN, Float::NAN], @double.fill_nil_forward
      assert_equal_array ['A', 'B', 'B', '', ''], @string.fill_nil_forward
    end
  end

  sub_test_case '#cumulative_sum' do
    test '#cumulative_sum' do
      assert_equal_array [1, 3, 6, 255], Vector.new(1, 2, 3, 249).cumulative_sum_checked
      assert_raise(Arrow::Error::Invalid) { Vector.new(1, 2, 3, 250).cumulative_sum_checked }
      assert_equal_array [1.0, 3.0, 6.0, 256.0], Vector.new(1.0, 2, 3, 250).cumulative_sum_checked
      assert_raise(Arrow::Error::NotImplemented) { Vector.new(%w[A B C]).cumulative_sum_checked }
      assert_raise(Arrow::Error::NotImplemented) { Vector.new(true, false, nil).cumulative_sum_checked }
    end

    test '#cumsum' do
      assert_equal_array [1, 3, 6, 255], Vector.new(1, 2, 3, 249).cumsum
      assert_equal_array [1, 3, 6, 256], Vector.new(1, 2, 3, 250).cumsum
      assert_equal_array [1.0, 3.0, 6.0, 256.0], Vector.new(1.0, 2, 3, 250).cumsum
      assert_raise(Arrow::Error::NotImplemented) { Vector.new(%w[A B C]).cumsum }
      assert_raise(Arrow::Error::NotImplemented) { Vector.new(true, false, nil).cumsum }
    end
  end
end
