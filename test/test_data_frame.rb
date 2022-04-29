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
    data('hash 1 column', [hash, df], keep: true)

    hash = { x: [1, 2, 3], 'y' => %w[A B C] }
    df = RedAmber::DataFrame.new(hash)
    data('hash 2 colums', [hash, df], keep: true)

    test 'new from a Hash' do |(h, d)|
      assert_equal Arrow::Table.new(h), d.table
    end

    test 'new from a RedAmber::DataFrame' do |(_, d)|
      assert_equal d.table, RedAmber::DataFrame.new(d).table
    end

    test 'new from a Arrow::Table' do |(h, _)|
      table = Arrow::Table.new(h)
      df = RedAmber::DataFrame.new(table)
      assert_equal table, df.table
    end

    test 'new from an Array' do
      # assert_equal
    end

    test 'new from a Rover::DataFrame' do |(h, d)|
      rover = Rover::DataFrame.new(h)
      assert_equal d, RedAmber::DataFrame.new(rover)
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

    test 'types class' do
      _, df, types = data
      types = [Arrow::UInt8DataType, Arrow::StringDataType] if types == %i[uint8 string]
      assert_equal types, df.types(class_name: true)
    end
  end

  sub_test_case '.new and .to_ I/O' do
    data = [
      'string and integer',
      [
        { name: %w[Yasuko Rui Hinata], age: [68, 49, 28] },
        { name: :string, age: :uint8 },
        [['Yasuko', 68], ['Rui', 49], ['Hinata', 28]],
      ],
    ]
    data = ['empty', [{}, {}, []]]

    test 'hash I/O' do |hash, schema, array|
      assert_equal DataFrame.new(hash), DataFrame.new(schema, array)
      assert_equal hash, DataFrame.new(hash).to_h
      assert_equal schema, DataFrame.new(hash).schema
      assert_equal array, DataFrame.new(hash).to_a
    end

    test 'rover I/O' do |hash,|
      redamber = DataFrame.new(hash)
      rover = Rover::DataFrame.new(hash)
      assert_equal redamber, DataFrame.new(rover)
      assert_equal rover, redamber.to_rover
    end
  end
end
