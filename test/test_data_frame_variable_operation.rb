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

  sub_test_case 'pick' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.pick.empty?
      assert_raise(DataFrameArgumentError) { df.pick(1) }
    end

    test 'pick by arguments' do
      assert_raise(DataFrameArgumentError) { @df.pick(:index) { :block } }
      assert_raise(DataFrameArgumentError) { @df.pick(1, 2) }

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_true @df.pick.empty? # pick nothing
      assert_equal str, @df.pick(@df.keys).tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 1 Vector
        Vector : 1 numeric
        # key    type  level data_preview
        1 :index uint8     5 [0, 1, 2, 3, nil], 1 nil
      OUTPUT
      assert_equal str, @df.pick(:index).tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 2 numeric
        # key    type   level data_preview
        1 :index uint8      5 [0, 1, 2, 3, nil], 1 nil
        2 :float double     5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
      OUTPUT
      assert_equal str, @df.pick(:index, :float).tdr_str
      assert_equal str, @df.pick(%i[index float]).tdr_str
    end

    test 'pick by block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 1 Vector
        Vector : 1 boolean
        # key   type    level data_preview
        1 :bool boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_true @df.pick {}.empty? # pick nothing
      assert_equal str, @df.pick { :bool }.tdr_str
      assert_equal str, @df.pick { |d| d.keys.detect { |k| d[k].boolean? } }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 2 numeric
        # key    type   level data_preview
        1 :index uint8      5 [0, 1, 2, 3, nil], 1 nil
        2 :float double     5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
      OUTPUT
      assert_equal str, @df.pick { %i[index float] }.tdr_str
      assert_equal str, @df.pick { |d| d.keys.select { |k| d[k].numeric? } }.tdr_str
    end
  end

  sub_test_case 'drop' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.drop.empty?
      assert_true df.drop(:key).empty?
    end

    test 'drop by arguments' do
      assert_raise(DataFrameArgumentError) { @df.drop(:index) { :block } }
      assert_equal @df, @df.drop(1, 2)

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal @df, @df.drop # drop nothing
      assert_equal str, @df.drop([]).tdr_str
      assert_true @df.drop(@df.keys).empty?

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 1 numeric, 1 boolean
        # key    type    level data_preview
        1 :index uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :bool  boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.drop(:float, :string).tdr_str
      assert_equal str, @df.drop(%i[float string]).tdr_str
    end

    test 'drop by block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 3 Vectors
        Vectors : 2 numeric, 1 string
        # key     type   level data_preview
        1 :index  uint8      5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double     5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string     5 ["A", "B", "C", "D", nil], 1 nil
      OUTPUT
      assert_equal(@df, @df.drop { nil }) # drop nothing
      assert_equal str, @df.drop { :bool }.tdr_str
      assert_equal str, @df.drop { |d| d.keys.detect { |k| d[k].boolean? } }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 1 string, 1 boolean
        # key     type    level data_preview
        1 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        2 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.drop { %i[index float] }.tdr_str
      assert_equal str, @df.drop { |d| d.keys.select { |k| d[k].numeric? } }.tdr_str
    end
  end
end
