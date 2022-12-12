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

    test 'invalid specifier' do
      assert_raise(VectorArgumentError) { @vec.replace(%w[A B C], 0) }
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
    test '#shift' do
      vector = Vector.new([1, 2, 3, 4, 5])
      assert_equal [nil, 1, 2, 3, 4], vector.shift
      assert_equal [3, 4, 5, nil, nil], vector.shift(-2)
      assert_equal [0, 0, 1, 2, 3], vector.shift(2, fill: 0)
    end

    test '#shift, amount == 0' do
      vector = Vector.new([1, 2, 3, 4, 5])
      assert_equal_array vector, vector.shift(0)
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
end
