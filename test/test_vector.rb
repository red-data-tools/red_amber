# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  @expected = [0, 1, nil, 4]

  data do
    data = {}
    data < {
      'Arrow::Array' => Arrow::UInt32Array.new(@expected),
      'array' => @expected,
      'vector' => RedAmber::Vector.new(@expected),
    }
    chunks = [Arrow::UInt32Array.new([0, 1]),
              Arrow::UInt32Array.new([nil, 4])]
    data['chunked array'] = Arrow::ChunkedArray.new(chunks)
    data
  end
  test 'initialize' do
    actual = RedAmber::Vector.new(data).to_a
    assert_equal @expected, actual
  end
end
