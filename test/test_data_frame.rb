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

    test 'new from schema and Array' do
      expected = RedAmber::DataFrame.new(x: [1, 2, 3])
      schema = { x: :uint8 }
      array = [[1], [2], [3]]
      assert_equal expected, RedAmber::DataFrame.new(schema, array)
    end

    test 'new from a Rover::DataFrame' do |(h, d)|
      rover = Rover::DataFrame.new(h)
      assert_equal d, RedAmber::DataFrame.new(rover)
    end

    test 'Select observations by invalid type' do
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

    test 'size' do
      hash, df, = data
      size = hash.empty? ? 0 : hash.values.first.size
      assert_equal size, df.size
      assert_equal size, df.n_rows
    end

    test 'n_keys' do
      hash, df, = data
      assert_equal hash.keys.size, df.n_keys
      assert_equal hash.keys.size, df.n_cols
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

    test 'variable_names' do
      hash, df, = data
      hash_sym = hash.each_with_object({}) do |kv, h|
        k, v = kv
        h[k.to_sym] = v
      end
      assert_equal hash_sym.keys, df.keys
      assert_equal hash_sym.keys, df.column_names
    end

    test 'key?' do
      hash, df, = data
      assert_equal hash.key?(:x), df.key?(:x)
      assert_false df.key?(:z)
    end

    test 'key_index' do
      hash, df, = data
      assert_equal hash.keys.index(:x), df.key_index(:x)
      assert_nil df.key_index(:z)
    end

    test 'types' do
      _, df, types = data
      assert_equal types, df.types
    end

    test 'data_types' do
      _, df, types = data
      types = [Arrow::UInt8DataType, Arrow::StringDataType] if types == %i[uint8 string]
      assert_equal types, df.data_types
    end
  end

  sub_test_case '.new and .to_ I/O' do
    # data in Array(hash, schema, array)
    data(
      'string and integer',
      [
        { name: %w[Yasuko Rui Hinata], age: [68, 49, 28] },
        { name: :string, age: :uint8 },
        [['Yasuko', 68], ['Rui', 49], ['Hinata', 28]],
      ], keep: true
    )
    data('empty', [{}, {}, []], keep: true)

    test 'hash I/O' do
      hash, schema, array = data
      assert_equal RedAmber::DataFrame.new(hash), RedAmber::DataFrame.new(schema, array)
      assert_equal hash, RedAmber::DataFrame.new(hash).to_h
      assert_equal schema, RedAmber::DataFrame.new(hash).schema
      assert_equal array, RedAmber::DataFrame.new(hash).to_a
    end

    test 'rover I/O' do
      # Rover::DataFrame doesn't support empty dataframe
      hash = { name: %w[Yasuko Rui Hinata], age: [68, 49, 28] }
      redamber = RedAmber::DataFrame.new(hash)
      rover = Rover::DataFrame.new(hash)
      assert_equal redamber, RedAmber::DataFrame.new(rover)
      assert_equal rover, redamber.to_rover
    end
  end
end
