# frozen_string_literal: true

require 'test_helper'

class DataFrameSelectableTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case '#[]' do
    df = DataFrame.new(x: [1, 2, 3], y: %w[A B C])

    test 'Select variables' do
      assert_equal [1, 2, 3], df[:x].to_a
      assert_equal %w[A B C], df['y'].to_a
      assert_equal Hash(y: %w[A B C], x: [1, 2, 3]), df[:y, :x].to_h
      assert_raise(DataFrameArgumentError) { df[:x, :x] }
      assert_raise(DataFrameArgumentError) { df[:z] }
    end

    test 'Select variables with Range' do
      hash = { a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3] }
      df_range = DataFrame.new(hash)
      assert_equal hash, df_range[:a..:c].to_h
      hash.delete(:c)
      assert_equal hash, df_range[:a...:c].to_h
      assert_raise(RangeError) { df_range[:a..] }
    end

    test 'Select observations by indeces' do
      assert_equal Hash(x: [2], y: ['B']), df[1].to_h
      assert_equal Hash(x: [2, 1, 3], y: %w[B A C]), df[1, 0, 2].to_h
      assert_equal Hash(x: [3, 2], y: %w[C B]), df[-1, -2].to_h
      assert_equal Hash(x: [2, 2, 2], y: %w[B B B]), df[1, 1, 1].to_h
      assert_equal 3, df[:x].to_a[2]
    end

    test 'Select observations by Range' do
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[1..2].to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[1...3].to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[-2..-1].to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df[-2..].to_h
      assert_equal Hash(x: [1, 2], y: %w[A B]), df[..1].to_h
      assert_equal Hash(x: [1, 2], y: %w[A B]), df[nil...-1].to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df[nil..].to_h
    end

    test 'Select observations by Array with Range' do
      assert_equal Hash(x: [2, 3, 1], y: %w[B C A]), df[1..2, 0].to_h
      assert_equal Hash(x: [2, 3, 1], y: %w[B C A]), df[-2..-1, 0].to_h
      assert_equal Hash(x: [2, 3, 1], y: %w[B C A]), df[1..-1, 0..0].to_h
    end

    test 'Select observations over range' do
      assert_raise(DataFrameArgumentError) { df[3] }
      assert_raise(DataFrameArgumentError) { df[-4] }
      assert_raise(DataFrameArgumentError) { df[2..3, 0] }
      assert_raise(DataFrameArgumentError) { df[3..4, 0] }
      assert_raise(DataFrameArgumentError) { df[-4..-1] }
    end

    test 'Select observations by float index' do
      assert_equal Hash(x: [1], y: ['A']), df[0.5].to_h
      assert_equal Hash(x: [3], y: ['C']), df[-0.5].to_h
    end

    test 'Select observations by invalid data type' do
      assert_raise(DataFrameArgumentError) { df[Time.new] }
    end

    test 'Select observations by invalid length' do
      assert_raise(DataFrameArgumentError) { df[Arrow::BooleanArray.new([true, false])] }
    end

    test 'Select observations by a boolean' do
      hash = { x: [1, 2], y: %w[A B] }
      assert_equal hash, df[true, true, false].to_h
      assert_equal hash, df[true, true, nil].to_h
      assert_equal hash, df[[true, true, false]].to_h
      assert_equal hash, df[Arrow::BooleanArray.new([true, true, false])].to_h
    end

    test 'Select observations by a Vector' do
      hash = { x: [1, 2], y: %w[A B] }
      assert_equal hash, df[Vector.new([true, true, false])].to_h
      assert_equal hash, df[Vector.new([true, true, nil])].to_h
      assert_equal hash, df[df[:x] < 3].to_h
    end

    test 'Select observations by Array or Vector with nil' do
      hash = { x: [2, 3, nil], y: %w[B C] << nil }
      assert_equal hash, df[1, 2, nil].to_h
      assert_equal hash, df[Arrow::Int32Array.new([1, 2, nil])].to_h
      assert_equal hash, df[Vector.new([1, 2, nil])].to_h
    end

    test 'Select empty' do
      assert_equal(Hash(x: [], y: []), df[].to_h) # nothing to get
      assert_equal(Hash(x: [], y: []), df[nil].to_h) # nothing to get
    end

    test 'Select for empty dataframe' do
      assert_raise(DataFrameArgumentError) { DataFrame.new[0] }
    end
  end

  setup do
    @df = DataFrame.new(
      {
        index: [0, 1, 2, 3, nil],
        float: [0.0, 1.1,  2.2, Float::NAN, nil],
        string: ['A', 'B', 'C', 'D', nil],
        bool: [true, false, true, false, nil],
      }
    )
  end

  sub_test_case 'slice by arguments' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_raise(DataFrameArgumentError) { df.slice }
      assert_raise(DataFrameArgumentError) { df.slice(1) }
    end

    test 'both arguments and a block' do
      assert_raise(DataFrameArgumentError) { @df.slice(1) { 2 } }
    end

    test 'argument by key' do
      assert_raise(DataFrameArgumentError) { @df.slice(:key) }
    end

    test 'slice nothing' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       0 []
        1 :float  double      0 []
        2 :string string      0 []
        3 :bool   boolean     0 []
      OUTPUT
      assert_equal str, @df.slice.tdr_str
      assert_equal str, @df.slice([]).tdr_str
      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       0 []
        1 :float  double      0 []
        2 :string string      0 []
        3 :bool   boolean     0 []
      OUTPUT
      assert_equal str, @df.slice([false] * @df.size).tdr_str
    end

    test 'slice all' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        1 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        2 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        3 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.slice(0...@df.size).tdr_str
      assert_equal str, @df.slice([true] * @df.size).tdr_str
    end

    test 'slice by indices' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [0, 1, 2]
        1 :float  double      3 [0.0, 1.1, 2.2]
        2 :string string      3 ["A", "B", "C"]
        3 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.slice(0, 1, 2).tdr_str
      assert_equal str, @df.slice([0, 1, 2]).tdr_str
      assert_equal str, @df.slice([0..2]).tdr_str
      assert_equal str, @df.slice([0...2, 2]).tdr_str
      assert_equal str, @df.slice([0, -4, -3]).tdr_str
      assert_equal str, @df.slice([0, 1.5, -2.5]).tdr_str
      assert_equal str, @df.slice(Arrow::Array.new([0, 1, 2])).tdr_str
      assert_equal str, @df.slice(Vector.new([0, 1, 2])).tdr_str
    end

    test 'slice by booleans' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [0, 1, 2]
        1 :float  double      3 [0.0, 1.1, 2.2]
        2 :string string      3 ["A", "B", "C"]
        3 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      boolean = [true, true, true, false, nil]
      assert_equal str, @df.slice(*boolean).tdr_str
      assert_equal str, @df.slice(boolean).tdr_str
      assert_equal str, @df.slice(Arrow::BooleanArray.new(boolean)).tdr_str
      assert_equal str, @df.slice(RedAmber::Vector.new(boolean)).tdr_str
      assert_equal str, @df.slice(@df[:index] < 3).tdr_str
      assert_equal str, @df.slice(!@df[:float].is_na).tdr_str
    end
  end

  sub_test_case 'slice with the block' do
    test 'slice nothing with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       0 []
        1 :float  double      0 []
        2 :string string      0 []
        3 :bool   boolean     0 []
      OUTPUT
      assert_equal str, @df.slice { [nil] }.tdr_str
      assert_equal str, @df.slice { [] }.tdr_str
    end

    test 'slice all with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        1 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        2 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        3 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal @df.tdr_str, @df.slice { 0...size }.tdr_str
      assert_equal str, @df.slice { [true] * size }.tdr_str
    end

    test 'slice by indices with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [0, 1, 2]
        1 :float  double      3 [0.0, 1.1, 2.2]
        2 :string string      3 ["A", "B", "C"]
        3 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.slice { [0, 1, 2] }.tdr_str
      assert_equal str, @df.slice { [0..2] }.tdr_str
      assert_equal str, @df.slice { [0...2, 2] }.tdr_str
      assert_equal str, @df.slice { [0, -4, -3] }.tdr_str
      assert_equal str, @df.slice { [0, 1.5, -2.5] }.tdr_str
    end

    test 'slice by booleans with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 2 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       2 [1, 3]
        1 :float  double      2 [1.1, NaN], 1 NaN
        2 :string string      2 ["B", "D"]
        3 :bool   boolean     1 {false=>2}
      OUTPUT
      assert_equal str, @df.slice { [false, true, false, true, false] }.tdr_str
      assert_equal str, @df.slice { indexes.map(&:odd?) }.tdr_str
    end

    test 'slice by Enumerator' do
      df = DataFrame.new(x: [*0..10])
      assert_equal [1, 4, 7, 10], df.slice(1.step(by: 3, to: 10))[:x].to_a
    end
  end

  sub_test_case 'slice_by' do
    test 'Invalid arguments' do
      assert_raise(ArgumentError) { @df.slice_by {} } # no key
      assert_raise(DataFrameArgumentError) { @df.slice_by(:string) } # no block
      assert_raise(DataFrameArgumentError) { @df.slice_by(:key_not_exist) { [1, 2] } }
      assert_raise(DataFrameArgumentError) { @df.slice_by(:string) { [1, 5] } }
    end

    test 'by Range' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 2 numeric, 1 boolean
        # key    type    level data_preview
        0 :index uint8       3 [0, 1, 2]
        1 :float double      3 [0.0, 1.1, 2.2]
        2 :bool  boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.slice_by(:string) { 0..2 }.tdr_str
      assert_equal str, @df.slice_by(:string) { ..2 }.tdr_str
      assert_equal str, @df.slice_by(:string) { 'A'..'C' }.tdr_str
      assert_equal str, @df.slice_by(:string) { ..'C' }.tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 2 numeric, 1 boolean
        # key    type    level data_preview
        0 :index uint8       3 [2, 3, nil], 1 nil
        1 :float double      3 [2.2, NaN, nil], 1 NaN, 1 nil
        2 :bool  boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.slice_by(:string) { 2..-1 }.tdr_str
      assert_equal str, @df.slice_by(:string) { 2.. }.tdr_str
      assert_equal str, @df.slice_by(:string) { 'C'..nil }.tdr_str
      assert_equal str, @df.slice_by(:string) { 'C'.. }.tdr_str
    end

    test 'by Array' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 2 numeric, 1 boolean
        # key    type    level data_preview
        0 :index uint8       3 [0, 1, nil], 1 nil
        1 :float double      3 [0.0, 1.1, nil], 1 nil
        2 :bool  boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.slice_by(:string) { [0, 1, 4] }.tdr_str
      assert_equal str, @df.slice_by(:string) { [0, 1, -1] }.tdr_str
      assert_equal str, @df.slice_by(:string) { ['A', 'B', nil] }.tdr_str
    end

    test 'option keep_key: true' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [0, 1, 2]
        1 :float  double      3 [0.0, 1.1, 2.2]
        2 :string string      3 ["A", "B", "C"]
        3 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.slice_by(:string, keep_key: true) { 0..2 }.tdr_str
    end
  end

  sub_test_case 'remove by arguments' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_raise(DataFrameArgumentError) { df.remove }
      assert_raise(DataFrameArgumentError) { df.remove(1) }
    end

    test 'both arguments and a block' do
      assert_raise(DataFrameArgumentError) { @df.remove(1) { 2 } }
    end

    test 'argument by key' do
      assert_raise(DataFrameArgumentError) { @df.remove(:key) }
    end

    test 'remove nothing' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        1 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        2 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        3 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.remove.tdr_str
      assert_equal str, @df.remove([]).tdr_str
      assert_equal str, @df.remove([false] * @df.size).tdr_str
    end

    test 'remove all' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       0 []
        1 :float  double      0 []
        2 :string string      0 []
        3 :bool   boolean     0 []
      OUTPUT
      assert_equal str, @df.remove(0..4).tdr_str
      assert_equal str, @df.remove([true] * 5).tdr_str
    end

    test 'remove by indices' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [0, 1, 2]
        1 :float  double      3 [0.0, 1.1, 2.2]
        2 :string string      3 ["A", "B", "C"]
        3 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      assert_equal str, @df.remove(3, 4).tdr_str
      assert_equal str, @df.remove([3, 4]).tdr_str
      assert_equal str, @df.remove([3..4]).tdr_str
      assert_equal str, @df.remove([3...4, 4]).tdr_str
      assert_equal str, @df.remove([-2, -1]).tdr_str
      assert_equal str, @df.remove([3.5, -0.1]).tdr_str
      assert_equal str, @df.remove(Arrow::Array.new([3, 4])).tdr_str
      assert_equal str, @df.remove(Vector.new([3, 4])).tdr_str
    end

    test 'remove by booleans' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       3 [0, 1, 2]
        1 :float  double      3 [0.0, 1.1, 2.2]
        2 :string string      3 ["A", "B", "C"]
        3 :bool   boolean     2 {true=>2, false=>1}
      OUTPUT
      boolean = [false, nil, false, true, true]
      assert_equal str, @df.remove(*boolean).tdr_str
      assert_equal str, @df.remove(boolean).tdr_str
      assert_equal str, @df.remove(Arrow::BooleanArray.new(boolean)).tdr_str
      assert_equal str, @df.remove(RedAmber::Vector.new(boolean)).tdr_str
      assert_equal str, @df.remove(@df[:float].is_na).tdr_str

      str = <<~OUTPUT
        RedAmber::DataFrame : 4 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       4 [0, 1, 2, nil], 1 nil
        1 :float  double      4 [0.0, 1.1, 2.2, nil], 1 nil
        2 :string string      4 ["A", "B", "C", nil], 1 nil
        3 :bool   boolean     3 {true=>2, false=>1, nil=>1}
      OUTPUT
      assert_equal str, @df.remove(@df[:index] > 2).tdr_str
    end
  end

  sub_test_case 'remove with the block' do
    test 'remove nothing with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 5 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       5 [0, 1, 2, 3, nil], 1 nil
        1 :float  double      5 [0.0, 1.1, 2.2, NaN, nil], 1 NaN, 1 nil
        2 :string string      5 ["A", "B", "C", "D", nil], 1 nil
        3 :bool   boolean     3 {true=>2, false=>2, nil=>1}
      OUTPUT
      assert_equal str, @df.remove { nil }.tdr_str
      assert_equal str, @df.remove { [] }.tdr_str
    end

    test 'remove all with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 0 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       0 []
        1 :float  double      0 []
        2 :string string      0 []
        3 :bool   boolean     0 []
      OUTPUT
      assert_equal str, @df.remove { 0...size }.tdr_str
    end

    test 'remove by indices with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 2 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       2 [3, nil], 1 nil
        1 :float  double      2 [NaN, nil], 1 NaN, 1 nil
        2 :string string      2 ["D", nil], 1 nil
        3 :bool   boolean     2 [false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.remove { [0, 1, 2] }.tdr_str
    end

    test 'remove by booleans with the block' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 2 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       2 [1, 3]
        1 :float  double      2 [1.1, NaN], 1 NaN
        2 :string string      2 ["B", "D"]
        3 :bool   boolean     1 {false=>2}
      OUTPUT
      assert_equal str, @df.remove { indexes.map(&:even?) }.tdr_str
    end
  end

  sub_test_case 'remove_nil' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_true df.remove_nil.empty?
    end

    test 'remove_nil' do
      assert_equal <<~OUTPUT, @df.remove_nil.tdr_str
        RedAmber::DataFrame : 4 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key     type    level data_preview
        0 :index  uint8       4 [0, 1, 2, 3]
        1 :float  double      4 [0.0, 1.1, 2.2, NaN], 1 NaN
        2 :string string      4 ["A", "B", "C", "D"]
        3 :bool   boolean     2 {true=>2, false=>2}
      OUTPUT
    end
  end

  sub_test_case '#take(indices)' do
    setup do
      @df = RedAmber::DataFrame.new(x: [1, 2, 3, 4, nil], y: %w[A B C D] << nil)
    end

    test 'empty dataframe' do
      assert_true DataFrame.new({}, []).take.empty?
    end

    test '#take' do
      assert_equal(Hash(x: [], y: []), @df.take.to_h) # nothing to get
      assert_equal({ x: [2], y: ['B'] }, @df.take(1).to_h) # single value
      assert_equal({ x: [2, 4], y: %w[B D] }, @df.take(1, 3).to_h) # array without bracket
      assert_equal({ x: [4, 1, 4], y: %w[D A D] }, @df.take([3, 0, -2]).to_h) # array, negative index
      assert_equal({ x: [4, 1, 4], y: %w[D A D] }, @df.take(Vector.new([3, 0, -2])).to_h) # array, negative index
      assert_equal({ x: [4, nil, 3], y: ['D', nil, 'C'] }, @df.take([3.1, -0.5, -2.5]).to_h) # float index
    end

    test '#take out of range' do
      assert_raise(DataFrameArgumentError) { @df.take(-6) } # out of lower limit
      assert_raise(DataFrameArgumentError) { @df.take(5) } # out of upper limit
    end
  end

  sub_test_case '#filter(booleans)' do
    setup do
      @df = RedAmber::DataFrame.new(x: [1, 2, 3, 4, nil], y: %w[A B C D] << nil)
      @booleans = [true, false, nil, false, true]
      @hash = { x: [1, nil], y: ['A', nil] }
    end

    test 'empty dataframe' do
      assert_true DataFrame.new({}, []).filter.empty?
    end

    test '#filter' do
      assert_equal({ x: [], y: [] }, @df.filter.to_h) # nothing to get
      assert_equal @hash, @df.filter(*@booleans).to_h # arguments
      assert_equal @hash, @df.filter(@booleans).to_h # primitive Array
      assert_equal @hash, @df.filter(Arrow::BooleanArray.new(@booleans)).to_h # Arrow::BooleanArray
      assert_equal @hash, @df.filter(Vector.new(@booleans)).to_h # Vector
      assert_equal({ x: [], y: [] }, @df.filter([nil] * 5).to_h) # head only dataframe
    end

    test '#filter not booleans' do
      assert_raise(DataFrameArgumentError) { @df.filter(1) }
      assert_raise(DataFrameArgumentError) { @df.filter([*1..5]) }
    end

    test '#filter size unmatch' do
      assert_raise(DataFrameArgumentError) { @df.filter([true]) } # out of lower limit
    end
  end

  sub_test_case 'others' do
    df = DataFrame.new(x: [1, 2, 3], y: %w[A B C])

    test 'v method' do
      assert_equal [1, 2, 3], df.v(:x).to_a
      assert_equal %w[A B C], df.v('y').to_a
      assert_raise(DataFrameArgumentError) { df.v(:z) }
      assert_raise(DataFrameArgumentError) { df.v('') }
    end

    test 'head/first' do
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.head.to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.head(4).to_h
      assert_equal Hash(x: [1, 2], y: %w[A B]), df.head(2).to_h
      assert_equal Hash(x: [1], y: ['A']), df.first.to_h
      assert_raise(DataFrameArgumentError) { df.head(-1) }
    end

    test 'tail/last' do
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.tail.to_h
      assert_equal Hash(x: [1, 2, 3], y: %w[A B C]), df.tail(4).to_h
      assert_equal Hash(x: [2, 3], y: %w[B C]), df.tail(2).to_h
      assert_equal Hash(x: [3], y: ['C']), df.last.to_h
      assert_raise(DataFrameArgumentError) { df.tail(-1) }
    end
  end
end
