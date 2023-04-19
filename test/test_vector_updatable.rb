# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case('replace') do
    test 'empty vector' do
      vec = Vector.new([])
      assert_true vec.replace(nil, nil).empty?
      assert_true vec.replace([], nil).empty?
      assert_true vec.replace([nil], nil).empty?
    end

    setup do
      @vec = Vector.new([1, 2, 3])
    end

    test 'empty specifier' do
      assert_equal_array @vec, @vec.replace([], [0])
    end

    test 'empty replacer' do
      assert_equal_array @vec, @vec.replace([0], [])
    end

    test 'replace UInt argument' do
      assert_equal_array [0, 2, 0], @vec.replace([0, 2], 0) # Broadcasted
      assert_raise(VectorArgumentError) { @vec.replace([2, 0], [0]) } # Size unmatch. Not broadcasted.
      assert_equal_array [0, 2, 4], @vec.replace([0, 2], [0, 4])
      assert_raise(VectorArgumentError) { @vec.replace([0, 2], [0, 0, 0]) } # Size unmatch
      assert_raise(VectorArgumentError) { @vec.replace([0, 1, 2], [0, 0]) } # Size unmatch
      assert_equal_array [5, 2, 4], @vec.replace([0, 2, nil], [5, 4])
      assert_equal_array [0, 2, nil], @vec.replace([0, 2], [0, nil])
    end

    test 'replace Int/Range argument mixture' do
      assert_equal_array [0, 0, 0], @vec.replace([0..1, 2], 0)
    end

    test 'reduced index' do
      assert_equal_array [1, 2, 0], @vec.replace([2, 2], 0) # equals to replace([2], [0])
      assert_equal_array [1, 2, 0], @vec.replace([2, -1], 0) # ibid.
      assert_equal_array [1, 3, 4], @vec.replace([2, 1, -1], [3, 4]) # equals to replace([1, 2], [3, 4])
    end

    test 'replace Range' do
      expected = [0, 0, 3]
      assert_equal_array expected, @vec.replace([0..1], 0)
      assert_equal_array expected, @vec.replace([0...-1], 0)
    end

    test 'replace UInt single' do
      assert_equal_array [1, 2, 0], @vec.replace([false, false, true], 0)
      assert_equal_array [1, 2, 0], @vec.replace([false, false, true], [0])
      assert_raise(VectorArgumentError) { @vec.replace([true], 0) } # boolean size mismatch
      assert_equal_array @vec, @vec.replace([false, false, nil], 0) # no true in boolean, return self
      assert_equal_array @vec, @vec.replace(Vector.new([false, false, nil]), 0) # no true in boolean, return self
      assert_raise(VectorArgumentError) { @vec.replace([true, false, nil], [0, 0]) } # replacement size mismatch
    end

    test 'replace multi/broadcast' do
      assert_equal_array [0, 2, 0], @vec.replace([true, false, true], [0, 0])
      assert_raise(VectorArgumentError) { @vec.replace([true, false, true], [0]) } # Replacements size unmatch
      assert_equal_array [0, 2, 0], @vec.replace([true, false, true], 0)
    end

    test 'replace multi/upcast' do
      assert_equal_array [0, 2, -1], @vec.replace([true, false, true], [0, -1])
      assert_equal :int8, @vec.replace([true, false, true], [0, -1]).type
    end

    test 'replace containing nil' do
      assert_equal_array [0, 2, nil], @vec.replace([true, false, nil], [0])
    end

    test 'replace Arrow::Array' do
      booleans = Arrow::Array.new([true, false, nil])
      assert_equal_array [0, 2, nil], @vec.replace(booleans, [0])
    end

    test 'replace with nil' do
      assert_equal_array [0, 2, nil], @vec.replace([true, false, true], [0, nil]) # 1 nil
      assert_equal_array [nil, 2, nil], @vec.replace([true, false, true], [nil]) # broadcast with nil
      assert_equal_array [nil, 2, nil], @vec.replace([true, false, true], nil) # broadcast with nil
      assert_raise(ArgumentError) { @vec.replace([true, false, true]) } # w/o replacer
    end

    test 'not align order of replacer to arg' do
      assert_equal_array [1, 4, 5], @vec.replace([2, 1], [4, 5])
    end

    test 'replace with Arrow::BooleanArray' do
      assert_equal_array [1, 2, 0], @vec.replace(Arrow::Array.new([false, false, true]), 0)
    end

    test 'replace with Vector' do
      assert_equal_array [4, 2, 5], @vec.replace(Arrow::Array.new([true, false, true]), Vector.new(4, 5))
    end

    test 'replace with Arrow::Array' do
      assert_equal_array [4, 2, 5], @vec.replace(Arrow::Array.new([true, false, true]), Arrow::Array.new([4, 5]))
    end

    test 'invalid specifier' do
      assert_raise(VectorArgumentError) { @vec.replace(%w[A B C], 0) }
    end
  end

  sub_test_case('fill_nil') do
    test 'fill_nil(0)' do
      vec = Vector.new([1, 2, nil])
      assert_equal_array [1, 2, 0], vec.fill_nil(0)
    end
  end

  sub_test_case('Ternary function #if_else') do
    setup do
      @empty = Vector.new([])
      @boolean = Vector.new([true, true, false, nil])
      @integer = Vector.new([1, 2, 3, nil])
      @double = Vector.new([1.0, Float::NAN, Float::INFINITY, nil])
      @string = Vector.new(%w[A B C] << nil)
    end

    test 'not a boolean' do
      assert_raise(RedAmber::VectorTypeError) { @integer.if_else(@integer, @integer) }
    end

    test 'empty' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(@empty, @integer) }
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(@integer, @empty) }
    end

    test 'scalar or scalar' do
      assert_equal_array [1, 1, 0, nil], @boolean.if_else(1, 0)
      assert_raise(ArgumentError) { @boolean.if_else(1, nil) }
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(1, 'A') }
    end

    test 'array or scalar' do
      assert_equal_array [1, 2, 0, nil], @boolean.if_else([1, 2, 3, 4], 0)
    end

    test 'array or array' do
      assert_equal_array [1, 2, 0, nil], @boolean.if_else([1, 2, 3, 4], [0, 0, 0, nil])
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else([1, 2, 3, 4], [nil, nil, nil, nil]) }
      assert_equal_array [1, 2, nil, nil], @boolean.if_else([1, 2, 3, 4], Arrow::UInt8Array.new([nil, nil, nil, nil]))
    end

    test 'vector or scalar' do
      assert_equal_array [1, 2, 0, nil], @boolean.if_else(@integer, 0)
    end

    test 'vector(integer) or vector(double)' do
      assert_equal_array [1.0, 2.0, Float::INFINITY, nil], @boolean.if_else(@integer, @double)
    end

    test 'vector(integer) or vector(string)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(@integer, @string) }
    end
  end

  sub_test_case '#primitive_invert' do
    test '#primitive_invert' do
      assert_raise(VectorTypeError) { Vector.new([1]).primitive_invert }
      assert_equal_array [false, true, true], Vector.new([true, false, nil]).primitive_invert
    end
  end

  sub_test_case '#shift' do
    setup do
      @numeric = Vector.new(1, 2, 3, 4, 5)
      @boolean = Vector.new(true, false, true, false, false)
    end

    test '#shift amount too large' do
      assert_raise(VectorArgumentError) { @numeric.shift(5) }
      assert_raise(VectorArgumentError) { @numeric.shift(-5) }
    end

    test '#shift numeric Vector' do
      assert_equal_array [nil, 1, 2, 3, 4], @numeric.shift
      assert_equal_array [3, 4, 5, nil, nil], @numeric.shift(-2)
      assert_equal_array [0, 0, 1, 2, 3], @numeric.shift(2, fill: 0)
    end

    test '#shift boolean Vector' do
      assert_equal_array [nil, true, false, true, false], @boolean.shift
      assert_equal_array [true, false, false, nil, nil], @boolean.shift(-2)
      assert_equal_array [false, false, true, false, true], @boolean.shift(2, fill: false)
    end

    test '#shift, amount == 0' do
      assert_equal_array [1, 2, 3, 4, 5], @numeric.shift(0)
      assert_equal_array [true, false, true, false, false], @boolean.shift(0)
    end
  end

  sub_test_case '#split_to_columns' do
    test '#split a invalid Vector' do
      assert_raise(VectorTypeError) { Vector.new.split_to_columns } # Empty Vector is string type
      assert_raise(VectorTypeError) { Vector.new(1, 2, 3).split_to_columns }
    end

    test '#split_to_columns' do
      array = ['a b', 'c d', 'e f']
      expect = array.map(&:split).transpose
      assert_equal expect, Vector.new(array).split_to_columns
    end

    test '#split_to_columns tab separator' do
      array = ['a\tb', 'c\td', 'e\tf']
      expect = array.map(&:split).transpose
      assert_equal expect, Vector.new(array).split_to_columns
    end

    test '#split_to_columns using separator' do
      array = %w[a_b c_d e_f]
      expect = array.map { |e| e.split('_') }.transpose
      assert_equal expect, Vector.new(array).split_to_columns('_')
    end

    test '#split_to_columns with nil' do
      array = [nil, 'c d', 'e f']
      expect = [[nil, 'c', 'e'], [nil, 'd', 'f']]
      assert_equal expect, Vector.new(array).split_to_columns
    end

    test '#split_to_columns only nil' do
      assert_raise(VectorTypeError) { Vector.new(nil).split_to_columns }
      assert_raise(VectorTypeError) { Vector.new(nil, nil).split_to_columns }
    end

    test '#split_to_columns no separator' do
      array = %w[ab cd ef]
      assert_equal [array], Vector.new(array).split_to_columns
      assert_equal [%w[a c e], %w[b d f]], Vector.new(array).split_to_columns('')
    end

    test '#split_to_columns different str length' do
      array = ['a', 'a b', 'a b c', nil]
      expect = [['a', 'a', 'a', nil], [nil, 'b', 'b', nil], [nil, nil, 'c', nil]]
      assert_equal expect, Vector.new(array).split_to_columns
    end

    test '#split_to_columns different stlength with limit' do
      array = ['a', 'a b', 'a b c', nil]
      expect = [['a', 'a', 'a', nil], [nil, 'b', 'b c', nil]]
      assert_equal expect, Vector.new(array).split_to_columns(' ', 2)
    end
  end

  sub_test_case '#split_to_rows' do
    test '#split a invalid Vector' do
      assert_raise(VectorTypeError) { Vector.new.split_to_rows } # Empty Vector is string type
      assert_raise(VectorTypeError) { Vector.new(1, 2, 3).split_to_rows }
    end

    test '#split_to_rows' do
      array = ['a b', 'c d', 'e f']
      expect = array.map(&:split).flatten
      assert_equal expect, Vector.new(array).split_to_rows
    end

    test '#split_to_rows tab separator' do
      array = ['a\tb', 'c\td', 'e\tf']
      expect = array.map(&:split).flatten
      assert_equal expect, Vector.new(array).split_to_rows
    end

    test '#split_to_rows using separator' do
      array = %w[a_b c_d e_f]
      expect = array.map { |e| e.split('_') }.flatten
      assert_equal expect, Vector.new(array).split_to_rows('_')
    end

    test '#split_to_rows with nil' do
      array = [nil, 'c d', 'e f']
      expect = %w[c e d f]
      assert_equal expect, Vector.new(array).split_to_rows
    end

    test '#split_to_rows only nil' do
      assert_raise(VectorTypeError) { Vector.new(nil).split_to_rows }
      assert_raise(VectorTypeError) { Vector.new(nil, nil).split_to_rows }
    end

    test '#split_to_rows no separator' do
      array = %w[ab cd ef]
      assert_equal array, Vector.new(array).split_to_rows
      assert_equal %w[a b c d e f], Vector.new(array).split_to_rows('')
    end

    test '#split_to_rows different str length' do
      array = ['a', 'a b', 'a b c', nil]
      expect = %w[a a a b b c]
      assert_equal expect, Vector.new(array).split_to_rows
    end

    test '#split_to_rows different stlength with limit' do
      array = ['a', 'a b', 'a b c', nil]
      expect = ['a', 'a', 'a', 'b', 'b c']
      assert_equal expect, Vector.new(array).split_to_rows(' ', 2)
    end
  end

  sub_test_case '#merge' do
    test '#merge for a invalid Vector' do
      assert_raise(VectorTypeError) { Vector.new.merge('x') } # Empty Vector is string type
      assert_raise(VectorTypeError) { Vector.new(1, 2, 3).merge('x') }
    end

    test '#merge' do
      vector = Vector.new(%w[a c e])
      other = Vector.new(%w[b d f])
      assert_equal ['a b', 'c d', 'e f'], vector.merge(other)
      assert_equal ['a b', 'c d', 'e f'], vector.merge(other.data)
    end

    test '#merge with scalar' do
      vector = Vector.new(%w[a c e])
      assert_equal ['a x', 'c x', 'e x'], vector.merge('x')
      assert_raise(VectorArgumentError) { vector.merge(0) }
    end

    test '#merge with a separator' do
      vector = Vector.new(%w[a c e])
      other = Vector.new(%w[b d f])
      assert_equal %w[a-b c-d e-f], vector.merge(other, sep: '-')
      assert_equal %w[ab cd ef], vector.merge(other, sep: '')
      assert_equal ['a\nb', 'c\nd', 'e\nf'], vector.merge(other, sep: '\n')
      assert_raise(VectorArgumentError) { vector.merge(other, sep: 0) }
    end

    test '#merge invalid merge' do
      vector = Vector.new(%w[a c e])
      other = Vector.new(%w[b d f x])
      assert_raise(NameError) { Vector.new(array).merge(other) }
    end
  end

  sub_test_case '#concatenate' do
    setup do
      @string = Vector.new(%w[A B C])
      @integer = Vector.new([1, 2])
    end

    test '#concatenate []' do
      assert_raise(ArgumentError) { @string.concatenate }
      assert_equal_array %w[A B C], @string.concatenate([])
      assert_equal_array %w[A B C], @string.concatenate(Vector.new)
      assert_equal_array [1, 2], @integer.concatenate([])
      assert_equal_array [1, 2], @integer.concatenate(Vector.new)
    end

    test '#concatenate integer into string' do
      expected = %w[A B C 1 2]
      assert_equal_array expected, @string.concatenate([1, 2])
      assert_equal_array expected, @string.concatenate(@integer)
    end

    test '#concatenate string into integer' do
      assert_equal_array [1, 2, 65, 66, 67], @integer.concatenate(%w[A B C])
      assert_raise(Arrow::Error::Invalid) { @integer.concatenate(@string) }
    end

    test '#concatenate string' do
      assert_equal_array %w[A B C], Vector.new.concatenate(@string)
      assert_equal_array %w[1 2], Vector.new.concatenate(@integer)
      assert_equal_array %w[A B C D E], @string.concatenate(%w[D E])
      assert_equal_array %w[A B C D E], @string.concatenate(Arrow::Array.new(%w[D E]))
      assert_equal_array %w[A B C D E], @string.concatenate(Arrow::ChunkedArray.new([%w[D E]]))
      assert_equal_array %w[A B C D E], @string.concatenate(Vector.new(%w[D E]))
    end

    test '#concatenate integer' do
      assert_equal_array [1, 2, 3, 4], @integer.concatenate([3, 4])
      assert_equal_array [1, 2, 3, 4], @integer.concatenate(Arrow::Array.new([3, 4]))
      assert_equal_array [1, 2, 3, 4], @integer.concatenate(Arrow::ChunkedArray.new([[3, 4]]))
      assert_equal_array [1, 2, 3, 4], @integer.concatenate(Vector.new([3, 4]))
    end
  end

  sub_test_case '#cast' do
    setup do
      @vector = Vector.new(1, 2, nil)
    end

    test '#cast(:int32)' do
      vector = @vector.cast(:int32)
      assert_equal :int32, vector.type
      assert_equal_array [1, 2, nil], vector
    end

    test '#cast(:int64)' do
      vector = @vector.cast(:int64)
      assert_equal :int64, vector.type
      assert_equal_array [1, 2, nil], vector
    end

    test '#cast(:double)' do
      vector = @vector.cast(:double)
      assert_equal :double, vector.type
      assert_equal_array [1.0, 2.0, nil], vector
    end

    test '#cast(:string)' do
      vector = @vector.cast(:string)
      assert_equal :string, vector.type
      assert_equal_array ['1', '2', nil], vector
    end

    test '#cast unsupported type' do
      assert_raise(TypeError) { @vector.cast(:list) }
    end
  end
end
