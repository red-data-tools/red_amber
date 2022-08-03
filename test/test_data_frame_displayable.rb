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

  sub_test_case 'inspect by tdr mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'TDR'
    end

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

  sub_test_case 'inspect by table mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'Table'
    end

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
          integer    double string   boolean
          <uint8>  <double> <string> <boolean>
        1       1       1.0 A        true
        2       2       NaN A        false
        3       3  Infinity B        (nil)
        4       4 -Infinity C        true
        5       5     (nil) D        false
        6       6       0.0 E        (nil)
      OUTPUT
      assert_equal str, @df.inspect
    end

    setup do
      @df2 = DataFrame.load('test/entity/test_penguins.csv')
    end

    test 'ellipsis in row and column' do
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 10 x 7 Vectors, #{format('0x%016x', @df2.object_id)}>
           ID       Date Egg   Culmen_Length_mm Culmen_Depth_mm Flipper_Length_mm ... Sex
           <string> <date32>           <double>        <double>           <int64> ... <string>
         1 N1A1     2007-11-11             39.1            18.7               181 ... MALE
         2 N1A2     2007-11-11             39.5            17.4               186 ... FEMALE
         3 N2A1     2007-11-16             40.3            18.0               195 ... FEMALE
         4 N2A2     2007-11-16            (nil)           (nil)             (nil) ...
         5 N3A1     2007-11-16             36.7            19.3               193 ... FEMALE
         : :        :                         :               :                 : ... :
         8 N4A2     2007-11-15             39.2            19.6               195 ... MALE
         9 N5A1     2007-11-09             34.1            18.1               193 ...
        10 N5A2     2007-11-09             42.0            20.2               190 ...
      OUTPUT
      assert_equal str, @df2.inspect
    end

    test 'ellipsis in row' do
      df = @df2.drop(:'Date Egg')
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 10 x 6 Vectors, #{format('0x%016x', df.object_id)}>
           ID       Culmen_Length_mm Culmen_Depth_mm Flipper_Length_mm Body_Mass_g Sex
           <string>         <double>        <double>           <int64>     <int64> <string>
         1 N1A1                 39.1            18.7               181        3750 MALE
         2 N1A2                 39.5            17.4               186        3800 FEMALE
         3 N2A1                 40.3            18.0               195        3250 FEMALE
         4 N2A2                (nil)           (nil)             (nil)       (nil)
         5 N3A1                 36.7            19.3               193        3450 FEMALE
         : :                       :               :                 :           : :
         8 N4A2                 39.2            19.6               195        4675 MALE
         9 N5A1                 34.1            18.1               193        3475
        10 N5A2                 42.0            20.2               190        4250
      OUTPUT
      assert_equal str, df.inspect
    end

    test 'ellipsis in column' do
      df = @df2.slice(0..5)
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 6 x 7 Vectors, #{format('0x%016x', df.object_id)}>
          ID       Date Egg   Culmen_Length_mm Culmen_Depth_mm Flipper_Length_mm ... Sex
          <string> <date32>           <double>        <double>           <int64> ... <string>
        1 N1A1     2007-11-11             39.1            18.7               181 ... MALE
        2 N1A2     2007-11-11             39.5            17.4               186 ... FEMALE
        3 N2A1     2007-11-16             40.3            18.0               195 ... FEMALE
        4 N2A2     2007-11-16            (nil)           (nil)             (nil) ...
        5 N3A1     2007-11-16             36.7            19.3               193 ... FEMALE
        6 N3A2     2007-11-16             39.3            20.6               190 ... MALE
      OUTPUT
      assert_equal str, df.inspect
    end

    test 'empty key name' do
      df = DataFrame.new("": [1, 2, 3], x: %w[A B C])
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 3 x 2 Vectors, #{format('0x%016x', df.object_id)}>
          unnamed1 x
           <uint8> <string>
        1        1 A
        2        2 B
        3        3 C
      OUTPUT
      assert_equal str, df.inspect
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
        # key       type  level data_preview
        1 :unnamed1 uint8     2 [1, 2]
        2 :"  "     uint8     2 [3, 4]
        3 :"a b"    uint8     2 [5, 6]
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
