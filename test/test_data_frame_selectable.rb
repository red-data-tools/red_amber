# frozen_string_literal: true

require 'test_helper'

class DataFrameSelectableTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case '#[]' do
    df = DataFrame.new(x: [1, 2, 3], y: %w[A B C])

    test 'Select variables' do
      assert_equal [1, 2, 3], df[:x].to_a
      assert_equal %w[A B C], df['y'].to_a
      assert_equal Hash(y: %w[A B C], x: [1, 2, 3]), df[:y, :x].to_h
      assert_equal Hash(x: [1, 2, 3]), df[:x, :x].to_h
      assert_raise(DataFrameArgumentError) { df[:z] }
    end

    test 'Select variables with Range' do
      hash = { a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3] }
      df_range = DataFrame.new(hash)
      assert_equal hash, df_range[:a..:c].to_h
      hash.delete(:c)
      assert_equal hash, df_range[:a...:c].to_h
      assert_raise(RangeError) { df_range[:a..] }
    end

    test 'Select observations by indeces' do
      assert_equal Hash(x: [2], y: ['B']), df[1].to_h
      assert_equal Hash(x: [2, 1, 3], y: %w[B A C]), df[1, 0, 2].to_h
      assert_equal Hash(x: [3, 2], y: %w[C B]), df[-1, -2].to_h
      assert_equal Hash(x: [2, 2, 2], y: %w[B B B]), df[1, 1, 1].to_h
      assert_equal 3, df[:x].to_a[2]
    end

    test 'Select observations by Range' do
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[1..2].to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[1...3].to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[-2..-1].to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[-2..].to_h
      assert_equal Hash(x: [1, 2], y: %w[A B]), df[..1].to_h
      assert_equal Hash(x: [1, 2], y: %w[A B]), df[nil...-1].to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df[nil..].to_h
    end

    test 'Select observations by Array with Range' do
      assert_equal Hash(x: [2, 3, 1], y: %w[B C A]), df[1..2, 0].to_h
      assert_equal Hash(x: [2, 3, 1], y: %w[B C A]), df[-2..-1, 0].to_h
      assert_equal Hash(x: [2, 3, 1], y: %w[B C A]), df[1..-1, 0..0].to_h
    end

    test 'Select observations over range' do
      assert_raise(Arrow::Error::Index) { df[3] }
      assert_raise(Arrow::Error::Index) { df[-4] }
      assert_raise(DataFrameArgumentError) { df[2..3, 0] }
      assert_raise(DataFrameArgumentError) { df[3..4, 0] }
      assert_raise(DataFrameArgumentError) { df[-4..-1] }
    end

    test 'Select observations by invalid index' do
      assert_raise(DataFrameArgumentError) { df[0.5] }
    end

    test 'Select rows by invalid data type' do
      assert_raise(DataFrameArgumentError) { df[Time.new] }
    end

    test 'Select rows by invalid length' do
      assert_raise(DataFrameArgumentError) { df[Arrow::Int32Array.new([1, 2])] }
      assert_raise(Arrow::Error::Invalid) { df[Arrow::BooleanArray.new([true, false])] }
    end

    test 'Select observations by a boolean' do
      hash = { x: [1, 2], y: %w[A B] }
      assert_equal hash, df[true, true, false].to_h
      assert_equal hash, df[true, true, nil].to_h
      assert_equal hash, df[[true, true, false]].to_h
      assert_equal hash, df[Arrow::BooleanArray.new([true, true, false])].to_h
    end

    test 'Select observations by a Vector' do
      hash = { x: [1, 2], y: %w[A B] }
      assert_equal hash, df[Vector.new([true, true, false])].to_h
      assert_equal hash, df[Vector.new([true, true, nil])].to_h
      assert_equal hash, df[df[:x] < 3].to_h
    end

    test 'Select observations by a invalid Array or Vector' do
      hash = { x: [1, 2], y: %w[A B] }
      assert_raise(DataFrameArgumentError) { df[1, 2, nil] }
      assert_raise(DataFrameArgumentError) { df[Arrow::Int32Array.new([1, 2, nil])] }
      assert_equal hash, df[Vector.new([1, 2, nil])].to_h
    end

    test 'Select empty' do
      assert_raise(DataFrameArgumentError) { df[] }
    end

    test 'Select for empty dataframe' do
      assert_raise(DataFrameArgumentError) { DataFrame.new[0] }
    end
  end

  sub_test_case '#take(indices)' do
    setup do
      @df = RedAmber::DataFrame.new(x: [1, 2, 3, 4, nil], y: %w[A B C D] << nil)
    end

    test 'empty dataframe' do
      assert_true DataFrame.new({}, []).take.empty?
    end

    test '#take' do
      assert_true @df.take.empty?
      assert_equal({ x: [2], y: ['B'] }, @df.take(1).to_h) # single value
      assert_equal({ x: [2, 4], y: %w[B D] }, @df.take(1, 3).to_h) # array without bracket
      assert_equal({ x: [4, 1, 4], y: %w[D A D] }, @df.take([3, 0, -2]).to_h) # array, negative index
      assert_equal({ x: [4, 1, 4], y: %w[D A D] }, @df.take(Vector.new([3, 0, -2])).to_h) # array, negative index
      assert_equal({ x: [4, nil, 3], y: ['D', nil, 'C'] }, @df.take([3.1, -0.5, -2.5]).to_h) # float index
    end

    test '#take out of range' do
      assert_raise(DataFrameArgumentError) { @df.take(-6) } # out of lower limit
      assert_raise(DataFrameArgumentError) { @df.take(5) } # out of upper limit
    end
  end

  sub_test_case '#filter(booleans)' do
    setup do
      @df = RedAmber::DataFrame.new(x: [1, 2, 3, 4, nil], y: %w[A B C D] << nil)
      @booleans = [true, false, nil, false, true]
      @hash = { x: [1, nil], y: ['A', nil] }
    end

    test 'empty dataframe' do
      assert_true DataFrame.new({}, []).filter.empty?
    end

    test '#filter' do
      assert_equal({ x: [], y: [] }, @df.filter.to_h) # nothing to get
      assert_equal @hash, @df.filter(*@booleans).to_h # arguments
      assert_equal @hash, @df.filter(@booleans).to_h # primitive Array
      assert_equal @hash, @df.filter(Arrow::BooleanArray.new(@booleans)).to_h # Arrow::BooleanArray
      assert_equal @hash, @df.filter(Vector.new(@booleans)).to_h # Vector
      assert_equal({ x: [], y: [] }, @df.filter([nil] * 5).to_h) # head only dataframe
    end

    test '#filter not booleans' do
      assert_raise(DataFrameArgumentError) { @df.filter(1) }
      assert_raise(DataFrameArgumentError) { @df.filter([*1..5]) }
    end

    test '#filter size unmatch' do
      assert_raise(DataFrameArgumentError) { @df.filter([true]) } # out of lower limit
    end
  end

  sub_test_case 'others' do
    df = DataFrame.new(x: [1, 2, 3], y: %w[A B C])

    test 'v method' do
      assert_equal [1, 2, 3], df.v(:x).to_a
      assert_equal %w[A B C], df.v('y').to_a
      assert_raise(DataFrameArgumentError) { df.v(:z) }
      assert_raise(DataFrameArgumentError) { df.v('') }
    end

    test 'head/first' do
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.head.to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.head(4).to_h
      assert_equal Hash(x: [1, 2], y: %w[A B]), df.head(2).to_h
      assert_equal Hash(x: [1], y: ['A']), df.first.to_h
      assert_raise(DataFrameArgumentError) { df.head(-1) }
    end

    test 'tail/last' do
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.tail.to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.tail(4).to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df.tail(2).to_h
      assert_equal Hash(x: [3], y: ['C']), df.last.to_h
      assert_raise(DataFrameArgumentError) { df.tail(-1) }
    end
  end
end
