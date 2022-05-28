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
      assert_equal str, @df.pick { vectors.map(&:boolean?) }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 2 numeric
        # key    type   level data_preview
        1 :index uint8      5 [0, 1, 2, 3, nil], 1 nil
        2 :float double     5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
      OUTPUT
      assert_equal str, @df.pick { %i[index float] }.tdr_str
      assert_equal str, @df.pick { vectors.map(&:numeric?) }.tdr_str
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
      assert_equal str, @df.drop { vectors.map(&:boolean?) }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 1 string, 1 boolean
        # key     type    level data_preview
        1 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        2 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.drop { %i[index float] }.tdr_str
      assert_equal str, @df.drop { vectors.map(&:numeric?) }.tdr_str
    end
  end

  sub_test_case 'rename' do
    # test 'Empty dataframe' do
    #   df = DataFrame.new
    #   assert_true df.rename.empty?
    #   assert_true df.rename(:key).empty?
    # end

    test 'rename by arguments' do
      assert_raise(DataFrameArgumentError) { @df.rename(:key) { :block } }
      assert_raise(DataFrameArgumentError) { @df.rename(:key) }

      assert_equal @df, @df.rename # rename nothing
      assert_equal @df, @df.rename([])

      unchanged_key_pair = @df.keys.each_with_object({}) { |k, h| h[k] = k }
      assert_equal @df, @df.rename(unchanged_key_pair)

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float   double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string  string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool    boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.rename(:index, :integer).tdr_str
      assert_equal str, @df.rename({ index: :integer }).tdr_str
    end

    test 'rename by block' do
      assert_raise(DataFrameArgumentError) { @df.rename {} } # empty block
      assert_raise(DataFrameArgumentError) { @df.rename { nil } } # empty block
      assert_raise(DataFrameArgumentError) { @df.rename { :key } }
      assert_equal(@df, @df.rename { {} }) # rename nothing
      assert_equal(@df, @df.rename { Hash(key_not_exist: :new_key) }) # rename nothing

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float   double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string  string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool    boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.rename {
        Hash(keys.detect { |key| self[key].type == :uint8 } => :integer)
      }.tdr_str
    end

    test 'rename blank key' do
      df = DataFrame.new('' => [1, 2, 3], 'A' => [4, 5, 6])
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 2 Vectors
        Vectors : 2 numeric
        # key    type  level data_preview
        1 :blank uint8     3 [1, 2, 3]
        2 :A     uint8     3 [4, 5, 6]
      OUTPUT
      assert_equal str, df.rename(:'', 'blank').tdr_str
      assert_equal str, df.rename('': 'blank').tdr_str
    end
  end
end
