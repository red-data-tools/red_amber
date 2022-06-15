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

  sub_test_case('#take(indices), #[](indices)') do
    setup do
      @string = Vector.new(%w[A B C D E])
    end

    test 'empty vector' do
      assert_equal [], Vector.new([]).take.to_a
    end

    test '#take' do
      assert_equal [], @string.take.to_a
      assert_equal %w[B], @string.take(1).to_a # single value
      assert_equal %w[B D], @string.take(1, 3).to_a # array without bracket
      assert_equal %w[D A D], @string.take([3, 0, -2]).to_a # array, negative index
      assert_equal %w[D A D], @string.take(Vector.new([3, 0, -2])).to_a # array, negative index
      assert_equal %w[D E C], @string.take([3.1, -0.5, -2.5]).to_a # float index
    end

    test '#take out of range' do
      assert_raise(VectorArgumentError) { @string.take(-6) } # out of lower limit
      assert_raise(VectorArgumentError) { @string.take(5) } # out of upper limit
    end

    test '#[]' do
      assert_equal %w[B], @string[1].to_a # single value
      assert_equal %w[D A D], @string[[3, 0, -2]].to_a # array, negative index
      assert_equal %w[D A D], @string[Vector.new([3, 0, -2])].to_a # array, negative index
      assert_equal %w[D E C], @string[3.1, -0.5, -2.5].to_a # float index
    end
  end
end
