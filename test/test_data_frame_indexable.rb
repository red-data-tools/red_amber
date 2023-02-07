# frozen_string_literal: true

require 'test_helper'

class DataFrameIndexableTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  setup do
    @df = RedAmber::DataFrame.new(
      {
        index: [1, 1, 0, nil, 0],
        float: [1.1, nil, Float::NAN, 0.0, 1.1],
        string: ['C', 'B', nil, 'A', 'B'],
        bool: [nil, true, false, true, false],
      }
    )
  end

  sub_test_case '#indices' do
    test 'indices' do
      assert_true @df.indices.is_a?(Vector)
      assert_equal_array [*0..4], @df.indices
      assert_equal_array [*1..5], @df.indices(1)
      assert_equal_array ('a'..).take(5), @df.indices('a')
    end
  end

  sub_test_case '#sort_index' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_raise(Arrow::Error::Invalid) { df.sort_indices(:key) }
    end

    test 'key error' do
      assert_raise(Arrow::Error::Invalid) { @df.sort_indices(:key_not_exist) }
      assert_raise(Arrow::Error::Invalid) { @df.sort_indices(:index, :key_not_exist) }
    end

    test 'single key' do
      assert_equal_array [2, 4, 0, 1, 3], @df.sort_indices(:index)
      assert_equal_array [3, 0, 4, 2, 1], @df.sort_indices('float')
      assert_equal_array [3, 1, 4, 0, 2], @df.sort_indices('+string')
      assert_equal_array [1, 3, 2, 4, 0], @df.sort_indices('-bool')
    end

    test 'multiple key' do
      assert_equal_array [4, 2, 0, 1, 3], @df.sort_indices(:index, 'float')
      assert_equal_array [3, 0, 4, 2, 1], @df.sort_indices('+float', '-string')
      assert_equal_array [0, 1, 4, 3, 2], @df.sort_indices('-string', '-bool')
      assert_equal_array [1, 3, 2, 4, 0], @df.sort_indices('-bool', '-index')
    end
  end

  sub_test_case '#sort' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_raise(Arrow::Error::Invalid) { df.sort(:key) }
    end

    test 'key error' do
      assert_raise(Arrow::Error::Invalid) { @df.sort(:key_not_exist) }
      assert_raise(Arrow::Error::Invalid) { @df.sort(:index, :key_not_exist) }
    end

    test 'single key' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [nil, 1, 0, 0, 1], 1 nil
        1 :float  double      4 [0.0, 1.1, 1.1, NaN, nil], 1 NaN, 1 nil
        2 :string string      4 ["A", "C", "B", nil, "B"], 1 nil
        3 :bool   boolean     3 [true, nil, false, false, true], 1 nil
      OUTPUT
      assert_equal str, @df.sort('+float').tdr_str(tally: 0)

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [1, nil, 0, 0, 1], 1 nil
        1 :float  double      4 [nil, 0.0, NaN, 1.1, 1.1], 1 NaN, 1 nil
        2 :string string      4 ["B", "A", nil, "B", "C"], 1 nil
        3 :bool   boolean     3 [true, true, false, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.sort('-bool').tdr_str(tally: 0)
    end

    test 'multiple key' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [0, 0, 1, 1, nil], 1 nil
        1 :float  double      4 [1.1, NaN, 1.1, nil, 0.0], 1 NaN, 1 nil
        2 :string string      4 ["B", nil, "C", "B", "A"], 1 nil
        3 :bool   boolean     3 [false, false, nil, true, true], 1 nil
      OUTPUT
      assert_equal str, @df.sort(:index, 'float').tdr_str(tally: 0)

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [nil, 1, 0, 0, 1], 1 nil
        1 :float  double      4 [0.0, 1.1, 1.1, NaN, nil], 1 NaN, 1 nil
        2 :string string      4 ["A", "C", "B", nil, "B"], 1 nil
        3 :bool   boolean     3 [true, nil, false, false, true], 1 nil
      OUTPUT
      assert_equal str, @df.sort('+float', '-string').tdr_str(tally: 0)
    end
  end
end
