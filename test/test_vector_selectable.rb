# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include RedAmber
  include Helper

  sub_test_case('drop_nil') do
    test 'empty vector' do
      assert_equal [], Vector.new([]).drop_nil.to_a
    end

    test 'drop_nil' do
      assert_equal [1, 2], Vector.new([1, 2, nil]).drop_nil.to_a
      assert_equal %w[A B], Vector.new(['A', 'B', nil]).drop_nil.to_a
      assert_equal [true, false], Vector.new([true, false, nil]).drop_nil.to_a
      assert_equal [], Vector.new([nil, nil, nil]).drop_nil.to_a
    end
  end

  sub_test_case('#take(indices), #[](indices)') do
    setup do
      @string = Vector.new(%w[A B C D E])
    end

    test 'empty vector' do
      assert_equal [], Vector.new([]).take.to_a
    end

    test '#take' do
      assert_equal [], @string.take.to_a
      assert_equal %w[B], @string.take(1).to_a # single value
      assert_equal %w[B D], @string.take(1, 3).to_a # array without bracket
      assert_equal %w[D A D], @string.take([3, 0, -2]).to_a # array, negative index
      assert_equal %w[D A D], @string.take(Vector.new([3, 0, -2])).to_a # array, negative index
      assert_equal %w[D E C], @string.take([3.1, -0.5, -2.5]).to_a # float index
    end

    test '#take out of range' do
      assert_raise(VectorArgumentError) { @string.take(-6) } # out of lower limit
      assert_raise(VectorArgumentError) { @string.take(5) } # out of upper limit
    end
  end

  sub_test_case('#filter(booleans)') do
    setup do
      @string = Vector.new(%w[A B C D E])
      @booleans = [true, false, nil, false, true]
    end

    test 'empty vector' do
      assert_equal [], Vector.new([]).filter.to_a
    end

    test '#filter' do
      assert_equal [], @string.filter.to_a
      assert_equal %w[A E], @string.filter(*@booleans).to_a # arguments
      assert_equal %w[A E], @string.filter(@booleans).to_a # primitive Array
      assert_equal %w[A E], @string.filter(Arrow::BooleanArray.new(@booleans)).to_a # Arrow::BooleanArray
      assert_equal %w[A E], @string.filter(Vector.new(@booleans)).to_a # Vector
      assert_equal [], @string.filter([nil] * 5).to_a # nil array
    end

    test '#filter not booleans' do
      assert_raise(VectorTypeError) { @string.filter(1) }
      assert_raise(VectorTypeError) { @string.filter([*1..5]) }
    end

    test '#filter size unmatch' do
      assert_raise(VectorArgumentError) { @string.filter([true]) } # out of lower limit
    end
  end

  sub_test_case '#[]' do
    setup do
      @string = Vector.new(%w[A B C D E])
      @booleans = [true, false, nil, false, true]
    end

    test 'empty vector' do
      assert_equal [], Vector.new([])[].to_a
    end

    test '#[indices]' do
      assert_equal %w[B], @string[1].to_a # single value
      assert_equal %w[D A D], @string[[3, 0, -2]].to_a # array, negative index
      assert_equal %w[D A D], @string[Vector.new([3, 0, -2])].to_a # array, negative index
      assert_equal %w[D E C], @string[3.1, -0.5, -2.5].to_a # float index
      assert_equal %w[D A D], @string[Arrow::Array.new([3, 0, -2])].to_a # Arrow
    end

    test '#[booleans]' do
      assert_equal %w[B], @string[1].to_a # single value
      assert_equal %w[A E], @string[*@booleans].to_a # arguments
      assert_equal %w[A E], @string[@booleans].to_a # primitive Array
      assert_equal %w[A E], @string[Arrow::BooleanArray.new(@booleans)].to_a # Arrow::BooleanArray
      assert_equal %w[A E], @string[Vector.new(@booleans)].to_a # Vector
      assert_raise(VectorArgumentError) { @string[nil] } # nil array
      assert_raise(VectorArgumentError) { @string[[nil] * 5] } # nil array
    end

    test '#[Range]' do
      assert_equal %w[B C D], @string[1..3] # Normal Range
      assert_equal %w[B C D E], @string[1..] # Endless Range
      assert_equal %w[A B C], @string[..2] # Beginless Range
      assert_equal %w[B C D], @string[1..-2] # Range to index from tail
      assert_raise(RedAmber::DataFrameArgumentError) { @string[1..6] }
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
      assert_equal [false] * 5, @vector.is_in.to_a # no value
      assert_equal [false] * 5, @vector.is_in([]).to_a # empty array
      assert_equal [false] * 5, @vector.is_in([nil]).to_a # nil array
      assert_equal @expected, @vector.is_in(*@values).to_a # arguments
      assert_equal @expected, @vector.is_in(@values).to_a # Array
      assert_equal @expected, @vector.is_in(Arrow::Array.new(@values)).to_a # Arrow::Array
      assert_equal @expected, @vector.is_in(Vector.new(@values)).to_a # Vector
      assert_equal @expected, @vector.is_in([2.0, 3.0]).to_a # Cast
      assert_equal @expected, Vector.new([1.0, 2, 3, 4, 5]).is_in([2, 3]).to_a # Cast
      assert_equal [true, false, false, false, false], @vector.is_in([1, '2']).to_a # [1, '2'] => [1, 50]
      assert_raise(TypeError) { @vector.is_in([1, true]) } # Can't cast
    end
  end

  sub_test_case '#index' do
    vector = Vector.new([1, 2, 3, nil])
    test 'found index' do
      assert_equal 1, vector.index(2)
      assert_equal 3, vector.index(nil)
      assert_nil vector.index(0) # out of range
      assert_equal 1, vector.index(2.0) # types are ignored
    end
  end
end
