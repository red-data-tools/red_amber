# frozen_string_literal: true

require 'test_helper'

class DataFrameTest < Test::Unit::TestCase
  sub_test_case 'Constructor and property' do
    data(keep: true) do
      data_set = {}

      hash = { 'name' => %w[Yasuko Rui Hinata], 'age' => [68, 49, 28] }
      dataframe = RedAmber::DataFrame.new(hash)
      types = %i[string uint8]
      data_set['name/age'] = [hash, dataframe, types]

      data_set
    end

    test 'new_hash' do
      hash, df, = data
      assert_equal(Arrow::Table.new(hash), df.table)
    end

    test 'n_rows' do
      hash, df, = data
      assert_equal(hash.first.last.size, df.n_rows)
      assert_equal(hash.first.last.size, df.nrow)
      assert_equal(hash.first.last.size, df.length)
    end

    test 'n_columns' do
      hash, df, = data
      assert_equal(hash.keys.size, df.n_columns)
      assert_equal(hash.keys.size, df.ncol)
      assert_equal(hash.keys.size, df.width)
    end

    test 'shape' do
      hash, df, = data
      assert_equal([hash.first.last.size, hash.keys.size], df.shape)
    end

    test 'to_h' do
      hash, df, = data
      hash_sym = hash.each_with_object({}) do |kv, h|
        k, v = kv
        h[k.to_sym] = v
      end
      assert_equal(hash_sym, df.to_h)
    end

    test 'column_names' do
      hash, df, = data
      hash_sym = hash.each_with_object({}) do |kv, h|
        k, v = kv
        h[k.to_sym] = v
      end
      assert_equal(hash_sym.keys, df.column_names)
      assert_equal(hash_sym.keys, df.keys)
    end

    test 'types' do
      _, df, types = data
      assert_equal(types, df.types)
    end
  end

  sub_test_case 'Selecting' do
    def setup
      @df = RedAmber::DataFrame.new(x: [1, 2, 3], y: %w[A B C])
    end

    test 'column_symbol' do
      assert_equal(RedAmber::DataFrame.new(x: [1, 2, 3]), @df[:x])
    end
  end
end
