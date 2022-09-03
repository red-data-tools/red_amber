# frozen_string_literal: true

require 'test_helper'

class DataFrameVariableOperationTest < Test::Unit::TestCase
  include RedAmber
  setup do
    @df = DataFrame.new(
      index: [0, 1, 2, 3, nil],
      float: [0.0, 1.1,  2.2, Float::NAN, nil],
      string: ['A', 'B', 'C', 'D', nil],
      bool: [true, false, true, false, nil]
    )
  end

  sub_test_case 'pick' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.pick.empty?
      assert_raise(VectorArgumentError) { df.pick(1) }
    end

    test 'pick by arguments' do
      assert_raise(DataFrameArgumentError) { @df.pick(:index) { :block } }

      assert_true @df.pick.empty? # pick nothing
      assert_equal @df.tdr_str, @df.pick(@df.keys).tdr_str # pick all

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 1 Vector
        Vector : 1 numeric
        # key    type  level data_preview
        1 :index uint8     5 [0, 1, 2, 3, nil], 1 nil
      OUTPUT
      assert_equal str, @df.pick(:index).tdr_str
      assert_equal str, @df.pick(0).tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 2 numeric
        # key    type   level data_preview
        1 :index uint8      5 [0, 1, 2, 3, nil], 1 nil
        2 :float double     5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
      OUTPUT
      assert_equal str, @df.pick(:index, :float).tdr_str
      assert_equal str, @df.pick(%i[index float]).tdr_str
      assert_equal str, @df.pick(0, 1).tdr_str
      assert_equal str, @df.pick([0, 1]).tdr_str
      assert_equal str, @df.pick([0, -3]).tdr_str
      assert_equal str, @df.pick(0..1).tdr_str
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
      assert_equal str, @df.pick { 3 }.tdr_str
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
      assert_equal str, @df.pick { [0, 1] }.tdr_str
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

      assert_equal @df, @df.drop # drop nothing
      assert_equal @df, @df.drop([]) # drop nothing
      assert_true @df.drop(@df.keys).empty? # drop all

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 1 numeric, 1 boolean
        # key    type    level data_preview
        1 :index uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :bool  boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.drop(:float, :string).tdr_str
      assert_equal str, @df.drop(%i[float string]).tdr_str
      assert_equal str, @df.drop(1, -2).tdr_str
      assert_equal str, @df.drop(1..2).tdr_str
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
      assert_equal str, @df.drop { -1 }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 2 Vectors
        Vectors : 1 string, 1 boolean
        # key     type    level data_preview
        1 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        2 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.drop { %i[index float] }.tdr_str
      assert_equal str, @df.drop { vectors.map(&:numeric?) }.tdr_str
      assert_equal str, @df.drop { [0, 1] }.tdr_str
    end
  end

  sub_test_case 'rename' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.rename.empty?
      assert_raise(DataFrameArgumentError) { df.rename(:key) }
    end

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
      assert_equal(@df, @df.rename {}) # empty block
      assert_equal(@df, @df.rename { nil }) # empty block
      assert_raise(DataFrameArgumentError) { @df.rename { :key } }
      assert_equal(@df, @df.rename { {} }) # rename nothing
      assert_raise(DataFrameArgumentError) { @df.rename { { key_not_exist: :new_key } } }

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
        { keys.detect { |key| self[key].type == :uint8 } => :integer }
      }.tdr_str
    end

    test 'rename with array' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float   double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string  string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool    boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.rename(%i[index integer]).tdr_str
      assert_equal str, @df.rename { %i[index integer] }.tdr_str

      str2 = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :double  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string  string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool    boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str2, @df.rename(%i[index integer], %i[float double]).tdr_str
      assert_equal str2, @df.rename([%i[index integer], %i[float double]]).tdr_str
      assert_equal str2, @df.rename { [%i[index integer], %i[float double]] }.tdr_str
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
      assert_equal str, df.rename(:unnamed1, :blank).tdr_str
      assert_equal str, df.rename(unnamed1: :blank).tdr_str
    end
  end

  sub_test_case 'assign' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.assign.empty?
      assert_raise(DataFrameArgumentError) { df.assign(:key) } # Causes error for key only
      assert_equal <<~OUTPUT, df.assign(key: []).tdr_str # You can add vector with size zero to empty dataframe
        RedAmber::DataFrame : 0 x 1 Vector
        Vector : 1 string
        # key  type   level data_preview
        1 :key string     0 []
      OUTPUT
    end

    test 'assign by arguments' do
      assert_raise(DataFrameArgumentError) { @df.assign(:key) } # key only

      assert_equal @df, @df.assign # assign nothing
      assert_equal @df, @df.assign(nil) # assign nil
      assert_equal @df, @df.assign([]) # assign empty array
      assert_equal @df, @df.assign({}) # assign empty hash

      unchanged_pair = @df.keys.each_with_object({}) { |k, h| h[k] = @df[k].to_a }
      assert_equal @df.tdr_str, @df.assign(unchanged_pair).tdr_str

      assigner = { new: %w[a a b b c] }
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
        5 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
      OUTPUT
      assert_equal str, @df.assign(assigner).tdr_str
      assert_equal str, @df.assign(new: %w[a a b b c]).tdr_str # directly write assigner
      assert_equal str, @df.assign(assigner.to_a).tdr_str
      assert_equal str, @df.assign(*assigner.to_a).tdr_str # assign(:x, ary) style

      assigner2 = { index: [-1, -2, -3, -4, -5], new: %w[a a b b c] }
      str2 = <<~OUTPUT
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :index  int8        5 [-1, -2, -3, -4, -5]
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
        5 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
      OUTPUT
      assert_equal str2, @df.assign(assigner2).tdr_str
      assert_equal str2, @df.assign(assigner2.to_a).tdr_str
      assert_equal str2, @df.assign(*assigner2.to_a).tdr_str # assign([:x, ary1], [:y, ary2]) style
    end

    test 'assign by block' do
      assert_raise(DataFrameArgumentError) { @df.assign { :key } } # key only
      assert_equal(@df, @df.assign {}) # assign nothing
      assert_equal(@df, @df.assign { nil }) # assign nothing
      assert_equal(@df, @df.assign { {} }) # assign nothing
      assert_equal(@df, @df.assign { [] }) # assign nothing

      assigner = { new: %w[a a b b c] }
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
        5 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
      OUTPUT
      assert_equal str, @df.assign { assigner }.tdr_str
      assert_equal str, @df.assign { assigner.to_a }.tdr_str

      assigner2 = { index: [-1, -2, -3, -4, -5], new: %w[a a b b c] }
      str2 = <<~OUTPUT
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :index  int8        5 [-1, -2, -3, -4, -5]
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
        5 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
      OUTPUT
      assert_equal str2, @df.assign { assigner2 }.tdr_str
      assert_equal str2, @df.assign { assigner2.to_a }.tdr_str
    end

    test 'assign by both args and block' do
      assert_raise(DataFrameArgumentError) { @df.assign(:key) {} } # rubocop:disable Lint/EmptyBlock

      str = <<~STR
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
        5 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
      STR
      assert_equal str, @df.assign(:new) { %w[a a b b c] }.tdr_str

      str2 = <<~STR
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :index  int8        5 [-1, -2, -3, -4, -5]
        2 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        3 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        4 :bool   boolean     3 {true=>2, false=>2, nil=>1}
        5 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
      STR
      assert_equal str2, @df.assign(:index, :new) { [[-1, -2, -3, -4, -5], %w[a a b b c]] }.tdr_str
    end

    test 'assign_left by param' do
      assigner = { index: [-1, -2, -3, -4, -5], new: %w[a a b b c] }
      assert_equal <<~OUTPUT, @df.assign_left(assigner).tdr_str
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
        2 :index  int8        5 [-1, -2, -3, -4, -5]
        3 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        4 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        5 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
    end

    test 'assign_left by block' do
      assigner = { index: [-1, -2, -3, -4, -5], new: %w[a a b b c] }
      assert_equal <<~OUTPUT, @df.assign_left { assigner }.tdr_str
        RedAmber::DataFrame : 5 x 5 Vectors
        Vectors : 2 numeric, 2 strings, 1 boolean
        # key     type    level data_preview
        1 :new    string      3 {"a"=>2, "b"=>2, "c"=>1}
        2 :index  int8        5 [-1, -2, -3, -4, -5]
        3 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        4 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        5 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
    end
  end
end
