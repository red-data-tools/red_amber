# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include RedAmber
  include Helper

  sub_test_case('drop_nil') do
    test 'empty vector' do
      assert_equal [], Vector.new([]).drop_nil.to_a
    end

    test 'drop_nil' do
      assert_equal [1, 2], Vector.new([1, 2, nil]).drop_nil.to_a
      assert_equal %w[A B], Vector.new(['A', 'B', nil]).drop_nil.to_a
      assert_equal [true, false], Vector.new([true, false, nil]).drop_nil.to_a
      assert_equal [], Vector.new([nil, nil, nil]).drop_nil.to_a
    end
  end
end
