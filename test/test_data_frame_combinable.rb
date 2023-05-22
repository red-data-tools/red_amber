# frozen_string_literal: true

require 'test_helper'

class DataFrameDisplayableTest < Test::Unit::TestCase
  include TestHelper
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
      @df3 = DataFrame.new(
        'KEY.1': %w[A B C],
        KEY: %w[s t u],
        X: [1, 2, 3]
      )
      @right3 = DataFrame.new(
        'KEY.1': %w[A B D],
        KEY: %w[s u v],
        Y: [3, 2, 1]
      )
    end

    sub_test_case 'with a join_key' do
      test 'illegal right object' do
        assert_raise(DataFrameArgumentError) { @df1.join(@right1.to_h) }
      end

      test 'natural join' do
        expected = DataFrame.new(
          KEY: %w[A B],
          X: [1, 2],
          Y: [3, 2]
        )
        assert_equal expected, @df1.join(@right1) # natural join
        assert_raise(Arrow::Error::Invalid) { @df1.join(@right1.rename(KEY: :KEY1)) }
      end

      test '#inner_join with a join_key' do
        expected = DataFrame.new(
          KEY: %w[A B],
          X: [1, 2],
          Y: [3, 2]
        )
        assert_equal expected, @df1.inner_join(@right1) # natural join
        assert_equal expected, @df1.inner_join(@right1, :KEY)
        assert_equal expected, @df1.inner_join(@right1, 'KEY')
        assert_equal expected, @df1.inner_join(@right1, [:KEY])
        assert_equal expected, @df1.inner_join(@right1.table, :KEY)
        assert_equal expected, @df1.inner_join(@right1, { left: :KEY, right: :KEY })
        assert_equal expected, @df1.inner_join(@right1.rename(KEY: :KEY1),
                                               { left: :KEY, right: :KEY1 })
      end

      test '#full_join with a join_key)' do
        expected = DataFrame.new(
          KEY: %w[A B C D],
          X: [1, 2, 3, nil],
          Y: [3, 2, nil, 1]
        )
        assert_equal expected, @df1.full_join(@right1) # natural join
        assert_equal expected, @df1.full_join(@right1, :KEY)
        assert_equal expected, @df1.full_join(@right1, 'KEY')
        assert_equal expected, @df1.full_join(@right1, [:KEY])
        assert_equal expected, @df1.full_join(@right1.table, :KEY)
        assert_equal expected, @df1.full_join(@right1, { left: :KEY, right: :KEY })
        assert_equal expected, @df1.full_join(@right1.rename(KEY: :KEY1),
                                              { left: :KEY, right: :KEY1 })
      end

      test '#left_join with a join_key)' do
        expected = DataFrame.new(
          KEY: %w[A B C],
          X: [1, 2, 3],
          Y: [3, 2, nil]
        )
        assert_equal expected, @df1.left_join(@right1) # natural join
        assert_equal expected, @df1.left_join(@right1, :KEY)
        assert_equal expected, @df1.left_join(@right1, 'KEY')
        assert_equal expected, @df1.left_join(@right1, [:KEY])
        assert_equal expected, @df1.left_join(@right1.table, :KEY)
        assert_equal expected, @df1.left_join(@right1, { left: :KEY, right: :KEY })
        assert_equal expected, @df1.left_join(@right1.rename(KEY: :KEY1),
                                              { left: :KEY, right: :KEY1 })
      end

      test '#right_join with a join_key)' do
        expected = DataFrame.new(
          X: [1, 2, nil],
          KEY: %w[A B D],
          Y: [3, 2, 1]
        )
        assert_equal expected, @df1.right_join(@right1) # natural join
        assert_equal expected, @df1.right_join(@right1, :KEY)
        assert_equal expected, @df1.right_join(@right1, 'KEY')
        assert_equal expected, @df1.right_join(@right1, [:KEY])
        assert_equal expected, @df1.right_join(@right1.table, :KEY)
        assert_equal expected, @df1.right_join(@right1, { left: :KEY, right: :KEY })
        assert_equal expected, @df1
                                 .rename(KEY: :KEY1)
                                 .right_join(@right1, { left: :KEY1, right: :KEY })
      end

      test '#semi_join with a join_key' do
        expected = DataFrame.new(
          KEY: %w[A B],
          X: [1, 2]
        )
        assert_equal expected, @df1.semi_join(@right1) # natural join
        assert_equal expected, @df1.semi_join(@right1, :KEY)
        assert_equal expected, @df1.semi_join(@right1, 'KEY')
        assert_equal expected, @df1.semi_join(@right1, [:KEY])
        assert_equal expected, @df1.semi_join(@right1.table, :KEY)
        assert_equal expected, @df1.semi_join(@right1, { left: :KEY, right: :KEY })
        assert_equal expected, @df1.semi_join(@right1.rename(KEY: :KEY1),
                                              { left: :KEY, right: :KEY1 })
      end

      test '#anti_join with a join_key' do
        expected = DataFrame.new(
          KEY: %w[C],
          X: [3]
        )
        assert_equal expected, @df1.anti_join(@right1) # natural join
        assert_equal expected, @df1.anti_join(@right1, :KEY)
        assert_equal expected, @df1.anti_join(@right1, 'KEY')
        assert_equal expected, @df1.anti_join(@right1, [:KEY])
        assert_equal expected, @df1.anti_join(@right1.table, :KEY)
        assert_equal expected, @df1.anti_join(@right1, { left: :KEY, right: :KEY })
        assert_equal expected, @df1.anti_join(@right1.rename(KEY: :KEY1),
                                              { left: :KEY, right: :KEY1 })
      end

      test 'right_semi' do
        expected = DataFrame.new(
          KEY: %w[A B],
          Y: [3, 2]
        )
        assert_equal expected, @df1.join(@right1, type: :right_semi)
        assert_equal expected, @df1.join(@right1, :KEY, type: :right_semi)
        assert_equal(
          expected,
          @df1.join(@right1, { left: :KEY, right: :KEY }, type: :right_semi)
        )
        assert_equal(
          expected,
          @df1
            .rename(KEY: :KEY1)
            .join(@right1, { left: :KEY1, right: :KEY }, type: :right_semi)
        )
      end

      test 'right_anti' do
        expected = DataFrame.new(
          KEY: %w[D],
          Y: [1]
        )
        assert_equal expected, @df1.join(@right1, type: :right_anti)
        assert_equal expected, @df1.join(@right1, :KEY, type: :right_anti)
        assert_equal(
          expected,
          @df1.join(@right1, { left: :KEY, right: :KEY }, type: :right_anti)
        )
        assert_equal(
          expected,
          @df1
            .rename(KEY: :KEY1)
            .join(@right1, { left: :KEY1, right: :KEY }, type: :right_anti)
        )
      end
    end

    sub_test_case 'with join_keys' do
      test '#inner_join with join_keys' do
        expected = DataFrame.new(
          KEY1: %w[A],
          KEY2: %w[s],
          X: [1],
          Y: [3]
        )
        assert_equal expected, @df2.inner_join(@right2) # natural join
        assert_equal expected, @df2.inner_join(@right2, %i[KEY1 KEY2])
        assert_equal expected, @df2.inner_join(@right2, %w[KEY1 KEY2])
        assert_equal expected, @df2.inner_join(@right2.table, %i[KEY1 KEY2])
        assert_equal expected, @df2.inner_join(@right2,
                                               { left: %i[KEY1 KEY2], right: %w[KEY1 KEY2] })
        assert_equal expected, @df2.inner_join(@right2.rename(KEY1: :KEY3),
                                               { left: %i[KEY1 KEY2], right: %w[KEY3 KEY2] })
      end

      test '#inner_join with join_keys, partial join_key/rename' do
        expected = DataFrame.new(
          KEY1: %w[A C],
          KEY2: %w[s u],
          X: [1, 3],
          'KEY1.1': %w[A B],
          Y: [3, 2]
        )
        assert_equal expected, @df2.inner_join(@right2, :KEY2)
        assert_equal expected, @df2.inner_join(@right2,
                                               { left: :KEY2, right: 'KEY2' })
      end

      test '#full_join with join_keys' do
        expected = DataFrame.new(
          KEY1: %w[A B C B D],
          KEY2: %w[s t u u v],
          X: [1, 2, 3, nil, nil],
          Y: [3, nil, nil, 2, 1]
        )
        assert_equal expected, @df2.full_join(@right2) # natural join
        assert_equal expected, @df2.full_join(@right2, %i[KEY1 KEY2])
        assert_equal expected, @df2.full_join(@right2, %w[KEY1 KEY2])
        assert_equal expected, @df2.full_join(@right2.table, %i[KEY1 KEY2])
        assert_equal expected, @df2.full_join(@right2,
                                              { left: %i[KEY1 KEY2], right: %w[KEY1 KEY2] })
        assert_equal expected, @df2.full_join(@right2.rename(KEY1: :KEY3),
                                              { left: %i[KEY1 KEY2], right: %w[KEY3 KEY2] })
      end

      test '#full_join with join_keys, partial join_key/rename' do
        expected = DataFrame.new(
          KEY1: ['A', 'B', 'C', nil],
          KEY2: %w[s t u v],
          X: [1, 2, 3, nil],
          'KEY1.1': ['A', nil, 'B', 'D'],
          Y: [3, nil, 2, 1]
        )
        assert_equal expected, @df2.full_join(@right2, :KEY2)
        assert_equal expected, @df2.full_join(@right2,
                                              { left: :KEY2, right: 'KEY2' })
      end

      test '#left_join with join_keys' do
        expected = DataFrame.new(
          KEY1: %w[A B C],
          KEY2: %w[s t u],
          X: [1, 2, 3],
          Y: [3, nil, nil]
        )
        assert_equal expected, @df2.left_join(@right2) # natural join
        assert_equal expected, @df2.left_join(@right2, %i[KEY1 KEY2])
        assert_equal expected, @df2.left_join(@right2, %w[KEY1 KEY2])
        assert_equal expected, @df2.left_join(@right2.table, %i[KEY1 KEY2])
        assert_equal expected, @df2.left_join(@right2,
                                              { left: %i[KEY1 KEY2], right: %w[KEY1 KEY2] })
        assert_equal expected, @df2.left_join(@right2.rename(KEY1: :KEY3),
                                              { left: %i[KEY1 KEY2], right: %w[KEY3 KEY2] })
      end

      test '#left_join with join_keys, partial join_key/rename' do
        expected = DataFrame.new(
          KEY1: %w[A B C],
          KEY2: %w[s t u],
          X: [1, 2, 3],
          'KEY1.1': ['A', nil, 'B'],
          Y: [3, nil, 2]
        )
        assert_equal expected, @df2.left_join(@right2, :KEY2)
        assert_equal expected, @df2.left_join(@right2,
                                              { left: :KEY2, right: 'KEY2' })
      end

      test '#right_join with join_keys' do
        expected = DataFrame.new(
          X: [1, nil, nil],
          KEY1: %w[A B D],
          KEY2: %w[s u v],
          Y: [3, 2, 1]
        )
        assert_equal expected, @df2.right_join(@right2) # natural join
        assert_equal expected, @df2.right_join(@right2, %i[KEY1 KEY2])
        assert_equal expected, @df2.right_join(@right2, %w[KEY1 KEY2])
        assert_equal expected, @df2.right_join(@right2.table, %i[KEY1 KEY2])
        assert_equal expected, @df2.right_join(@right2,
                                               { left: %i[KEY1 KEY2], right: %w[KEY1 KEY2] })
        assert_equal(
          expected,
          @df2
            .rename(KEY1: :KEY3)
            .right_join(@right2, { left: %i[KEY3 KEY2], right: %w[KEY1 KEY2] })
        )
      end

      test '#right_join with join_keys, partial join_key/rename' do
        expected = DataFrame.new(
          KEY1: ['A', 'C', nil],
          X: [1, 3, nil],
          'KEY1.1': %w[A B D],
          KEY2: %w[s u v],
          Y: [3, 2, 1]
        )
        assert_equal expected, @df2.right_join(@right2, :KEY2)
        assert_equal expected,
                     @df2.right_join(@right2, { left: :KEY2, right: 'KEY2' })
      end

      test '#semi_join with join_keys' do
        expected = DataFrame.new(
          KEY1: %w[A],
          KEY2: %w[s],
          X: [1]
        )
        assert_equal expected, @df2.semi_join(@right2) # natural join
        assert_equal expected, @df2.semi_join(@right2, %i[KEY1 KEY2])
        assert_equal expected, @df2.semi_join(@right2, %w[KEY1 KEY2])
        assert_equal expected, @df2.semi_join(@right2.table, %i[KEY1 KEY2])
        assert_equal expected, @df2.semi_join(@right2,
                                              { left: %i[KEY1 KEY2], right: %w[KEY1 KEY2] })
        assert_equal expected, @df2.semi_join(@right2.rename(KEY1: :KEY3),
                                              { left: %i[KEY1 KEY2], right: %w[KEY3 KEY2] })
      end

      test '#semi_join with join_keys, partial join_key' do
        expected = DataFrame.new(
          KEY1: %w[A C],
          KEY2: %w[s u],
          X: [1, 3]
        )
        assert_equal expected, @df2.semi_join(@right2, :KEY2)
        assert_equal expected, @df2.semi_join(@right2,
                                              { left: :KEY2, right: 'KEY2' })
      end

      test '#anti_join with join_keys' do
        expected = DataFrame.new(
          KEY1: %w[B C],
          KEY2: %w[t u],
          X: [2, 3]
        )
        assert_equal expected, @df2.anti_join(@right2) # natural join
        assert_equal expected, @df2.anti_join(@right2, %i[KEY1 KEY2])
        assert_equal expected, @df2.anti_join(@right2, %w[KEY1 KEY2])
        assert_equal expected, @df2.anti_join(@right2.table, %i[KEY1 KEY2])
        assert_equal expected, @df2.anti_join(@right2,
                                              { left: %i[KEY1 KEY2], right: %w[KEY1 KEY2] })
        assert_equal expected, @df2.anti_join(@right2.rename(KEY1: :KEY3),
                                              { left: %i[KEY1 KEY2], right: %w[KEY3 KEY2] })
      end

      test '#anti_join with join_keys, partial join_key' do
        expected = DataFrame.new(
          KEY1: %w[B],
          KEY2: %w[t],
          X: [2]
        )
        assert_equal expected, @df2.anti_join(@right2, :KEY2)
        assert_equal expected, @df2.anti_join(@right2,
                                              { left: :KEY2, right: 'KEY2' })
      end
    end

    sub_test_case 'renaming duplicate keys by suffix' do
      test '#inner_join with rename and collision by default' do
        expected = DataFrame.new(
          'KEY.1': %w[A B],
          KEY: %w[s t],
          X: [1, 2],
          'KEY.2': %w[s u],
          Y: [3, 2]
        )
        assert_equal expected, @df3.inner_join(@right3, :'KEY.1')
        assert_equal expected, @df3.inner_join(@right3,
                                               { left: :'KEY.1', right: 'KEY.1' })
      end

      test '#full_join with rename and collision by default' do
        expected = DataFrame.new(
          'KEY.1': %w[A B C D],
          KEY: ['s', 't', 'u', nil],
          X: [1, 2, 3, nil],
          'KEY.2': ['s', 'u', nil, 'v'],
          Y: [3, 2, nil, 1]
        )
        assert_equal expected, @df3.full_join(@right3, :'KEY.1')
        assert_equal expected, @df3.full_join(@right3,
                                              { left: :'KEY.1', right: 'KEY.1' })
      end

      test '#left_join with rename and collision by default' do
        expected = DataFrame.new(
          'KEY.1': %w[A B C],
          KEY: %w[s t u],
          X: [1, 2, 3],
          'KEY.2': ['s', 'u', nil],
          Y: [3, 2, nil]
        )
        assert_equal expected, @df3.left_join(@right3, :'KEY.1')
        assert_equal expected, @df3.left_join(@right3,
                                              { left: :'KEY.1', right: 'KEY.1' })
      end

      test '#right_join with rename and collision by default' do
        expected = DataFrame.new(
          KEY: ['s', 't', nil],
          X: [1, 2, nil],
          'KEY.1': %w[A B D],
          'KEY.2': %w[s u v],
          Y: [3, 2, 1]
        )
        assert_equal expected, @df3.right_join(@right3, :'KEY.1')
        assert_equal expected, @df3.right_join(@right3,
                                               { left: :'KEY.1', right: 'KEY.1' })
      end

      test '#inner_join with empty suffix' do
        expected = DataFrame.new(
          'KEY.1': %w[A B],
          KEY: %w[s t],
          X: [1, 2],
          KEZ: %w[s u],
          Y: [3, 2]
        )
        assert_equal expected, @df3.inner_join(@right3, :'KEY.1', suffix: '')
      end
    end

    sub_test_case 'sort by :force_order' do
      test '#full_join w/ sort' do
        sort = @df2.full_join(@right2, :KEY2, force_order: true)
        no_sort = @df2.full_join(@right2, :KEY2, force_order: false)
        assert_equal_dataframe_non_order(sort, no_sort)
      end

      test '#left_join w/ sort' do
        sort = @df2.left_join(@right2, :KEY2, force_order: true)
        no_sort = @df2.left_join(@right2, :KEY2, force_order: false)
        assert_equal_dataframe_non_order(sort, no_sort)
      end

      test '#right_join w/ sort' do
        sort = @df2.right_join(@right2, :KEY2, force_order: true)
        no_sort = @df2.right_join(@right2, :KEY2, force_order: false)
        assert_equal_dataframe_non_order(sort, no_sort)
      end

      test '#left_semi w/ sort' do
        sort = @df2.join(@right2, :KEY2, type: :left_semi, force_order: true)
        no_sort = @df2.join(@right2, :KEY2, type: :left_semi, force_order: false)
        assert_equal_dataframe_non_order(sort, no_sort)
      end

      test '#left_anti w/ sort' do
        sort = @df2.join(@right2, :KEY2, type: :left_anti, force_order: true)
        no_sort = @df2.join(@right2, :KEY2, type: :left_anti, force_order: false)
        assert_equal_dataframe_non_order(sort, no_sort)
      end

      test '#right_semi w/ sort' do
        sort = @df2.join(@right2, :KEY2, type: :right_semi, force_order: true)
        no_sort = @df2.join(@right2, :KEY2, type: :right_semi, force_order: false)
        assert_equal_dataframe_non_order(sort, no_sort)
      end

      test '#right_anti w/ sort' do
        sort = @df2.join(@right2, :KEY2, type: :right_anti, force_order: true)
        no_sort = @df2.join(@right2, :KEY2, type: :right_anti, force_order: false)
        assert_equal_dataframe_non_order(sort, no_sort)
      end
    end

    sub_test_case 'set operations' do
      setup do
        @df4 = DataFrame.new(
          KEY1: %w[A B C],
          KEY2: %w[s t u]
        )

        @right4 = DataFrame.new(
          KEY1: %w[A B D],
          KEY2: %w[s u v]
        )

        @foreign = @right4.rename(KEY2: :KEY3)
      end

      test '#set_operable?' do
        assert_true @df4.set_operable?(@right4)
      end

      test '#intersect' do
        expected = DataFrame.new(
          KEY1: %w[A],
          KEY2: %w[s]
        )
        assert_equal expected, @df4.intersect(@right4)
        assert_equal expected, @df4.intersect(@right4.table)
        assert_raise(DataFrameArgumentError) { @df4.intersect(@foreign) }
      end

      test '#union' do
        expected = DataFrame.new(
          KEY1: %w[A B C B D],
          KEY2: %w[s t u u v]
        )
        assert_equal expected, @df4.union(@right4)
        assert_equal expected, @df4.union(@right4.table)
        assert_raise(DataFrameArgumentError) { @df4.union(@foreign) }
      end

      test '#difference' do
        expected = DataFrame.new(
          KEY1: %w[B C],
          KEY2: %w[t u]
        )
        assert_equal expected, @df4.difference(@right4)
        assert_equal expected, @df4.difference(@right4.table)
        assert_raise(DataFrameArgumentError) { @df4.difference(@foreign) }
      end
    end
  end
end
