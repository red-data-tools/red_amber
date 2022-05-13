# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case('Basic properties') do
    data(keep: true) do
      a = [0, 1, nil, 4]
      h = {
        'array' => [a, :uint8, a],
        'Arrow::Array' => [a, :uint8, Arrow::UInt8Array.new(a)],
        'vector' => [a, :uint8, Vector.new(a)],
      }
      chunks = [Arrow::UInt32Array.new(a[0..1]),
                Arrow::UInt32Array.new(a[2..3])]
      h['chunked array'] = [a, :uint32, Arrow::ChunkedArray.new(chunks)]
      h
    end

    test '.initialize' do
      expect, _, array = data
      actual = Vector.new(array).to_a
      assert_equal expect, actual
    end

    test '#size' do
      expect, _, array = data
      actual = Vector.new(array)
      assert_equal expect.size, actual.size
    end

    test '#type' do
      _, type, array = data
      actual = Vector.new(array)
      assert_equal type, actual.type
    end

    test '#data_type' do
      _, type, array = data
      actual = Vector.new(array)
      assert_equal Arrow::Type.find(type), actual.data_type
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
