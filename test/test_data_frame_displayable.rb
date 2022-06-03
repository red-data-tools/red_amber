# frozen_string_literal: true

require 'test_helper'

class DataFrameDisplayableTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case 'Properties' do
    hash = { x: [1, 2, 3], y: %w[A B C] }
    data('hash data',
         [hash, DataFrame.new(hash), %i[uint8 string]],
         keep: true)
    data('empty data',
         [{}, DataFrame.new, []],
         keep: true)

    test 'to_h' do
      hash, df, = data
      hash_sym = hash.each_with_object({}) do |kv, h|
        k, v = kv
        h[k.to_sym] = v
      end
      assert_equal hash_sym, df.to_h
    end
  end

  sub_test_case 'inspect' do
    test 'empty dataframe' do
      df = DataFrame.new
      str = "#<RedAmber::DataFrame : (empty), #{format('0x%016x', df.object_id)}>\n"
      assert_equal str, df.inspect
    end

    setup do
      hash = { integer: [1, 2, 3, 4, 5, 6],
               double: [1, 0 / 0.0, 1 / 0.0, -1 / 0.0, nil, ''],
               string: %w[A A B C D E],
               boolean: [true, false, nil, true, false, nil] }
      @df = DataFrame.new(hash)
    end

    test 'default' do
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 6 x 4 Vectors, #{format('0x%016x', @df.object_id)}>
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        2 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        3 :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
         ... 1 more Vector ...
      OUTPUT
      assert_equal str, @df.inspect
    end
  end

  sub_test_case 'tdr_str' do
    setup do
      hash = { integer: [1, 2, 3, 4, 5, 6],
               double: [1, 0 / 0.0, 1 / 0.0, -1 / 0.0, nil, ''],
               string: %w[A A B C D E],
               boolean: [true, false, nil, true, false, nil] }
      @df = DataFrame.new(hash)
    end

    test ':all' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        2 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        3 :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        4 :boolean boolean     3 {true=>2, false=>2, nil=>2}
      OUTPUT
      assert_equal str, @df.tdr_str(:all)
    end

    test 'limit = 2' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        2 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
         ... 2 more Vectors ...
      OUTPUT
      assert_equal str, @df.tdr_str(2)
    end

    test 'tally_level' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        2 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        3 :string  string      5 ["A", "A", "B", "C", "D", ... ]
        4 :boolean boolean     3 [true, false, nil, true, false, ... ], 2 nils
      OUTPUT
      assert_equal str, @df.tdr_str(tally: 2)
    end

    test 'max_element' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       6 [1, 2, 3, 4, 5, 6]
        2 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, 0.0], 1 NaN, 1 nil
        3 :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        4 :boolean boolean     3 {true=>2, false=>2, nil=>2}
      OUTPUT
      assert_equal str, @df.tdr_str(elements: 6)
    end

    test 'tally_level and max_element' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        1 :integer uint8       6 [1, 2, 3, 4, 5, 6]
        2 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, 0.0], 1 NaN, 1 nil
        3 :string  string      5 ["A", "A", "B", "C", "D", "E"]
        4 :boolean boolean     3 [true, false, nil, true, false, nil], 2 nils
      OUTPUT
      assert_equal str, @df.tdr_str(tally: 2, elements: 6)
    end

    test 'empty key and key with blank' do
      df = DataFrame.new(
        {
          '': [1, 2],
          '  ': [3, 4],
          'a b': [5, 6],
        }
      )
      str = <<~OUTPUT
        RedAmber::DataFrame : 2 x 3 Vectors
        Vectors : 3 numeric
        # key    type  level data_preview
        1 :""    uint8     2 [1, 2]
        2 :"  "  uint8     2 [3, 4]
        3 :"a b" uint8     2 [5, 6]
      OUTPUT
      assert_equal str, df.tdr_str
    end

    test 'type timestamp in tdr' do
      df = DataFrame.load('test/entity/timestamp.csv')
      assert_equal <<~STR, df.tdr_str
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 2 numeric, 1 temporal
        # key       type      level data_preview
        1 :index    int64         3 [1, 2, 3]
        2 :value    double        3 [0.6745854900288456, 0.13221317634640772, 0.21327735697163186]
        3 :datetime timestamp     3 [2022-06-03 19:11:16 +0900, 2022-06-03 19:15:35 +0900, ... ]
      STR
    end
  end
end
