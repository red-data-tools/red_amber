# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case '#match_substring?' do
    setup do
      @vector = Vector.new('array', 'Arrow', 'carrot', nil, 'window')
    end

    test '#match_substring?(string)' do
      expected = [true, false, true, nil, false]
      assert_equal_array expected, @vector.match_substring?('arr')
    end

    test '#match_substring?(regexp)' do
      expected = [true, false, true, nil, false]
      assert_equal_array expected, @vector.match_substring?(/arr/)
    end

    test '#match_substring?(regexp_ignore_case)' do
      expected = [true, true, true, nil, false]
      assert_equal_array expected, @vector.match_substring?(/arr/i)
    end

    test '#match_substring?(regexp, ignore_case: true)' do
      expected = [true, true, true, nil, false]
      assert_equal_array expected, @vector.match_substring?(/arr/, ignore_case: true)
    end

    test '#match_substring? w/ illegal argument' do
      assert_raise(VectorArgumentError) { @vector.match_substring?(nil) }
    end

    test '#end_with?(string)' do
      expected = [false, true, false, nil, true]
      assert_equal_array expected, @vector.end_with?('ow')
    end

    test '#start_with?(string)' do
      expected = [false, false, true, nil, false]
      assert_equal_array expected, @vector.start_with?('ca')
    end
  end
end
