# frozen_string_literal: true

require 'test_helper'

class DataFrameSelectableTest < Test::Unit::TestCase
  sub_test_case 'Selecting' do
    df = RedAmber::DataFrame.new(x: [1, 2, 3], y: %w[A B C])

    test 'Select columns' do
      assert_equal Hash(x: [1, 2, 3]), df[:x].to_h
      assert_equal Hash(y: %w[A B C]), df['y'].to_h
      assert_equal Hash(y: %w[A B C], x: [1, 2, 3]), df[:y, :x].to_h
      assert_equal Hash(x: [1, 2, 3]), df[:x, :x].to_h
    end

    test 'Select rows' do
      assert_equal Hash(x: [2], y: ['B']), df[1].to_h
      assert_equal Hash(x: [2, 1, 3], y: %w[B A C]), df[1, 0, 2].to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[1..2].to_h
      assert_equal Hash(x: [3, 2], y: %w[C B]), df[-1, -2].to_h
      assert_equal Hash(x: [2, 3, 1], y: %w[B C A]), df[1..2, 0].to_h
      assert_equal Hash(x: [2, 2, 2], y: %w[B B B]), df[1, 1, 1].to_h
      assert_equal Hash(x: [3]), df[:x][2].to_h
    end

    test 'Select rows over range' do
      assert_raise(RedAmber::DataFrameArgumentError) { df[3] }
      assert_raise(RedAmber::DataFrameArgumentError) { df[-4] }
    end

    test 'Select rows by invalid index' do
      assert_raise(RedAmber::DataFrameArgumentError) { df[0.5] }
    end

    test 'Select rows by invalid type' do
      assert_raise(RedAmber::DataFrameArgumentError) { df[Arrow::Int32Array.new([1, 2])] }
    end

    test 'Select empty' do
      assert_raise(RedAmber::DataFrameArgumentError) { df[] }
    end

    test 'Select for empty dataframe' do
      assert_raise(RedAmber::DataFrameArgumentError) { RedAmber::DataFrame.new[0] }
    end

    test 'head/first' do
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.head.to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.head(4).to_h
      assert_equal Hash(x: [1, 2], y: %w[A B]), df.head(2).to_h
      assert_equal Hash(x: [1], y: ['A']), df.first.to_h
      assert_raise(RedAmber::DataFrameArgumentError) { df.head(-1) }
    end

    test 'tail/last' do
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.tail.to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.tail(4).to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df.tail(2).to_h
      assert_equal Hash(x: [3], y: ['C']), df.last.to_h
      assert_raise(RedAmber::DataFrameArgumentError) { df.tail(-1) }
    end
  end
end
