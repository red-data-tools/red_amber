# frozen_string_literal: true

require 'test_helper'

class DataFrameVariableOperationTest < Test::Unit::TestCase
  include RedAmber
  setup do
    @df = RedAmber::DataFrame.new(
      {
        index: [0, 1, 2, 3, nil],
        float: [0.0, 1.1,  2.2, Float::NAN, nil],
        string: ['A', 'B', 'C', 'D', nil],
        bool: [true, false, true, false, nil],
      }
    )
  end

  sub_test_case 'slice' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.slice.empty?
      assert_raise(DataFrameArgumentError) { df.slice(1) }
    end

    test 'slice by arguments' do
      assert_raise(DataFrameArgumentError) { @df.slice(1) { 2 } }
      assert_raise(DataFrameArgumentError) { @df.slice(:key) }

      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 4 strings
        # key     type   level data_preview
        1 :index  string     0 []
        2 :float  string     0 []
        3 :string string     0 []
        4 :bool   string     0 []
      OUTPUT
      assert_equal str, @df.slice.tdr_str # slice nothing
      assert_equal str, @df.slice([]).tdr_str # slice nothing

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.slice(0...@df.size).tdr_str # slice all

      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       3 [0, 1, 2]
        2 :float  double      3 [0.0, 1.1, 2.2]
        3 :string string      3 ["A", "B", "C"]
        4 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.slice(0, 1, 2).tdr_str
      assert_equal str, @df.slice([0, 1, 2]).tdr_str
      assert_equal str, @df.slice([0..2]).tdr_str

      boolean = [true, true, true, false, nil]
      assert_equal str, @df.slice(*boolean).tdr_str
      assert_equal str, @df.slice(boolean).tdr_str
      assert_equal str, @df.slice(Arrow::BooleanArray.new(boolean)).tdr_str
      assert_equal str, @df.slice(RedAmber::Vector.new(boolean)).tdr_str
      assert_equal str, @df.slice(@df[:index] < 3).tdr_str
      assert_equal str, @df.slice(!@df[:float].is_na).tdr_str
    end

    test 'slice by block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 4 strings
        # key     type   level data_preview
        1 :index  string     0 []
        2 :float  string     0 []
        3 :string string     0 []
        4 :bool   string     0 []
      OUTPUT
      assert_equal str, @df.slice { [nil] }.tdr_str # slice nothing
      assert_equal str, @df.slice { [] }.tdr_str # slice nothing

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal @df.tdr_str, @df.slice { 0...@df.size }.tdr_str # slice all

      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       3 [0, 1, 2]
        2 :float  double      3 [0.0, 1.1, 2.2]
        3 :string string      3 ["A", "B", "C"]
        4 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.slice { [0, 1, 2] }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 2 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       2 [1, 3]
        2 :float  double      2 [1.1, NaN], 1 NaN
        3 :string string      2 ["B", "D"]
        4 :bool   boolean     1 {false=>2}
      OUTPUT
      assert_equal str, @df.slice { |d| d.indexes.map(&:odd?) }.tdr_str
    end
  end

  sub_test_case 'remove' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.remove.empty?
      assert_true df.remove(:key).empty?
    end

    test 'remove by arguments' do
      assert_raise(DataFrameArgumentError) { @df.remove(1) { 2 } }
      assert_equal @df.tdr_str, @df.remove(:key).tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.remove.tdr_str # remove nothing
      assert_equal str, @df.remove([]).tdr_str # remove nothing

      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 4 strings
        # key     type   level data_preview
        1 :index  string     0 []
        2 :float  string     0 []
        3 :string string     0 []
        4 :bool   string     0 []
      OUTPUT
      assert_equal str, @df.remove(0...@df.size).tdr_str # remove all

      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       3 [0, 1, 2]
        2 :float  double      3 [0.0, 1.1, 2.2]
        3 :string string      3 ["A", "B", "C"]
        4 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.remove(3, 4).tdr_str
      assert_equal str, @df.remove([3, 4]).tdr_str
      assert_equal str, @df.remove([3..4]).tdr_str

      boolean = [false, false, nil, true, true]
      assert_equal str, @df.remove(*boolean).tdr_str
      assert_equal str, @df.remove(boolean).tdr_str
      assert_equal str, @df.remove(Arrow::BooleanArray.new(boolean)).tdr_str
      assert_equal str, @df.remove(RedAmber::Vector.new(boolean)).tdr_str
      assert_equal str, @df.remove(@df[:float].is_na).tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 4 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       4 [0, 1, 2, nil], 1 nil
        2 :float  double      4 [0.0, 1.1, 2.2, nil], 1 nil
        3 :string string      4 ["A", "B", "C", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>1, nil=>1}
      OUTPUT
      assert_equal str, @df.remove(@df[:index] > 2).tdr_str
    end

    test 'remove by block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.remove { nil }.tdr_str # remove nothing
      assert_equal str, @df.remove { [] }.tdr_str # remove nothing

      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 4 strings
        # key     type   level data_preview
        1 :index  string     0 []
        2 :float  string     0 []
        3 :string string     0 []
        4 :bool   string     0 []
      OUTPUT
      assert_equal str, @df.remove { 0...@df.size }.tdr_str # remove all

      str = <<~OUTPUT
        RedAmber::DataFrame : 2 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       2 [3, nil], 1 nil
        2 :float  double      2 [NaN, nil], 1 NaN, 1 nil
        3 :string string      2 ["D", nil], 1 nil
        4 :bool   boolean     2 [false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.remove { [0, 1, 2] }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 2 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       2 [1, 3]
        2 :float  double      2 [1.1, NaN], 1 NaN
        3 :string string      2 ["B", "D"]
        4 :bool   boolean     1 {false=>2}
      OUTPUT
      assert_equal str, @df.remove { |d| d.indexes.map(&:even?) }.tdr_str
    end
  end
end
