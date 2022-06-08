# frozen_string_literal: true

require 'test_helper'

class DataFrameIndexableTest < Test::Unit::TestCase
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

  sub_test_case 'sort_index' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_raise(Arrow::Error::Invalid) { df.sort_indices(:key) }
    end

    test 'key error' do
      assert_raise(Arrow::Error::Invalid) { @df.sort_indices(:key_not_exist) }
      assert_raise(Arrow::Error::Invalid) { @df.sort_indices(:index, :key_not_exist) }
    end

    test 'single key' do
      assert_equal [2, 4, 0, 1, 3], @df.sort_indices(:index).to_a
      assert_equal [3, 0, 4, 2, 1], @df.sort_indices('float').to_a
      assert_equal [3, 1, 4, 0, 2], @df.sort_indices('+string').to_a
      assert_equal [1, 3, 2, 4, 0], @df.sort_indices('-bool').to_a
    end

    test 'multiple key' do
      assert_equal [4, 2, 0, 1, 3], @df.sort_indices(:index, 'float').to_a
      assert_equal [3, 0, 4, 2, 1], @df.sort_indices('+float', '-string').to_a
      assert_equal [0, 1, 4, 3, 2], @df.sort_indices('-string', '-bool').to_a
      assert_equal [1, 3, 2, 4, 0], @df.sort_indices('-bool', '-index').to_a
    end
  end

  sub_test_case 'sort' do
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
        1 :index  uint8       3 [nil, 1, 0, 0, 1], 1 nil
        2 :float  double      4 [0.0, 1.1, 1.1, NaN, nil], 1 NaN, 1 nil
        3 :string string      4 ["A", "C", "B", nil, "B"], 1 nil
        4 :bool   boolean     3 [true, nil, false, false, true], 1 nil
      OUTPUT
      assert_equal str, @df.sort('+float').tdr_str(tally: 0)

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       3 [1, nil, 0, 0, 1], 1 nil
        2 :float  double      4 [nil, 0.0, NaN, 1.1, 1.1], 1 NaN, 1 nil
        3 :string string      4 ["B", "A", nil, "B", "C"], 1 nil
        4 :bool   boolean     3 [true, true, false, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.sort('-bool').tdr_str(tally: 0)
    end

    test 'multiple key' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       3 [0, 0, 1, 1, nil], 1 nil
        2 :float  double      4 [1.1, NaN, 1.1, nil, 0.0], 1 NaN, 1 nil
        3 :string string      4 ["B", nil, "C", "B", "A"], 1 nil
        4 :bool   boolean     3 [false, false, nil, true, true], 1 nil
      OUTPUT
      assert_equal str, @df.sort(:index, 'float').tdr_str(tally: 0)

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       3 [nil, 1, 0, 0, 1], 1 nil
        2 :float  double      4 [0.0, 1.1, 1.1, NaN, nil], 1 NaN, 1 nil
        3 :string string      4 ["A", "C", "B", nil, "B"], 1 nil
        4 :bool   boolean     3 [true, nil, false, false, true], 1 nil
      OUTPUT
      assert_equal str, @df.sort('+float', '-string').tdr_str(tally: 0)
    end
  end

  sub_test_case 'map_indices' do
    test 'indices by Vector/Arrow::Array' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       3 [nil, 1, 0, 0, 1], 1 nil
        2 :float  double      4 [0.0, 1.1, 1.1, NaN, nil], 1 NaN, 1 nil
        3 :string string      4 ["A", "C", "B", nil, "B"], 1 nil
        4 :bool   boolean     3 [true, nil, false, false, true], 1 nil
      OUTPUT
      vector = Vector.new([3, 0, 4, 2, 1])
      assert_equal str, @df.map_indices(vector).tdr_str(tally: 0)
    end
  end
end
