# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case '#initialize' do
    test 'initialize by empty array' do
      assert_equal_array [], Vector.new([])
    end

    test 'initialize by arrays including nils' do
      assert_equal_array [nil], Vector.new([nil])
      assert_equal_array [nil, nil], Vector.new([nil, nil])
    end

    test 'initialize by an Array' do
      array = [1, 2, 3]
      assert_equal_array array, Vector.new(array)
    end

    test 'initialize by an expanded Array' do
      array = [1, 2, 3]
      assert_equal_array array, Vector.new(*array)
    end

    test 'initialize by an Arrow::Array' do
      a = [1, 2, 3]
      ary = Arrow::Array.new(a)
      assert_equal_array a, Vector.new(ary)
    end

    test 'initialize by an Arrow::ChunkedArray' do
      a = [[1, 2, 3]]
      ary = Arrow::ChunkedArray.new(a)
      assert_equal_array a.flatten, Vector.new(ary)
    end

    test 'initialize by a Vector' do
      array = [1, 2, 3]
      vector = Vector.new(array)
      assert_equal_array array, Vector.new(vector)
    end

    test 'initialize by a Range' do
      range = 1..3
      assert_equal_array [*range], Vector.new(range)
    end

    test 'initialize by Numo::NArray' do
      numo = Numo::Int8.new(3).seq(-1)
      assert_equal_array [-1, 0, 1], Vector.new(numo)
    end
  end

  sub_test_case 'Vector[]' do
    test 'Vector[] by empty array' do
      assert_equal_array [], Vector[[]]
      assert_equal_array [], Vector[]
    end

    test 'Vector[] by arrays including nils' do
      assert_equal_array [nil], Vector[nil]
      assert_equal_array [nil, nil], Vector[nil, nil]
    end

    test 'Vector[] by an Array' do
      array = [1, 2, 3]
      assert_equal_array array, Vector[array]
    end

    test 'Vector[] by an expanded Array' do
      array = [1, 2, 3]
      assert_equal_array array, Vector[*array]
    end
  end

  sub_test_case '#resolve' do
    test '#resolve integer upcast' do
      assert_equal :uint16, Vector.new(256).resolve([1]).type
      assert_equal :uint16, Vector.new(256).resolve(Vector.new(1)).type
    end

    test '#resolve integer overflow' do
      assert_equal_array [0], Vector.new(1).resolve([256])
    end

    test '#resolve string' do
      assert_equal_array ['1'], Vector.new('A').resolve([1])
    end

    test '#resolve string to integer' do
      assert_equal_array [65], Vector.new(1).resolve(['A'])
    end

    test '#resolve invalid argument' do
      assert_raise(VectorArgumentError) { Vector.new(1).resolve(1) }
    end
  end

  sub_test_case 'Basic properties' do
    data(keep: true) do
      a = [0, 1, nil, 4]
      s = [%w[a b]]
      chunks = [Arrow::UInt32Array.new(a[0..1]),
                Arrow::UInt32Array.new(a[2..3])]

      # [expect, type, type_class, array]
      {
        array: [a, :uint8, Arrow::UInt8DataType, a],
        'Arrow::Array': [a, :uint8, Arrow::UInt8DataType, Arrow::UInt8Array.new(a)],
        vector: [a, :uint8, Arrow::UInt8DataType, Vector.new(a)],
        Range: [[1, 2, 3], :uint8, Arrow::UInt8DataType, 1..3],
        Float: [[1.0], :double, Arrow::DoubleDataType, 1.0],
        list: [s, :list, Arrow::ListDataType, s],
        'chunked array': [a, :uint32, Arrow::UInt32DataType, Arrow::ChunkedArray.new(chunks)],
        'list chunked array': [[s], :list, Arrow::ListDataType, [s]],
      }
    end

    test 'initialize' do
      expect, _, _, array = data
      actual = Vector.new(array)
      assert_equal expect, actual.to_a
    end

    test '#to_arrow_array' do
      _, _, _, array = data
      assert_true(Vector.new(array).to_arrow_array.any? { [is_a?(Arrow::Array), is_a?(Arrow::ChunkedArray)] })
    end

    test '#size' do
      expect, _, _, array = data
      actual = Vector.new(array)
      assert_equal expect.size, actual.size
    end

    test '#indices' do
      assert_equal_array [0, 1, 2], Vector.new(%w[A B C]).indices
    end

    test '#to_ary' do
      assert_equal [1, 2, 3, 4], [1, 2] + Vector.new([3, 4])
    end

    test '#empty?' do
      assert_true Vector.new([]).empty?
    end

    test '#type' do
      _, type, _, array = data
      actual = Vector.new(array)
      assert_equal type, actual.type
    end

    test '#type_class' do
      _, _, type_class, array = data
      actual = Vector.new(array)
      assert_equal type_class, actual.type_class
    end

    test '#has_nil?' do
      assert_true Vector.new([1, 2, nil]).has_nil?
      assert_false Vector.new([1, 2, 3]).has_nil?
    end

    test '#each' do
      expect, _, _, array = data
      vector = Vector.new(array)
      assert_kind_of Enumerator, vector.each
      assert_equal_array expect.first, vector.each.next
    end

    test '#map' do
      expect, _, _, array = data
      vector = Vector.new(array)
      assert_kind_of Enumerator, vector.map
      assert_kind_of Vector, vector.map { _1 }
      assert_equal_array expect, vector.map { _1 }
    end
  end

  sub_test_case 'chunked arrays' do
    setup do
      chunks = [[*0..1], [*2..3]]
      @chunked_array = Arrow::ChunkedArray.new(chunks)
    end

    test '#chunked?' do
      assert_true Vector.new(@chunked_array).chunked?
    end

    test '#n_chunks' do
      assert_equal 2, Vector.new(@chunked_array).n_chunks
    end
  end

  sub_test_case 'type check' do
    test '#boolean?' do
      assert_true Vector.new([true, false, nil]).boolean?
    end

    test '#numeric?/#float?' do
      v = Vector.new([1.0, 2, 3])
      assert_true v.numeric?
      assert_true v.float?
    end

    test '#numeric?/#integer?' do
      v = Vector.new([1, -2, 3])
      assert_true v.numeric?
      assert_true v.integer?
    end

    test '#string?' do
      assert_true Vector.new(%w[A B C]).string?
    end

    test '#temporal?' do
      assert_true Vector.new(Arrow::Date32Array.new([19_186])).temporal?
    end

    test '#dictionary?' do
      assert_true Vector.new(Arrow::Array.new(%i[a b c])).dictionary?
    end

    test '#list?' do
      assert_true Vector.new(Arrow::Array.new([%i[a b c]])).list?
      assert_true Vector.new(Arrow::ChunkedArray.new([[%i[a b c]]])).list?
    end
  end

  sub_test_case '#inspect' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = nil
      @double = Vector.new([0.3841307461261749, 0.6028782725334167, 0.3752671480178833, 0.9437413811683655])
      @string = Vector.new([*'A'..'P'])
    end

    test 'double default' do
      exp = <<~OUTPUT
        #<RedAmber::Vector(:double, size=4):#{format '0x%016x', @double.object_id}>
        [0.3841307461261749, 0.6028782725334167, 0.3752671480178833, 0.9437413811683655]
      OUTPUT
      assert_equal exp, @double.inspect
    end

    test 'double l=79' do
      exp = <<~OUTPUT
        #<RedAmber::Vector(:double, size=4):#{format '0x%016x', @double.object_id}>
        [0.3841307461261749, 0.6028782725334167, 0.3752671480178833, ... ]
      OUTPUT
      assert_equal exp, @double.inspect(limit: 79)
    end

    test 'string default' do
      exp = <<~OUTPUT
        #<RedAmber::Vector(:string, size=16):#{format '0x%016x', @string.object_id}>
        ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"]
      OUTPUT
      assert_equal exp, @string.inspect
    end

    test 'string l=79' do
      exp = <<~OUTPUT
        #<RedAmber::Vector(:string, size=16):#{format '0x%016x', @string.object_id}>
        ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", ... ]
      OUTPUT
      assert_equal exp, @string.inspect(limit: 79)
    end
  end

  sub_test_case '#inspect with minimum mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'Minimum'
      @double = Vector.new([0.3841307461261749, 0.6028782725334167, 0.3752671480178833, 0.9437413811683655])
      @string = Vector.new([*'A'..'P'])
    end

    test 'double default' do
      assert_equal 'RedAmber::Vector(:double, size=4)', @double.inspect
      assert_equal 'RedAmber::Vector(:string, size=16)', @string.inspect
    end
  end

  sub_test_case 'coerce' do
    test '#add' do
      array = [1, 2, 3, nil]
      vector = Vector.new(array)
      assert_equal array, (0 + vector).to_a
    end

    test '#multiply' do
      vector = Vector.new([1, 2, 3, nil])
      assert_equal [-1.0, -2.0, -3.0, nil], (-1.0 * vector).to_a
      assert_equal :double, (-1.0 * vector).type
    end
  end

  sub_test_case '#propagate' do
    setup do
      @vector = Vector.new(1, 2, 3, 4)
      @expected = [2.5, 2.5, 2.5, 2.5]
    end

    test 'propagate mean' do
      assert_equal_array @expected, @vector.propagate(:mean)
    end

    test 'propagate by block' do
      # same as @vector.propagate { |v| v.mean }
      assert_equal_array @expected, @vector.propagate(&:mean)
    end

    test 'propagate with element-wise method' do
      assert_raise(VectorArgumentError) { @vector.propagate(:round) }
    end

    test 'propagate with argument and block' do
      assert_raise(VectorArgumentError) { @vector.propagate(:mean) { 2.5 } }
    end
  end

  sub_test_case 'module_function .arrow_doc' do
    test 'add' do
      expected = <<~OUT
        add(x, y): Add the arguments element-wise
        ---
        Results will wrap around on integer overflow.
        Use function "add_checked" if you want overflow
        to return an error.
      OUT
      assert_equal expected.chomp, ArrowFunction.arrow_doc(:add).to_s
    end
  end
end
