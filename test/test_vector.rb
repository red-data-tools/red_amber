# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  data do
    array = [0, 1, nil, 4]
    h = {
      'array' =>
        [array, array],
      'Arrow::Array' =>
        [array, Arrow::UInt32Array.new(array)],
      'vector' =>
        [array, RedAmber::Vector.new(array)],
    }
    chunks = [Arrow::UInt32Array.new(array[0..1]),
              Arrow::UInt32Array.new(array[2..3])]
    h['chunked array'] =
      [array, Arrow::ChunkedArray.new(chunks)]
    h
  end

  test 'initialize' do
    expect, actual = data
    actual = RedAmber::Vector.new(actual).to_a
    assert_equal expect, actual
  end
end
