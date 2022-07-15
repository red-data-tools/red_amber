# frozen_string_literal: true

require 'test_helper'

class GroupTest < Test::Unit::TestCase
  include RedAmber
  sub_test_case 'group' do
    test 'Empty dataframe' do
      df = DataFrame.new
      assert_raise(GroupArgumentError) { df.group(:x).count }
    end

    setup do
      @df = DataFrame.new(
        {
          i: [0, 0, 1, 2, 2, nil],
          f: [0.0, 1.1, 2.2, 3.3, Float::NAN, nil],
          s: ['A', 'B', nil, 'A', 'B', 'A'],
          b: [true, false, true, false, true, nil],
        }
      )
    end

    test 'group count' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 4 x 5 Vectors
        Vectors : 5 numeric
        # key         type  level data_preview
        1 :"count(i)" int64     3 [2, 1, 2, 0]
        2 :"count(f)" int64     3 [2, 1, 2, 0]
        3 :"count(s)" int64     3 [2, 0, 2, 1]
        4 :"count(b)" int64     3 [2, 1, 2, 0]
        5 :i          uint8     4 [0, 1, 2, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:i).count(%i[i f s b]).tdr_str(tally: 0)
    end

    test 'group max' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 5 Vectors
        Vectors : 2 numeric, 1 string, 2 boolean
        # key       type    level data_preview
        1 :"max(i)" uint8       2 [2, 2, nil], 1 nil
        2 :"max(f)" double      3 [2.2, 3.3, nil], 1 nil
        3 :"max(s)" string      2 ["B", "B", "A"]
        4 :"max(b)" boolean     3 [true, false, nil], 1 nil
        5 :b        boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:b).max(%i[i f s b]).tdr_str(tally: 0)
    end

    test 'group mean' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 3 numeric, 1 boolean
        # key        type    level data_preview
        1 :"mean(i)" double      2 [1.0, 1.0, nil], 1 nil
        2 :"mean(f)" double      3 [NaN, 2.2, nil], 1 NaN, 1 nil
        3 :"mean(b)" double      3 [1.0, 0.0, nil], 1 nil
        4 :b         boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:b).mean(%i[i f b]).tdr_str(tally: 0)
    end

    test 'group min' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 5 Vectors
        Vectors : 2 numeric, 1 string, 2 boolean
        # key       type    level data_preview
        1 :"min(i)" uint8       2 [0, 0, nil], 1 nil
        2 :"min(f)" double      3 [0.0, 1.1, nil], 1 nil
        3 :"min(s)" string      1 ["A", "A", "A"]
        4 :"min(b)" boolean     3 [true, false, nil], 1 nil
        5 :b        boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:b).min(%i[i f s b]).tdr_str(tally: 0)
    end

    test 'group product' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 3 numeric, 1 boolean
        # key           type    level data_preview
        1 :"product(i)" uint64      2 [0, 0, nil], 1 nil
        2 :"product(f)" double      3 [NaN, 3.63, nil], 1 NaN, 1 nil
        3 :"product(b)" uint64      3 [1, 0, nil], 1 nil
        4 :b            boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:b).product(%i[i f b]).tdr_str(tally: 0)
    end

    test 'group stddev' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 2 numeric, 1 boolean
        # key          type    level data_preview
        1 :"stddev(i)" double      3 [0.816496580927726, 1.0, nil], 1 nil
        2 :"stddev(f)" double      3 [NaN, 1.0999999999999999, nil], 1 NaN, 1 nil
        3 :b           boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:b).stddev(%i[i f]).tdr_str(tally: 0)
    end

    test 'group sum' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 4 Vectors
        Vectors : 3 numeric, 1 boolean
        # key       type    level data_preview
        1 :"sum(i)" uint64      3 [3, 2, nil], 1 nil
        2 :"sum(f)" double      3 [NaN, 4.4, nil], 1 NaN, 1 nil
        3 :"sum(b)" uint64      3 [3, 0, nil], 1 nil
        4 :b        boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:b).sum(%i[i f b]).tdr_str(tally: 0)
    end

    test 'group variance' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 2 numeric, 1 boolean
        # key            type    level data_preview
        1 :"variance(i)" double      3 [0.6666666666666666, 1.0, nil], 1 nil
        2 :"variance(f)" double      3 [NaN, 1.2099999999999997, nil], 1 NaN, 1 nil
        3 :b             boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal str, @df.group(:b).variance(%i[i f]).tdr_str(tally: 0)
    end
  end
end
