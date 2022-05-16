# frozen_string_literal: true

require 'test_helper'

class DataFrameOutputTest < Test::Unit::TestCase
  sub_test_case 'Properties' do
    hash = { x: [1, 2, 3], y: %w[A B C] }
    data('hash data',
         [hash, RedAmber::DataFrame.new(hash), %i[uint8 string]],
         keep: true)
    data('empty data',
         [{}, RedAmber::DataFrame.new, []],
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
      df = RedAmber::DataFrame.new
      str = '#<RedAmber::DataFrame (empty)>'
      assert_equal str, df.inspect
    end

    setup do
      hash = { integer: [1, 2, 3, 4, 5, 6],
               string: %w[A A B C D E],
               boolean: [true, false, nil, true, false, nil] }
      @df = RedAmber::DataFrame.new(hash)
    end

    test 'default' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key      type   level data_preview
        1 :integer uint8      6 [1, 2, 3, 4, 5, ... ]
        2 :string  string     5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3 :boolean bool       3 {true=>2, false=>2, nil=>2}
      OUTPUT
      assert_equal str, @df.inspect
    end

    test ':all' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key      type   level data_preview
        1 :integer uint8      6 [1, 2, 3, 4, 5, ... ]
        2 :string  string     5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3 :boolean bool       3 {true=>2, false=>2, nil=>2}
      OUTPUT
      assert_equal str, @df.inspect(:all)
    end

    test 'limit = 2' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key      type   level data_preview
        1 :integer uint8      6 [1, 2, 3, 4, 5, ... ]
        2 :string  string     5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
         ... 1 more Vector ...
      OUTPUT
      assert_equal str, @df.inspect(2)
    end

    test 'tally_level' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key      type   level data_preview
        1 :integer uint8      6 [1, 2, 3, 4, 5, ... ]
        2 :string  string     5 ["A", "A", "B", "C", "D", ... ]
        3 :boolean bool       3 [true, false, nil, true, false, ... ], 2 nils
      OUTPUT
      assert_equal str, @df.inspect(tally_level: 2)
    end

    test 'max_element' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key      type   level data_preview
        1 :integer uint8      6 [1, 2, 3, 4, 5, 6]
        2 :string  string     5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3 :boolean bool       3 {true=>2, false=>2, nil=>2}
      OUTPUT
      assert_equal str, @df.inspect(max_element: 6)
    end

    test 'tally_level and max_element' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key      type   level data_preview
        1 :integer uint8      6 [1, 2, 3, 4, 5, 6]
        2 :string  string     5 ["A", "A", "B", "C", "D", "E"]
        3 :boolean bool       3 [true, false, nil, true, false, nil], 2 nils
      OUTPUT
      assert_equal str, @df.inspect(tally_level: 2, max_element: 6)
    end

    test 'empty key and key with blank' do
      df = RedAmber::DataFrame.new(
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
      assert_equal str, df.inspect
    end
  end
end
