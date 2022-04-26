# frozen_string_literal: true

require 'test_helper'

class DataFrameTest < Test::Unit::TestCase
  sub_test_case 'Constructor' do
    test 'new empty DataFrame' do
      assert_equal [], RedAmber::DataFrame.new.table.columns
      assert_equal [], RedAmber::DataFrame.new([]).table.columns
      assert_equal [], RedAmber::DataFrame.new(nil).table.columns
    end

    hash = { x: [1, 2, 3] }
    df = RedAmber::DataFrame.new(hash)
    data('hash 1 colum', [hash, df], keep: true)

    hash = { x: [1, 2, 3], 'y' => %w[A B C] }
    df = RedAmber::DataFrame.new(hash)
    data('hash 2 colums', [hash, df], keep: true)

    test 'new from a Hash' do
      hash, df = data
      assert_equal Arrow::Table.new(hash), df.table
    end

    test 'new from a RedAmber::DataFrame' do
      _, df = data
      assert_equal df.table, RedAmber::DataFrame.new(df).table
    end

    test 'new from a Arrow::Table' do
      hash, = data
      table = Arrow::Table.new(hash)
      df = RedAmber::DataFrame.new(table)
      assert_equal table, df.table
    end

    test 'new from an Array' do
      # assert_equal
    end

    test 'new from a Rover::DataFrame' do
      # aeert_equal
    end

    test 'Select rows by invalid type' do
      int32_array = Arrow::Int32Array.new([1, 2])
      assert_raise(RedAmber::DataFrameTypeError) { RedAmber::DataFrame.new(int32_array) }
    end
  end

  sub_test_case 'Properties' do
    hash = { x: [1, 2, 3], y: %w[A B C] }
    data('hash data',
         [hash, RedAmber::DataFrame.new(hash), %i[uint8 string]],
         keep: true)
    data('empty data',
         [{}, RedAmber::DataFrame.new, []],
         keep: true)

    test 'n_rows' do
      hash, df, = data
      size = hash.empty? ? 0 : hash.values.first.size
      assert_equal size, df.n_rows
      assert_equal size, df.nrow
      assert_equal size, df.length
    end

    test 'n_columns' do
      hash, df, = data
      assert_equal hash.keys.size, df.n_columns
      assert_equal hash.keys.size, df.ncol
      assert_equal hash.keys.size, df.width
    end

    test 'empty?' do
      hash, df = data
      assert_equal hash.empty?, df.empty?
    end

    test 'shape' do
      hash, df, = data
      expected = hash.empty? ? [0, 0] : [hash.values.first.size, hash.keys.size]
      assert_equal expected, df.shape
    end

    test 'to_h' do
      hash, df, = data
      hash_sym = hash.each_with_object({}) do |kv, h|
        k, v = kv
        h[k.to_sym] = v
      end
      assert_equal hash_sym, df.to_h
    end

    test 'column_names' do
      hash, df, = data
      hash_sym = hash.each_with_object({}) do |kv, h|
        k, v = kv
        h[k.to_sym] = v
      end
      assert_equal hash_sym.keys, df.column_names
      assert_equal hash_sym.keys, df.keys
    end

    test 'types' do
      _, df, types = data
      assert_equal types, df.types
    end
  end

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
