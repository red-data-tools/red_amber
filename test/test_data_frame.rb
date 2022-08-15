# frozen_string_literal: true

require 'test_helper'

class DataFrameTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case 'Constructor' do
    test 'new empty DataFrame' do
      assert_equal [], DataFrame.new.table.columns
      assert_equal [], DataFrame.new([]).table.columns
      assert_equal [], DataFrame.new(nil).table.columns
    end

    hash = { x: [1, 2, 3] }
    df = DataFrame.new(hash)
    data('hash 1 variable', [hash, df], keep: true)

    hash = { x: [1, 2, 3], 'y' => %w[A B C] }
    df = DataFrame.new(hash)
    data('hash 2 variables', [hash, df], keep: true)

    test 'new from a Hash' do |(h, d)|
      assert_equal Arrow::Table.new(h), d.table
    end

    test 'new from a DataFrame' do |(_, d)|
      assert_equal d.table, DataFrame.new(d).table
    end

    test 'new from a Arrow::Table' do |(h, _)|
      table = Arrow::Table.new(h)
      df = DataFrame.new(table)
      assert_equal table, df.table
    end

    test 'new from schema and Array' do
      expected = DataFrame.new(x: [1, 2, 3])
      schema = { x: :uint8 }
      array = [[1], [2], [3]]
      assert_equal expected, DataFrame.new(schema, array)
    end

    test 'new from a Rover::DataFrame' do |(h, d)|
      require 'rover'
      rover = Rover::DataFrame.new(h)
      assert_equal d, DataFrame.new(rover)
    end

    test 'Select observations by invalid type' do
      int32_array = Arrow::Int32Array.new([1, 2])
      assert_raise(DataFrameTypeError) { DataFrame.new(int32_array) }
    end

    test 'empty key renaming' do
      df = DataFrame.new('': [1, 2], unnamed1: [3, 4])
      assert_equal %i[unnamed2 unnamed1], df.keys
    end
  end

  sub_test_case 'Properties' do
    hash = { x: [1, 2, 3], y: %w[A B C] }
    data('hash data',
         [hash, DataFrame.new(hash), %i[uint8 string]],
         keep: true)
    data('empty data',
         [{}, DataFrame.new, []],
         keep: true)

    test 'size' do
      hash, df, = data
      size = hash.empty? ? 0 : hash.values.first.size
      assert_equal size, df.size
      assert_equal size, df.n_rows
    end

    test 'indices' do
      hash, df, = data
      size = hash.empty? ? 0 : hash.values.first.size
      assert_equal (0...size).to_a, df.indices
      assert_equal (1..size).to_a, df.indices(1)
      assert_equal ('a'..).take(size), df.indices('a')
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
      assert_equal types, df.type_classes
    end

    test 'variables, keys, vectors' do
      _, df, = data
      assert_equal df.variables.keys, df.keys
      assert_equal df.variables.values, df.vectors
    end
  end

  sub_test_case 'init_instance_vars' do
    test 'key?' do
      df = DataFrame.new(x: [1, 2, 3])
      assert_true df.key?(:x)
    end

    test 'key_index' do
      df = DataFrame.new(x: [1, 2, 3])
      assert_equal 0, df.key_index(:x)
    end
  end

  sub_test_case 'each_row' do
    test 'each_row' do
      df = DataFrame.new(x: [1, 2, 3], y: [4, 5, 6])
      assert_kind_of Enumerator, df.each_row
      # This will crash on 8.0.0
      assert_equal [{ x: 1, y: 4 },
                    { x: 2, y: 5 },
                    { x: 3, y: 6 }], df.each_row.to_a
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
      assert_equal DataFrame.new(hash), DataFrame.new(schema, array)
      assert_equal hash, DataFrame.new(hash).to_h
      assert_equal schema, DataFrame.new(hash).schema
      assert_equal array, DataFrame.new(hash).to_a
    end

    test 'rover I/O' do
      require 'rover'
      # Rover::DataFrame doesn't support empty dataframe
      hash = { name: %w[Yasuko Rui Hinata], age: [68, 49, 28] }
      redamber = DataFrame.new(hash)
      rover = Rover::DataFrame.new(hash)
      assert_equal redamber, DataFrame.new(rover)
      assert_equal rover, redamber.to_rover
    end
  end

  sub_test_case 'to_iruby in table mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'Table'
    end

    test 'empty' do
      df = DataFrame.new
      assert_equal ['text/plain', '(empty DataFrame)'], df.to_iruby
    end

    test 'simple dataframe' do
      df = DataFrame.new(x: [1, 2, Float::NAN], y: ['', ' ', nil], z: [true, false, nil])
      html = 'RedAmber::DataFrame <3 x 3 vectors> <table><tr><th>x</th><th>y</th><th>z</th></tr><tr><td>1.0</td><td>""</td><td>true</td></tr><tr><td>2.0</td><td>" "</td><td>false</td></tr><tr><td>NaN</td><td><i>(nil)</i></td><td><i>(nil)</i></td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end

    test 'long dataframe' do
      df = RedAmber::DataFrame.new(x: [*1..10])
      html = 'RedAmber::DataFrame <10 x 1 vector> <table><tr><th>x</th></tr><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr><tr><td>4</td></tr><tr><td>&#8942;</td></tr><tr><td>8</td></tr><tr><td>9</td></tr><tr><td>10</td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end

    test 'wide dataframe' do
      raw_record = (1..16).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = RedAmber::DataFrame.new(raw_record)
      html = 'RedAmber::DataFrame <1 x 16 vectors> <table><tr><th>A</th><th>B</th><th>C</th><th>D</th><th>E</th><th>F</th><th>G</th><th>&#8230;</th><th>J</th><th>K</th><th>L</th><th>M</th><th>N</th><th>O</th><th>P</th></tr><tr><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>&#8230;</td><td>10</td><td>11</td><td>12</td><td>13</td><td>14</td><td>15</td><td>16</td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end
  end

  sub_test_case 'to_iruby in tdr mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'TDR'
    end

    test 'empty' do
      df = DataFrame.new
      assert_equal ['text/plain', '(empty DataFrame)'], df.to_iruby
    end

    test 'simple dataframe' do
      df = DataFrame.new(x: [1, 2, Float::NAN], y: ['', ' ', nil], z: [true, false, nil])
      html = <<~OUTPUT
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key type    level data_preview
        1 :x  double      3 [1.0, 2.0, NaN], 1 NaN
        2 :y  string      3 ["", " ", nil], 1 nil
        3 :z  boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal html, df.to_iruby[1]
    end

    test 'long dataframe' do
      df = RedAmber::DataFrame.new(x: [*1..10])
      html = <<~OUTPUT
        RedAmber::DataFrame : 10 x 1 Vector
        Vector : 1 numeric
        # key type  level data_preview
        1 :x  uint8    10 [1, 2, 3, 4, 5, ... ]
      OUTPUT
      assert_equal html, df.to_iruby[1]
    end

    test 'wide dataframe' do
      raw_record = (1..16).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = RedAmber::DataFrame.new(raw_record)
      html = <<~OUTPUT
        RedAmber::DataFrame : 1 x 16 Vectors
        Vectors : 16 numeric
        #  key type  level data_preview
        1  :A  uint8     1 [1]
        2  :B  uint8     1 [2]
        3  :C  uint8     1 [3]
        4  :D  uint8     1 [4]
        5  :E  uint8     1 [5]
        6  :F  uint8     1 [6]
        7  :G  uint8     1 [7]
        8  :H  uint8     1 [8]
        9  :I  uint8     1 [9]
        10 :J  uint8     1 [10]
         ... 6 more Vectors ...
      OUTPUT
      assert_equal html, df.to_iruby[1]
    end
  end
end
