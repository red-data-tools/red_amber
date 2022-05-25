# frozen_string_literal: true

require 'test_helper'

class DataFrameSelectableTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case 'Selecting' do
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
      assert_raise(DataFrameArgumentError) { df[3] }
      assert_raise(DataFrameArgumentError) { df[-4] }
      assert_raise(DataFrameArgumentError) { df[2..3, 0] }
      assert_raise(DataFrameArgumentError) { df[3..4, 0] }
      assert_raise(DataFrameArgumentError) { df[-4..-1] }
    end

    test 'Select observations by invalid index' do
      assert_raise(DataFrameArgumentError) { df[0.5] }
    end

    test 'Select observations by invalid type' do
      assert_raise(DataFrameArgumentError) { df[Arrow::Int32Array.new([1, 2])] }
    end

    test 'Select empty' do
      assert_raise(DataFrameArgumentError) { df[] }
    end

    test 'Select for empty dataframe' do
      assert_raise(DataFrameArgumentError) { DataFrame.new[0] }
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
