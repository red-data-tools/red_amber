# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  def setup
    @array = Arrow::UInt32Array.new([0, 1, nil, 4])
    @vector = RedAmber::Vector.new(array)
  end

  def test_new
    assert_equal @array, @vector.data
  end
end
