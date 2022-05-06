# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  data(keep: true) do
    a = [0, 1, nil, 4]
    h = {
      'array' => [a, :uint8, a],
      'Arrow::Array' => [a, :uint8, Arrow::UInt8Array.new(a)],
      'vector' => [a, :uint8, RedAmber::Vector.new(a)],
    }
    chunks = [Arrow::UInt32Array.new(a[0..1]),
              Arrow::UInt32Array.new(a[2..3])]
    h['chunked array'] = [a, :uint32, Arrow::ChunkedArray.new(chunks)]
    h
  end

  test 'initialize' do
    expect, _, array = data
    actual = RedAmber::Vector.new(array).to_a
    assert_equal expect, actual
  end

  test 'size' do
    expect, _, array = data
    actual = RedAmber::Vector.new(array)
    assert_equal expect.size, actual.size
  end

  test 'type' do
    _, type, array = data
    actual = RedAmber::Vector.new(array)
    assert_equal type, actual.type
  end

  test 'data_type' do
    _, type, array = data
    actual = RedAmber::Vector.new(array)
    assert_equal Arrow::Type.find(type), actual.data_type
  end
end
