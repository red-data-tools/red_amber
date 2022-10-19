# frozen_string_literal: true

require 'test_helper'

class DataFrameDisplayableTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case '#concatenate' do
    setup do
      @df = DataFrame.new(
        x: [1, 2],
        y: %w[A B]
      )

      @other = DataFrame.new(
        x: [3, 4],
        y: %w[C D]
      )
    end

    test 'empty argument' do
      assert_equal @df, @df.concatenate
      assert_equal @df, @df.concatenate(nil)
      assert_equal @df, @df.concatenate([]) # empty Array returns self
    end

    test 'not a Table or a DataFrame' do
      assert_raise(DataFrameArgumentError) { @df.concatenate(@df.to_h) } # Hash
      assert_raise(DataFrameArgumentError) { @df.concatenate(@df.to_a) } # Array
    end

    test 'concatenate single Table/DataFrame' do
      expected = <<~STR
                x y
          <uint8> <string>
        0       1 A
        1       2 B
        2       3 C
        3       4 D
      STR
      assert_equal expected, @df.concatenate(@other.table).to_s
      assert_equal expected, @df.concatenate(@other).to_s
    end

    test 'concatenate a Array of Tables/DataFrames' do
      expected = <<~STR
                x y
          <uint8> <string>
        0       1 A
        1       2 B
        2       3 C
        3       4 D
        4       1 A
        5       2 B
      STR
      assert_equal expected, @df.concatenate([@other.table, @df.table]).to_s
      assert_equal expected, @df.concatenate(@other, @df).to_s
      assert_equal expected, @df.concatenate([@other, @df]).to_s
    end

    test 'illegal dataframe shape' do
      assert_raise(Arrow::Error::Invalid) { @df.concatenate(@other.rename(:x, :z)) } # key mismatch
      assert_raise(Arrow::Error::Invalid) { @df.concatenate(@other.assign(z: [true, false])) } # shape mismatch
    end

    test 'type mismatch' do
      assert_raise(Arrow::Error::Invalid) { @df.concatenate(@other.assign(:y, :x) { [x, y] }) } # type mismatch
      assert_raise(Arrow::Error::Invalid) { @df.concatenate(@other.assign(:x) { x.map(&:to_f) }) } # type mismatch
    end
  end

  sub_test_case '#merge' do
    setup do
      @df = DataFrame.new(
        x: [1, 2],
        y: [3, 4]
      )

      @other = DataFrame.new(
        a: %w[A B],
        b: %w[C D]
      )
    end

    test 'empty argument' do
      assert_equal @df, @df.merge
      assert_equal @df, @df.merge(nil)
      assert_equal @df, @df.merge([]) # empty Array returns self
    end

    test 'not a Table or a DataFrame' do
      assert_raise(DataFrameArgumentError) { @df.merge(@df.to_h) } # Hash
      assert_raise(DataFrameArgumentError) { @df.merge(@df.to_a) } # Array
    end

    test 'concatenate single Table/DataFrame' do
      expected = <<~STR
                x       y a        b
          <uint8> <uint8> <string> <string>
        0       1       3 A        C
        1       2       4 B        D
      STR
      assert_equal expected, @df.merge(@other.table).to_s
      assert_equal expected, @df.merge(@other).to_s
    end

    test 'concatenate a Array of Tables/DataFrames' do
      array = [@other.pick(0), @other.pick(1)]
      expected = <<~STR
                x       y a        b
          <uint8> <uint8> <string> <string>
        0       1       3 A        C
        1       2       4 B        D
      STR
      assert_equal expected, @df.merge(array.map(&:table)).to_s
      assert_equal expected, @df.merge(*array).to_s
      assert_equal expected, @df.merge(array).to_s
    end

    test 'illegal dataframe shape' do
      assert_raise(DataFrameArgumentError) { @df.merge(@df) } # key mismatch
      assert_raise(DataFrameArgumentError) { @df.merge(DataFrame.new(z: [0, 0, 0])) } # shape mismatch
    end
  end

  sub_test_case '#join' do
    setup do
      @df1 = DataFrame.new(
        KEY: %w[A B C],
        X: [1, 2, 3]
      )

      @right1 = DataFrame.new(
        KEY: %w[A B D],
        Y: [3, 2, 1]
      )
    end

    test '#inner_join with a join_key' do
      expected = DataFrame.new(
        KEY: %w[A B],
        X: [1, 2],
        Y: [3, 2]
      )
      assert_equal expected, @df1.inner_join(@right1, :KEY)
      assert_equal expected, @df1.inner_join(@right1, 'KEY')
      assert_equal expected, @df1.inner_join(@right1, [:KEY])
      assert_equal expected, @df1.inner_join(@right1.table, :KEY)
    end

    test '#full_join with a join_key)' do
      expected = DataFrame.new(
        KEY: %w[A B C D],
        X: [1, 2, 3, nil],
        Y: [3, 2, nil, 1]
      )
      assert_equal expected, @df1.full_join(@right1, :KEY)
      assert_equal expected, @df1.full_join(@right1, 'KEY')
      assert_equal expected, @df1.full_join(@right1, [:KEY])
      assert_equal expected, @df1.full_join(@right1.table, :KEY)
    end

    test '#left_join with a join_key)' do
      expected = DataFrame.new(
        KEY: %w[A B C],
        X: [1, 2, 3],
        Y: [3, 2, nil]
      )
      assert_equal expected, @df1.left_join(@right1, :KEY)
      assert_equal expected, @df1.left_join(@right1, 'KEY')
      assert_equal expected, @df1.left_join(@right1, [:KEY])
      assert_equal expected, @df1.left_join(@right1.table, :KEY)
    end

    test '#right_join with a join_key)' do
      expected = DataFrame.new(
        KEY: %w[A B D],
        X: [1, 2, nil],
        Y: [3, 2, 1]
      )
      assert_equal expected, @df1.right_join(@right1, :KEY)
      assert_equal expected, @df1.right_join(@right1, 'KEY')
      assert_equal expected, @df1.right_join(@right1, [:KEY])
      assert_equal expected, @df1.right_join(@right1.table, :KEY)
    end

    test '#semi_join with a join_key' do
      expected = DataFrame.new(
        KEY: %w[A B],
        X: [1, 2]
      )
      assert_equal expected, @df1.semi_join(@right1, :KEY)
      assert_equal expected, @df1.semi_join(@right1, 'KEY')
      assert_equal expected, @df1.semi_join(@right1, [:KEY])
      assert_equal expected, @df1.semi_join(@right1.table, :KEY)
    end

    test '#anti_join with a join_key' do
      expected = DataFrame.new(
        KEY: %w[C],
        X: [3]
      )
      assert_equal expected, @df1.anti_join(@right1, :KEY)
      assert_equal expected, @df1.anti_join(@right1, 'KEY')
      assert_equal expected, @df1.anti_join(@right1, [:KEY])
      assert_equal expected, @df1.anti_join(@right1.table, :KEY)
    end

    setup do
      @df2 = DataFrame.new(
        KEY1: %w[A B C],
        KEY2: %w[s t u],
        X: [1, 2, 3]
      )

      @right2 = DataFrame.new(
        KEY1: %w[A B D],
        KEY2: %w[s u v],
        Y: [3, 2, 1]
      )
    end

    test '#inner_join with join_keys' do
      assert_raise(DataFrameArgumentError) { @df2.inner_join(@right2, :KEY1) }
      expected = DataFrame.new(
        KEY1: %w[A],
        KEY2: %w[s],
        X: [1],
        Y: [3]
      )
      assert_equal expected, @df2.inner_join(@right2, %i[KEY1 KEY2])
      assert_equal expected, @df2.inner_join(@right2, %w[KEY1 KEY2])
      assert_equal expected, @df2.inner_join(@right2.table, %i[KEY1 KEY2])
    end

    test '#full_join with join_keys' do
      assert_raise(DataFrameArgumentError) { @df2.full_join(@right2, :KEY1) }
      expected = DataFrame.new(
        KEY1: %w[A B C B D],
        KEY2: %w[s t u u v],
        X: [1, 2, 3, nil, nil],
        Y: [3, nil, nil, 2, 1]
      )
      assert_equal expected, @df2.full_join(@right2, %i[KEY1 KEY2])
      assert_equal expected, @df2.full_join(@right2, %w[KEY1 KEY2])
      assert_equal expected, @df2.full_join(@right2.table, %i[KEY1 KEY2])
    end

    test '#left_join with join_keys' do
      assert_raise(DataFrameArgumentError) { @df2.left_join(@right2, :KEY1) }
      expected = DataFrame.new(
        KEY1: %w[A B C],
        KEY2: %w[s t u],
        X: [1, 2, 3],
        Y: [3, nil, nil]
      )
      assert_equal expected, @df2.left_join(@right2, %i[KEY1 KEY2])
      assert_equal expected, @df2.left_join(@right2, %w[KEY1 KEY2])
      assert_equal expected, @df2.left_join(@right2.table, %i[KEY1 KEY2])
    end

    test '#right_join with join_keys' do
      assert_raise(DataFrameArgumentError) { @df2.right_join(@right2, :KEY1) }
      expected = DataFrame.new(
        KEY1: %w[A B D],
        KEY2: %w[s u v],
        X: [1, nil, nil],
        Y: [3, 2, 1]
      )
      assert_equal expected, @df2.right_join(@right2, %i[KEY1 KEY2])
      assert_equal expected, @df2.right_join(@right2, %w[KEY1 KEY2])
      assert_equal expected, @df2.right_join(@right2.table, %i[KEY1 KEY2])
    end

    test '#semi_join with join_keys' do
      # assert_raise(DataFrameArgumentError) { @df2.semi_join(@right2, :KEY1) }
      expected = DataFrame.new(
        KEY1: %w[A],
        KEY2: %w[s],
        X: [1]
      )
      assert_equal expected, @df2.semi_join(@right2, %i[KEY1 KEY2])
      assert_equal expected, @df2.semi_join(@right2, %w[KEY1 KEY2])
      assert_equal expected, @df2.semi_join(@right2.table, %i[KEY1 KEY2])
    end

    test '#anti_join with join_keys' do
      # assert_raise(DataFrameArgumentError) { @df2.anti_join(@right2, :KEY1) }
      expected = DataFrame.new(
        KEY1: %w[B C],
        KEY2: %w[t u],
        X: [2, 3]
      )
      assert_equal expected, @df2.anti_join(@right2, %i[KEY1 KEY2])
      assert_equal expected, @df2.anti_join(@right2, %w[KEY1 KEY2])
      assert_equal expected, @df2.anti_join(@right2.table, %i[KEY1 KEY2])
    end

    setup do
      @df3 = DataFrame.new(
        KEY1: %w[A B C],
        KEY2: %w[s t u]
      )

      @right3 = DataFrame.new(
        KEY1: %w[A B D],
        KEY2: %w[s u v]
      )
    end

    test '#intersect' do
      expected = DataFrame.new(
        KEY1: %w[A],
        KEY2: %w[s]
      )
      assert_equal expected, @df3.intersect(@right3)
      assert_equal expected, @df3.intersect(@right3.table)
    end

    test '#union' do
      expected = DataFrame.new(
        KEY1: %w[A B C B D],
        KEY2: %w[s t u u v]
      )
      assert_equal expected, @df3.union(@right3)
      assert_equal expected, @df3.union(@right3.table)
    end

    test '#setdiff' do
      expected = DataFrame.new(
        KEY1: %w[B C],
        KEY2: %w[t u]
      )
      assert_equal expected, @df3.setdiff(@right3)
      assert_equal expected, @df3.setdiff(@right3.table)
    end
  end
end
