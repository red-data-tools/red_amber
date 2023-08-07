# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  sub_test_case 'MatchSubString family' do
    setup do
      @vector = Vector.new('array', 'Arrow', 'carrot', nil, 'window')
      @vector2 = Vector.new('amber', 'Amazon', 'banana', nil)
    end

    test '#match_substring?(string)' do
      expected = [true, false, true, nil, false]
      assert_equal_array expected, @vector.match_substring('arr')
    end

    test '#match_substring?(regexp)' do
      expected = [true, false, true, nil, false]
      assert_equal_array expected, @vector.match_substring(/arr/)
    end

    test '#match_substring?(regexp_ignore_case)' do
      expected = [true, true, true, nil, false]
      assert_equal_array expected, @vector.match_substring(/arr/i)
    end

    test '#match_substring(regexp, ignore_case: true)' do
      expected = [true, true, true, nil, false]
      assert_equal_array expected, @vector.match_substring(/arr/, ignore_case: true)
    end

    test '#match_substring w/ illegal argument' do
      assert_raise(VectorArgumentError) { @vector.match_substring(nil) }
    end

    test '#end_with(string)' do
      expected = [false, true, false, nil, true]
      assert_equal_array expected, @vector.end_with('ow')
    end

    test '#start_with(string)' do
      expected = [false, false, true, nil, false]
      assert_equal_array expected, @vector.start_with('ca')
    end

    test '#match_like(string)' do
      expected = [true, true, false, nil, false]
      assert_equal_array expected, @vector.match_like('_rr%')
    end

    test '#count_substring(string)' do
      expected = [0, 0, 2, nil]
      assert_equal_array expected, @vector2.count_substring('an')
    end

    test '#count_substring(regexp_ignore_case)' do
      expected = [1, 1, 2, nil]
      assert_equal_array expected, @vector2.count_substring(/a[mn]/i)
    end

    test '#count_substring w/ illegal argument' do
      assert_raise(VectorArgumentError) { @vector2.count_substring(nil) }
    end

    test '#find_substring(string)' do
      expected = [0, -1, 1, nil, -1]
      assert_equal_array expected, @vector.find_substring('arr')
    end

    test '#find_substring(regexp) case ignored' do
      expected = [0, 0, 1, nil, -1]
      assert_equal_array expected, @vector.find_substring(/arr/i)
      assert_equal_array expected, @vector.find_substring(/arr/, ignore_case: true)
    end

    test '#find_substring w/ illegal argument' do
      assert_raise(VectorArgumentError) { @vector.find_substring(nil) }
    end
  end
end
