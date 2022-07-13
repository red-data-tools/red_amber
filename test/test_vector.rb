# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case('Basic properties') do
    data(keep: true) do
      a = [0, 1, nil, 4]
      # h in [expect, type, type_class, array]
      h = {
        array: [a, :uint8, Arrow::UInt8DataType, a],
        'Arrow::Array': [a, :uint8, Arrow::UInt8DataType, Arrow::UInt8Array.new(a)],
        vector: [a, :uint8, Arrow::UInt8DataType, Vector.new(a)],
        Range: [[1, 2, 3], :uint8, Arrow::UInt8DataType, 1..3],
        Float: [[1.0], :double, Arrow::DoubleDataType, 1.0],
      }
      chunks = [Arrow::UInt32Array.new(a[0..1]),
                Arrow::UInt32Array.new(a[2..3])]
      h['chunked array'] = [a, :uint32, Arrow::UInt32DataType, Arrow::ChunkedArray.new(chunks)]
      h
    end

    test '.initialize' do
      expect, _, _, array = data
      actual = Vector.new(array).to_a
      assert_equal expect, actual
    end

    test '.initialize by an expanded Array' do
      array = [1, 2, 3]
      assert_equal array, Vector.new(*array).to_a
    end

    test '#size' do
      expect, _, _, array = data
      actual = Vector.new(array)
      assert_equal expect.size, actual.size
    end

    test '#indices' do
      assert_equal [0, 1, 2], Vector.new(%w[A B C]).indices
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
  end

  sub_test_case('type check') do
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
  end

  sub_test_case('#inspect') do
    setup do
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
end
