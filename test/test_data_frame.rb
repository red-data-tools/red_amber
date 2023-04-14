# frozen_string_literal: true

require 'test_helper'

class DataFrameTest < Test::Unit::TestCase
  include TestHelper
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

    test 'invalid argument' do
      assert_raise(DataFrameTypeError) { DataFrame.new(Object.new) }
    end

    test 'Select observations by invalid type' do
      int32_array = Arrow::Int32Array.new([1, 2])
      assert_raise(DataFrameTypeError) { DataFrame.new(int32_array) }
    end

    test 'empty key renaming' do
      df = DataFrame.new('': [1, 2], unnamed1: [3, 4])
      assert_equal %i[unnamed2 unnamed1], df.keys
    end

    test 'new from a to_arrow-resposible object' do |(h, _)|
      table = Arrow::Table.new(h)
      (o = Object.new).define_singleton_method(:to_arrow) { table }

      df = DataFrame.new(o)
      assert_equal df.table, table
    end

    test 'new from a to_arrow-resposible object that returns non-Arrow::Table' do |(_, d)|
      (o = Object.new).define_singleton_method(:to_arrow) { d }
      assert_raise(DataFrameTypeError) { DataFrame.new(o) }
    end

    test 'new from a to_h-resposible object but does not return valid table' do |(_, d)|
      (o = Object.new).define_singleton_method(:to_h) { d }
      assert_raise(DataFrameTypeError) { DataFrame.new(o) }
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

  sub_test_case 'red-arrow-numo-narray' do
    setup do
      require 'arrow-numo-narray'
      Numo::NArray.srand(42)
    end

    test 'new from numo-narray' do
      assert_equal <<~EXPECTED, DataFrame.new(numo: Numo::DFloat.new(3).rand).tdr_str
        RedAmber::DataFrame : 3 x 1 Vector
        Vector : 1 numeric
        # key   type   level data_preview
        0 :numo double     3 [0.3206787829442638, 0.2756491628580763, 0.1659554879682396]
      EXPECTED
    end
  end

  sub_test_case 'SubFrames builders from DataFrame' do
    setup do
      @df = DataFrame.new(
        x: [*1..6],
        y: %w[A A B B B C],
        z: [false, true, false, nil, true, false]
      )
      # @df is:
      #         x y        z
      #   <uint8> <string> <boolean>
      # 0       1 A        false
      # 1       2 A        true
      # 2       3 B        false
      # 3       4 B        (nil)
      # 4       5 B        true
      # 5       6 C        false
    end

    test '#sub_by_value' do
      sf = @df.sub_by_value(:y)
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       6 C        false
      STR
    end

    setup do
      @expected = <<~STR
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        ---
                x y        z
          <uint8> <string> <boolean>
        0       2 A        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        ---
                x y        z
          <uint8> <string> <boolean>
        0       4 B        (nil)
        ---
                x y        z
          <uint8> <string> <boolean>
        0       5 B        true
        ---
        + 1 more DataFrame.
      STR
    end

    test '#sub_by_value(key1, key2)' do
      sf = @df.sub_by_value(:y, :z)
      assert_kind_of SubFrames, sf
      assert_equal @expected, sf.to_s
    end

    test '#sub_by_value([key1, key2])' do
      sf = @df.sub_by_value(%i[y z])
      assert_kind_of SubFrames, sf
      assert_equal @expected, sf.to_s
    end

    test '#sub_by_window with size and step' do
      sf = @df.sub_by_window(size: 4, step: 2)
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        2       3 B        false
        3       4 B        (nil)
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        3       6 C        false
      STR
    end

    test '#sub_by_window with from and size' do
      sf = @df.sub_by_window(from: 1, size: 4)
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       2 A        true
        1       3 B        false
        2       4 B        (nil)
        3       5 B        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        3       6 C        false
      STR
    end

    test '#sub_by_enum `each_slice`' do
      sf = @df.sub_by_enum(:each_slice, 3)
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        2       3 B        false
        ---
                x y        z
          <uint8> <string> <boolean>
        0       4 B        (nil)
        1       5 B        true
        2       6 C        false
      STR
    end

    test '#sub_by_enum `each_cons`' do
      sf = @df.sub_by_enum(:each_cons, 4)
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        2       3 B        false
        3       4 B        (nil)
        ---
                x y        z
          <uint8> <string> <boolean>
        0       2 A        true
        1       3 B        false
        2       4 B        (nil)
        3       5 B        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        3       6 C        false
      STR
    end

    test '#sub_by_kernel `each_slice`' do
      sf = @df.sub_by_kernel([true, false, false, true], step: 2)
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       4 B        (nil)
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       6 C        false
      STR
    end

    test '#build_subframes' do
      sf = @df.build_subframes([[0, 2, 4], [1, 3, 5]])
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
        2       5 B        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       2 A        true
        1       4 B        (nil)
        2       6 C        false
      STR
    end

    test '#build_subframes by block' do
      sf = @df.build_subframes do
        even = indices.map(&:even?)
        [even, !even]
      end
      assert_kind_of SubFrames, sf
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
        2       5 B        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       2 A        true
        1       4 B        (nil)
        2       6 C        false
      STR
    end
  end

  sub_test_case '#propagate' do
    setup do
      @df = DataFrame.new(x: [1, 2, 3])
    end

    test '#propagate empty DataFrame' do
      df = DataFrame.new
      assert_equal_array [], df.propagate('any_value')
    end

    test '#propagate scalar' do
      assert_equal_array %w[A A A], @df.propagate('A')
    end

    test '#propagate with block' do
      assert_equal_array([6, 6, 6], @df.propagate { x.sum })
    end
  end

  sub_test_case 'method_missing' do
    setup do
      @df = DataFrame.new(number: [1, 2, 3], 'string.1': %w[Aa Bb Cc])
    end

    test 'key as a method' do
      assert_raise(NoMethodError) { @df.key_not_exist }
      assert_equal_array [1, 2, 3], @df.number
    end

    test 'key as a method in block' do
      assert_equal <<~STR, @df.assign { [:number, number / 10.0] }.tdr_str
        RedAmber::DataFrame : 3 x 2 Vectors
        Vectors : 1 numeric, 1 string
        # key         type   level data_preview
        0 :number     double     3 [0.1, 0.2, 0.3]
        1 :"string.1" string     3 ["Aa", "Bb", "Cc"]
      STR
    end
  end
end
