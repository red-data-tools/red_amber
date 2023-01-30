# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case('#take(indices)') do
    setup do
      @string = Vector.new(%w[A B C D E])
      @indices = [3, 0, -2]
    end

    test 'empty vector' do
      assert_equal_array [], Vector.new([]).take
    end

    test '#take' do
      assert_equal_array [], @string.take
      assert_equal_array %w[B], @string.take(1) # single value
      assert_equal_array %w[B D], @string.take(1, 3) # array without bracket
      assert_equal_array %w[D A D], @string.take(@indices) # array, negative index
      assert_equal_array %w[D A D], @string.take(Vector.new(@indices)) # array, negative index
      assert_equal_array %w[D E C], @string.take([3.1, -0.5, -2.5]) # float index
    end

    test '#take out of range' do
      assert_raise(VectorArgumentError) { @string.take(-6) } # out of lower limit
      assert_raise(VectorArgumentError) { @string.take(5) } # out of upper limit
    end

    test '#take invalid args' do
      assert_raise(VectorArgumentError) { @string.take('A') }
    end

    test '#take with a block' do
      assert_raise(VectorArgumentError) { @string.take(@booleans) { @indices } } # with both args and a block
      assert_equal_array(%w[D A D], @string.take { @indices }) # primitive Array
      assert_equal_array(%w[D A D], @string.take { Arrow::Array.new([3, 0, 3]) }) # Arrow::BooleanArray
      assert_equal_array(%w[D A D], @string.take { Vector.new(@indices) }) # Vector
    end
  end

  sub_test_case('#filter(booleans)') do
    setup do
      @string = Vector.new(%w[A B C D E])
      @booleans = [true, false, nil, false, true]
    end

    test 'empty vector' do
      assert_equal_array [], Vector.new([]).filter
    end

    test '#filter' do
      assert_equal_array [], @string.filter
      assert_equal_array %w[A E], @string.filter(*@booleans) # arguments
      assert_equal_array %w[A E], @string.filter(@booleans) # primitive Array
      assert_equal_array %w[A E], @string.filter(Arrow::BooleanArray.new(@booleans)) # Arrow::BooleanArray
      assert_equal_array %w[A E], @string.filter(Vector.new(@booleans)) # Vector
      assert_equal_array %w[A E], @string.filter([Vector.new(@booleans)]) # Vector
      assert_raise(VectorTypeError) { @string.filter(Vector.new(@string)) } # Not a boolean Vector
      assert_equal_array [], @string.filter([nil] * 5) # nil array is string type
    end

    test '#filter not booleans' do
      assert_raise(VectorTypeError) { @string.filter(1) }
      assert_raise(VectorTypeError) { @string.filter([*1..5]) }
    end

    test '#filter size unmatch' do
      assert_raise(VectorArgumentError) { @string.filter([true]) } # out of lower limit
    end

    test '#filter with a block' do
      assert_raise(VectorArgumentError) { @string.filter(@booleans) { @booleans } } # with both args and a block
      assert_equal_array(%w[A E], @string.filter { @booleans }) # primitive Array
      assert_equal_array(%w[A E], @string.filter { Arrow::BooleanArray.new(@booleans) }) # Arrow::BooleanArray
      assert_equal_array(%w[A E], @string.filter { Vector.new(@booleans) }) # Vector
    end
  end

  sub_test_case '#[]' do
    setup do
      @string = Vector.new(%w[A B C D E])
      @booleans = [true, false, nil, false, true]
      @indices = [3, 0, -2]
    end

    test 'empty vector' do
      assert_nil Vector.new[]
    end

    test '#[indices]' do
      assert_equal 'B', @string[1] # single value
      assert_equal %w[D A D], @string[@indices] # array, negative index
      assert_equal %w[D A D], @string[Vector.new(@indices)] # array, negative index
      assert_equal %w[D E C], @string[3.1, -0.5, -2.5] # float index
      assert_equal %w[D A D], @string[Arrow::Array.new(@indices)] # Arrow
    end

    test '#[indices] with ChunkedArray' do
      ca = Arrow::ChunkedArray.new([[0, 1], [2, 3]])
      vector = Vector.new(ca)
      assert_true vector.chunked?
      assert_equal 2, vector[2] # This will fail in 8.0.0
    end

    test '#[booleans]' do
      assert_equal 'B', @string[1] # single value
      assert_equal %w[A E], @string[*@booleans] # arguments
      assert_equal %w[A E], @string[@booleans] # primitive Array
      assert_equal %w[A E], @string[Arrow::BooleanArray.new(@booleans)] # Arrow::BooleanArray
      assert_equal %w[A E], @string[Vector.new(@booleans)] # Vector
      assert_raise(VectorTypeError) { @string[Vector.new(@string)] } # Not a boolean Vector
      assert_raise(VectorArgumentError) { @string[nil] } # nil array
      assert_raise(VectorArgumentError) { @string[[nil] * 5] } # nil array
    end

    test '#[Range]' do
      assert_equal %w[B C D], @string[1..3] # Normal Range
      assert_equal %w[B C D E], @string[1..] # Endless Range
      assert_equal %w[A B C], @string[..2] # Beginless Range
      assert_equal %w[B C D], @string[1..-2] # Range to index from tail
      assert_raise(IndexError) { @string[1..6] }
    end

    test 'invalid argument' do
      assert_raise(VectorArgumentError) { @string[Object.new] }
    end
  end

  sub_test_case '#is_in' do
    setup do
      @vector = Vector.new([1, 2, 3, 4, 5])
      @values = [0, 2, 3] # 0 is not exist in vector
      @expected = [false, true, true, false, false]
    end

    test 'empty vector' do
      assert_equal [], Vector.new([]).is_in.to_a
    end

    test '#is_in(values)' do
      assert_equal_array [false] * 5, @vector.is_in # no value
      assert_equal_array [false] * 5, @vector.is_in([]) # empty array
      assert_equal_array [false] * 5, @vector.is_in([nil]) # nil array
      assert_equal_array @expected, @vector.is_in(*@values) # arguments
      assert_equal_array @expected, @vector.is_in(@values) # Array
      assert_equal_array @expected, @vector.is_in(Arrow::Array.new(@values)) # Arrow::Array
      assert_equal_array @expected, @vector.is_in(Vector.new(@values)) # Vector
      assert_equal_array @expected, @vector.is_in([2.0, 3.0]) # Cast
      assert_equal_array @expected, Vector.new([1.0, 2, 3, 4, 5]).is_in([2, 3]) # Cast
      assert_raise(TypeError) { @vector.is_in([1, true]) } # Can't cast
    end

    test 'chunked array' do
      chunked_vector = Vector.new(Arrow::ChunkedArray.new([[1, 2], [3, 4, 5]]))
      chunked_values = Vector.new(Arrow::ChunkedArray.new([[0, 2], [3]]))
      assert_equal_array @expected, chunked_vector.is_in(@values) # Chunked Vector
      assert_equal_array @expected, @vector.is_in(chunked_values) # Chunked values
    end

    test 'str and numeric' do
      array = ['1', 2, 3]
      assert_equal_array @expected, @vector.is_in(array)
    end

    setup do
      @uint = [1, 2, 3, 4, 5]
      @int = [2, 3, -1]
      @int_vector = Vector.new(@int)
      @uint_vector = Vector.new(@uint)
    end

    test 'uint is_in int' do
      assert_equal_array @expected, @uint_vector.is_in(@int)
      assert_equal_array @expected, @uint_vector.is_in(Arrow::Array.new(@int))
      assert_equal_array @expected, @uint_vector.is_in(@int_vector)
    end

    test 'int is_in uint' do
      expected = [true, true, false]
      assert_equal_array expected, @int_vector.is_in(@uint)
      assert_equal_array expected, @int_vector.is_in(Arrow::Array.new(@uint))
      assert_equal_array expected, @int_vector.is_in(@uint_vector)
    end
  end

  sub_test_case '#index' do
    vector = Vector.new([1, 2, 3, nil])
    test 'find index' do
      assert_equal 1, vector.index(2)
      assert_equal 3, vector.index(nil)
      assert_nil vector.index(0) # out of range
      assert_equal 1, vector.index(2.0) # types are ignored
    end
  end

  sub_test_case '#drop_nil' do
    test 'empty vector' do
      assert_equal_array [], Vector.new([]).drop_nil
    end

    test '#drop_nil' do
      assert_equal_array [1, 2], Vector.new([1, 2, nil]).drop_nil
      assert_equal_array %w[A B], Vector.new(['A', 'B', nil]).drop_nil
      assert_equal_array [true, false], Vector.new([true, false, nil]).drop_nil
      assert_equal_array [], Vector.new([nil, nil, nil]).drop_nil
    end
  end

  sub_test_case '#rank' do
    test '#rank default option' do
      float = [0.1, nil, Float::NAN, 0.2, 0.1]
      string = ['A', nil, 'C', 'B', 'A']
      expect = [0, 4, 3, 2, 1]
      assert_equal_array expect, Vector.new(float).rank
      assert_equal_array expect, Vector.new(string).rank
    end
  end

  sub_test_case '#sample' do
    setup do
      @vector = Vector.new('A'..'H')
    end

    test '#sample empty Vector' do
      assert_nil Vector.new([]).sample(1)
    end

    test '#sample negative number' do
      assert_raise(VectorArgumentError) { @vector.sample(-1) }
      assert_raise(VectorArgumentError) { @vector.sample(-1.0) }
    end

    test '#sample(0)' do
      assert_equal_array [], @vector.sample(0)
    end

    test '#sample not a number' do
      assert_raise(VectorArgumentError) { @vector.sample('1') }
    end

    test '#sample without argument' do
      sampled = @vector.sample
      assert_true @vector.to_a.include?(sampled)
    end

    test '#sample(1)' do
      sampled = @vector.sample(1)
      assert_kind_of Vector, sampled
      assert_equal 1, sampled.size
      assert_true sampled.is_in(@vector).all?
    end

    test '#sample by integer smaller than size' do
      sampled = @vector.sample(3)
      assert_equal 3, sampled.size
      assert_equal 3, sampled.uniq.size
      assert_true sampled.is_in(@vector).all?
    end

    test '#sample by integer equals to size' do
      sampled = @vector.sample(8)
      assert_equal 8, sampled.size
      assert_equal 8, sampled.uniq.size
      assert_true sampled.is_in(@vector).all?
    end

    test '#sample by integer oversampling' do
      sampled = @vector.sample(10)
      assert_equal 10, sampled.size
      assert_true sampled.uniq.size <= 8
      assert_true sampled.is_in(@vector).all?
    end

    test '#sample by float smaller than size' do
      sampled = @vector.sample(0.7)
      assert_equal 6, sampled.size
      assert_equal 6, sampled.uniq.size
      assert_true sampled.is_in(@vector).all?
    end

    test '#sample by float equals to size' do
      sampled = @vector.sample(1.0)
      assert_equal 8, sampled.size
      assert_equal 8, sampled.uniq.size
      assert_true sampled.is_in(@vector).all?
    end

    test '#sample by float oversampling' do
      sampled = @vector.sample(2.0)
      assert_equal 16, sampled.size
      assert_true sampled.uniq.size <= 8
      assert_true sampled.is_in(@vector).all?
    end
  end
end
