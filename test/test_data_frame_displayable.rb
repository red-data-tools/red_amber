# frozen_string_literal: true

require 'test_helper'

class DataFrameDisplayableTest < Test::Unit::TestCase
  include TestHelper
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

  sub_test_case '#to_s' do
    setup do
      hash = { integer: [1, 2, 3, 4, 5, 6],
               double: [1, 0 / 0.0, 1 / 0.0, -1 / 0.0, nil, ''],
               string: %w[A A B C D E],
               boolean: [true, false, nil, true, false, nil] }
      @df = DataFrame.new(hash)
    end

    test '#to_s default' do
      str = <<~OUTPUT
          integer    double string   boolean
          <uint8>  <double> <string> <boolean>
        0       1       1.0 A        true
        1       2       NaN A        false
        2       3  Infinity B        (nil)
        3       4 -Infinity C        true
        4       5     (nil) D        false
        5       6       0.0 E        (nil)
      OUTPUT
      assert_equal str, @df.to_s
    end

    test '#to_s specify head and tail' do
      str = <<~OUTPUT
          integer   double string   boolean
          <uint8> <double> <string> <boolean>
        0       1      1.0 A        true
        1       2      NaN A        false
        :       :        : :        :
        4       5    (nil) D        false
        5       6      0.0 E        (nil)
      OUTPUT
      assert_equal str, @df.to_s(head: 2, tail: 2)
    end

    setup do
      @df2 = DataFrame.load('test/entity/test_penguins.csv')
    end

    test '#to_s ellipsis in row and column' do
      str =
        "   ID       Date Egg   Culmen_Length_mm Culmen_Depth_mm Flipper_Length_mm Body_Mass_g Sex\n   " \
        "<string> <date32>           <double>        <double>           <int64>     <int64> <string>\n " \
        "0 N1A1     2007-11-11             39.1            18.7               181        3750 MALE\n " \
        "1 N1A2     2007-11-11             39.5            17.4               186        3800 FEMALE\n " \
        "2 N2A1     2007-11-16             40.3            18.0               195        3250 FEMALE\n " \
        "3 N2A2     2007-11-16            (nil)           (nil)             (nil)       (nil)\n " \
        "4 N3A1     2007-11-16             36.7            19.3               193        3450 FEMALE\n " \
        ": :        :                         :               :                 :           : :\n " \
        "7 N4A2     2007-11-15             39.2            19.6               195        4675 MALE\n " \
        "8 N5A1     2007-11-09             34.1            18.1               193        3475\n " \
        "9 N5A2     2007-11-09             42.0            20.2               190        4250\n" \
        "10 N6A1     2007-11-09             37.8            17.1               186        3300\n"
      assert_equal str, @df2.to_s
    end

    test '#to_s ellipsis in row' do
      df = @df2.drop(:'Date Egg')
      str =
        "   ID       Culmen_Length_mm Culmen_Depth_mm Flipper_Length_mm Body_Mass_g Sex\n   " \
        "<string>         <double>        <double>           <int64>     <int64> <string>\n " \
        "0 N1A1                 39.1            18.7               181        3750 MALE\n " \
        "1 N1A2                 39.5            17.4               186        3800 FEMALE\n " \
        "2 N2A1                 40.3            18.0               195        3250 FEMALE\n " \
        "3 N2A2                (nil)           (nil)             (nil)       (nil)\n " \
        "4 N3A1                 36.7            19.3               193        3450 FEMALE\n " \
        ": :                       :               :                 :           : :\n " \
        "7 N4A2                 39.2            19.6               195        4675 MALE\n " \
        "8 N5A1                 34.1            18.1               193        3475\n " \
        "9 N5A2                 42.0            20.2               190        4250\n" \
        "10 N6A1                 37.8            17.1               186        3300\n"
      assert_equal str, df.to_s
    end

    test '#to_s ellipsis in column' do
      df = @df2.assign_left(:index) { indices(1) }.slice(0..5)
      str = <<~OUTPUT
            index ID       Date Egg   Culmen_Length_mm Culmen_Depth_mm Flipper_Length_mm ... Sex
          <uint8> <string> <date32>           <double>        <double>           <int64> ... <string>
        0       1 N1A1     2007-11-11             39.1            18.7               181 ... MALE
        1       2 N1A2     2007-11-11             39.5            17.4               186 ... FEMALE
        2       3 N2A1     2007-11-16             40.3            18.0               195 ... FEMALE
        3       4 N2A2     2007-11-16            (nil)           (nil)             (nil) ...
        4       5 N3A1     2007-11-16             36.7            19.3               193 ... FEMALE
        5       6 N3A2     2007-11-16             39.3            20.6               190 ... MALE
      OUTPUT
      assert_equal str, df.to_s
    end

    test '#to_s non-ascii elements' do
      df = DataFrame.load(Arrow::Buffer.new(<<~CSV), format: :csv)
        postal_code,prefecture,city,address
        9800856,宮城県,仙台市青葉区,青葉山
        1040061,東京都,中央区,銀座
        1340091,東京都,江戸川区,船堀
        3900815,長野県,松本市,深志
        5140061,三重県,津市,一身田上津部田
        6060001,京都府,京都市左京区,岩倉大鷺町
        7300811,広島県,広島市中区,中島町
        8120032,福岡県,福岡市博多区,石城町
      CSV
      expected = <<~OUTPUT
          postal_code prefecture city         address
              <int64> <string>   <string>     <string>
        0     9800856 宮城県     仙台市青葉区 青葉山
        1     1040061 東京都     中央区       銀座
        2     1340091 東京都     江戸川区     船堀
        3     3900815 長野県     松本市       深志
        4     5140061 三重県     津市         一身田上津部田
        5     6060001 京都府     京都市左京区 岩倉大鷺町
        6     7300811 広島県     広島市中区   中島町
        7     8120032 福岡県     福岡市博多区 石城町
      OUTPUT
      assert_equal expected, df.to_s
    end
  end

  sub_test_case 'inspect by table mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = nil # Table mode
    end

    test 'empty dataframe' do
      df = DataFrame.new
      str = "#<RedAmber::DataFrame : (empty), #{format('0x%016x', df.object_id)}>\n"
      assert_equal str, df.inspect
    end

    test 'zero size dataframe' do
      df = DataFrame.new(x: [])
      str = <<~STR
        #<RedAmber::DataFrame : 0 x 1 Vector, #{format('0x%016x', df.object_id)}>
          x
          (Empty Vectors)
      STR
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
        0       1       1.0 A        true
        1       2       NaN A        false
        2       3  Infinity B        (nil)
        3       4 -Infinity C        true
        4       5     (nil) D        false
        5       6       0.0 E        (nil)
      OUTPUT
      assert_equal str, @df.inspect
    end

    test 'empty key name' do
      df = DataFrame.new("": [1, 2, 3], x: %w[A B C])
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 3 x 2 Vectors, #{format('0x%016x', df.object_id)}>
          unnamed1 x
           <uint8> <string>
        0        1 A
        1        2 B
        2        3 C
      OUTPUT
      assert_equal str, df.inspect
    end
  end

  sub_test_case 'inspect by plain mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'PLAIN'
    end

    test 'long dataframe' do
      df = RedAmber::DataFrame.new(x: [*1..10])
      str = <<~STR
        #<RedAmber::DataFrame : 10 x 1 Vector>
                x
          <uint8>
        0       1
        1       2
        2       3
        3       4
        4       5
        5       6
        6       7
        7       8
        8       9
        9      10
      STR
      assert_equal str, df.inspect
    end

    test 'wide dataframe' do
      raw_record = (1..16).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = RedAmber::DataFrame.new(raw_record)
      str = <<~STR
        #<RedAmber::DataFrame : 1 x 16 Vectors>
                A       B       C       D       E       F       G       H       I       J       K       L       M       N       O       P
          <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8>
        0       1       2       3       4       5       6       7       8       9      10      11      12      13      14      15      16
      STR
      assert_equal str, df.inspect
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

    test 'zero size dataframe' do
      df = DataFrame.new(x: [])
      str = <<~STR
        #<RedAmber::DataFrame : 0 x 1 Vector, #{format('0x%016x', df.object_id)}>
        Vector : 1 string
        # key type   level data_preview
        0 :x  string     0 []
      STR
      assert_equal str, df.inspect
    end

    setup do
      zeros = [0] * 6
      hash =
        {
          integer: [1, 2, 3, 4, 5, 6],
          double: [1, 0 / 0.0, 1 / 0.0, -1 / 0.0, nil, ''],
          string: %w[A A B C D E],
          boolean: [true, false, nil, true, false, nil],
        }
          .merge((:a..:g).each_with_object({}) { |k, h| h[k] = zeros })
      @df = DataFrame.new(hash)
    end

    test 'default' do
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 6 x 11 Vectors, #{format('0x%016x', @df.object_id)}>
        Vectors : 9 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        0 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        1 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        2 :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3 :boolean boolean     3 {true=>2, false=>2, nil=>2}
        4 :a       uint8       1 {0=>6}
        5 :b       uint8       1 {0=>6}
        6 :c       uint8       1 {0=>6}
        7 :d       uint8       1 {0=>6}
        8 :e       uint8       1 {0=>6}
        9 :f       uint8       1 {0=>6}
         ... 1 more Vector ...
      OUTPUT
      assert_equal str, @df.inspect
    end
  end

  sub_test_case 'inspect by tdra mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'TDRA'
    end

    test 'empty dataframe' do
      df = DataFrame.new
      str = "#<RedAmber::DataFrame : (empty), #{format('0x%016x', df.object_id)}>\n"
      assert_equal str, df.inspect
    end

    test 'zero size dataframe' do
      df = DataFrame.new(x: [])
      str = <<~STR
        #<RedAmber::DataFrame : 0 x 1 Vector, #{format('0x%016x', df.object_id)}>
        Vector : 1 string
        # key type   level data_preview
        0 :x  string     0 []
      STR
      assert_equal str, df.inspect
    end

    setup do
      zeros = [0] * 6
      hash =
        {
          integer: [1, 2, 3, 4, 5, 6],
          double: [1, 0 / 0.0, 1 / 0.0, -1 / 0.0, nil, ''],
          string: %w[A A B C D E],
          boolean: [true, false, nil, true, false, nil],
        }
          .merge((:a..:g).each_with_object({}) { |k, h| h[k] = zeros })
      @df = DataFrame.new(hash)
    end

    test 'default' do
      str = <<~OUTPUT
        #<RedAmber::DataFrame : 6 x 11 Vectors, #{format('0x%016x', @df.object_id)}>
        Vectors : 9 numeric, 1 string, 1 boolean
        #  key      type    level data_preview
        0  :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        1  :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        2  :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3  :boolean boolean     3 {true=>2, false=>2, nil=>2}
        4  :a       uint8       1 {0=>6}
        5  :b       uint8       1 {0=>6}
        6  :c       uint8       1 {0=>6}
        7  :d       uint8       1 {0=>6}
        8  :e       uint8       1 {0=>6}
        9  :f       uint8       1 {0=>6}
        10 :g       uint8       1 {0=>6}
      OUTPUT
      assert_equal str, @df.inspect
    end
  end

  sub_test_case 'inspect by minimum mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'Minimum'
    end

    test 'empty dataframe' do
      df = DataFrame.new
      assert_equal 'RedAmber::DataFrame : (empty)', df.inspect
    end

    test 'zero size dataframe' do
      df = DataFrame.new(x: [])
      assert_equal 'RedAmber::DataFrame : 0 x 1 Vector', df.inspect
    end

    setup do
      @df = DataFrame.new(
        integer: [1, 2, 3, 4, 5, 6],
        double: [1, 0 / 0.0, 1 / 0.0, -1 / 0.0, nil, ''],
        string: %w[A A B C D E],
        boolean: [true, false, nil, true, false, nil]
      )
    end

    test 'default' do
      assert_equal 'RedAmber::DataFrame : 6 x 4 Vectors', @df.inspect
    end
  end

  sub_test_case 'tdr' do
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
        0 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        1 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        2 :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3 :boolean boolean     3 {true=>2, false=>2, nil=>2}
      OUTPUT
      assert_equal str, @df.tdr_str(:all)
    end

    test 'limit = 2' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        0 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        1 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
         ... 2 more Vectors ...
      OUTPUT
      assert_equal str, @df.tdr_str(2)
    end

    test 'tally_level' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        0 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        1 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        2 :string  string      5 ["A", "A", "B", "C", "D", ... ]
        3 :boolean boolean     3 [true, false, nil, true, false, ... ], 2 nils
      OUTPUT
      assert_equal str, @df.tdr_str(tally: 2)
    end

    test 'max_element' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        0 :integer uint8       6 [1, 2, 3, 4, 5, 6]
        1 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, 0.0], 1 NaN, 1 nil
        2 :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3 :boolean boolean     3 {true=>2, false=>2, nil=>2}
      OUTPUT
      assert_equal str, @df.tdr_str(elements: 6)
    end

    test 'tally_level and max_element' do
      str = <<~OUTPUT
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        0 :integer uint8       6 [1, 2, 3, 4, 5, 6]
        1 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, 0.0], 1 NaN, 1 nil
        2 :string  string      5 ["A", "A", "B", "C", "D", "E"]
        3 :boolean boolean     3 [true, false, nil, true, false, nil], 2 nils
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
        0 :unnamed1 uint8     2 [1, 2]
        1 :"  "     uint8     2 [3, 4]
        2 :"a b"    uint8     2 [5, 6]
      OUTPUT
      assert_equal str, df.tdr_str
    end

    test 'type timestamp in tdr' do
      # Temporarily change time zone to assert timestamp
      tz_org = ENV.fetch('TZ', nil)
      ENV.store('TZ', 'Asia/Tokyo')
      df = DataFrame.load('test/entity/timestamp.csv')
      assert_equal <<~STR, df.tdr_str
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 2 numeric, 1 temporal
        # key       type      level data_preview
        0 :index    int64         3 [1, 2, 3]
        1 :value    double        3 [0.6745854900288456, 0.13221317634640772, 0.21327735697163186]
        2 :datetime timestamp     3 ["2022-06-03 19:11:16 +0900", "2022-06-03 19:15:35 +0900", "2022-06-03 19:18:43 +0900"]
      STR
      ENV.store('TZ', tz_org)
    end

    test '#tdr' do
      $stdout = StringIO.new
      assert_nil @df.tdr
      assert_equal <<~STR, $stdout.string
        RedAmber::DataFrame : 6 x 4 Vectors
        Vectors : 2 numeric, 1 string, 1 boolean
        # key      type    level data_preview
        0 :integer uint8       6 [1, 2, 3, 4, 5, ... ]
        1 :double  double      6 [1.0, NaN, Infinity, -Infinity, nil, ... ], 1 NaN, 1 nil
        2 :string  string      5 {"A"=>2, "B"=>1, "C"=>1, "D"=>1, "E"=>1}
        3 :boolean boolean     3 {true=>2, false=>2, nil=>2}
      STR
    ensure
      $stdout = STDOUT
    end

    test '#tdra' do
      df = DataFrame.new(
        (1..11).map { [(_1 + 96).chr, [_1 - 1, _1]] }
      )
      $stdout = StringIO.new
      assert_nil df.tdra
      assert_equal <<~STR, $stdout.string
        RedAmber::DataFrame : 2 x 11 Vectors
        Vectors : 11 numeric
        #  key type  level data_preview
        0  :a  uint8     2 [0, 1]
        1  :b  uint8     2 [1, 2]
        2  :c  uint8     2 [2, 3]
        3  :d  uint8     2 [3, 4]
        4  :e  uint8     2 [4, 5]
        5  :f  uint8     2 [5, 6]
        6  :g  uint8     2 [6, 7]
        7  :h  uint8     2 [7, 8]
        8  :i  uint8     2 [8, 9]
        9  :j  uint8     2 [9, 10]
        10 :k  uint8     2 [10, 11]
      STR
    ensure
      $stdout = STDOUT
    end
  end

  sub_test_case 'summary' do
    setup do
      @df = DataFrame.new(integers: [2, 3, 5, 7], floats: [2.0, 3.0, 5.0, 7.0])
    end

    test '#summary' do
      assert_equal <<~STR, @df.summary.tdr_str
        RedAmber::DataFrame : 2 x 9 Vectors
        Vectors : 8 numeric
        # key        type       level data_preview
        0 :variables dictionary     2 ["integers", "floats"]
        1 :count     uint8          1 {4=>2}
        2 :mean      double         1 {4.25=>2}
        3 :std       double         1 {2.217355782608345=>2}
        4 :min       double         1 {2.0=>2}
        5 :"25%"     double         1 {2.75=>2}
        6 :median    double         1 {4.0=>2}
        7 :"75%"     double         1 {5.5=>2}
        8 :max       double         1 {7.0=>2}
      STR
    end
  end

  sub_test_case 'to_iruby in table mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = nil # Table mode
    end

    test 'empty' do
      df = DataFrame.new
      assert_equal ['text/plain', '(empty DataFrame)'], df.to_iruby
    end

    test 'simple dataframe' do
      df = DataFrame.new(x: [1, 2, Float::NAN], y: ['', ' ', nil], z: [true, false, nil])
      html = 'RedAmber::DataFrame <3 x 3 vectors> <table><tr><th>x</th><th>y</th><th>z</th></tr><tr><td>1</td><td>""</td><td><i>(true)</i></td></tr><tr><td>2</td><td>" "</td><td><i>(false)</i></td></tr><tr><td>NaN</td><td><i>(nil)</i></td><td><i>(nil)</i></td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end

    test 'long dataframe' do
      df = DataFrame.new(x: [*1..11])
      html = 'RedAmber::DataFrame <11 x 1 vector> <table><tr><th>x</th></tr><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr><tr><td>4</td></tr><tr><td>5</td></tr><tr><td>&#8942;</td></tr><tr><td>8</td></tr><tr><td>9</td></tr><tr><td>10</td></tr><tr><td>11</td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end

    test 'wide dataframe' do
      raw_record = (1..16).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = DataFrame.new(raw_record)
      html = 'RedAmber::DataFrame <1 x 16 vectors> <table><tr><th>A</th><th>B</th><th>C</th><th>D</th><th>E</th><th>F</th><th>G</th><th>&#8230;</th><th>J</th><th>K</th><th>L</th><th>M</th><th>N</th><th>O</th><th>P</th></tr><tr><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>&#8230;</td><td>10</td><td>11</td><td>12</td><td>13</td><td>14</td><td>15</td><td>16</td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end

    test 'numeric digits' do
      df = DataFrame.new(digits: [123_456, 12_345.6, 1_234.56, 123.456, 12.3456, 1.23456, 0.123456, 0.0123456, 0.00123456])
      html = 'RedAmber::DataFrame <9 x 1 vector> <table><tr><th>digits</th></tr><tr><td>123456</td></tr><tr><td>12345.6</td></tr><tr><td>1234.56</td></tr><tr><td>123.456</td></tr><tr><td>12.3456</td></tr><tr><td>1.23456</td></tr><tr><td>0.123456</td></tr><tr><td>0.0123456</td></tr><tr><td>0.00123456</td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end

    test 'blank spaces' do
      df = DataFrame.new(str: ['', ' ', 'two words'])
      html = 'RedAmber::DataFrame <3 x 1 vector> <table><tr><th>str</th></tr><tr><td>""</td></tr><tr><td>" "</td></tr><tr><td>two words</td></tr></table>'
      assert_equal html, df.to_iruby[1]
    end

    test 'else' do
      date = Date.parse('2022/04/15')
      html = "RedAmber::DataFrame <1 x 1 vector> <table><tr><th>date</th></tr><tr><td>#{date}</td></tr></table>"
      assert_equal html, DataFrame.new(date: [date]).to_iruby[1]
    end
  end

  sub_test_case 'to_iruby in plain mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'PLAIN'
    end

    test 'empty' do
      df = DataFrame.new
      assert_equal ['text/plain', '(empty DataFrame)'], df.to_iruby
    end

    test 'simple dataframe' do
      df = DataFrame.new(x: [1, 2, Float::NAN], y: ['', ' ', nil], z: [true, false, nil])
      text = <<~OUTPUT
        #<RedAmber::DataFrame : 3 x 3 Vectors>
                 x y        z
          <double> <string> <boolean>
        0      1.0          true
        1      2.0          false
        2      NaN (nil)    (nil)
      OUTPUT
      assert_equal ['text/plain', text], df.to_iruby
    end

    test 'long dataframe' do
      df = RedAmber::DataFrame.new(x: [*1..10])
      text = <<~OUTPUT
        #<RedAmber::DataFrame : 10 x 1 Vector>
                x
          <uint8>
        0       1
        1       2
        2       3
        3       4
        4       5
        5       6
        6       7
        7       8
        8       9
        9      10
      OUTPUT
      assert_equal ['text/plain', text], df.to_iruby
    end

    test 'wide dataframe' do
      raw_record = (1..16).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = RedAmber::DataFrame.new(raw_record)
      text = <<~OUTPUT
        #<RedAmber::DataFrame : 1 x 16 Vectors>
                A       B       C       D       E       F       G       H       I       J       K       L       M       N       O       P
          <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8> <uint8>
        0       1       2       3       4       5       6       7       8       9      10      11      12      13      14      15      16
      OUTPUT
      assert_equal ['text/plain', text], df.to_iruby
    end
  end

  sub_test_case 'to_iruby in minimum mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'Minimum'
    end

    test 'empty' do
      df = DataFrame.new
      assert_equal ['text/plain', '(empty DataFrame)'], df.to_iruby
    end

    test 'simple dataframe' do
      df = DataFrame.new(x: [1, 2, Float::NAN], y: ['', ' ', nil], z: [true, false, nil])
      assert_equal ['text/plain', 'RedAmber::DataFrame : 3 x 3 Vectors'], df.to_iruby
    end

    test 'long dataframe' do
      df = RedAmber::DataFrame.new(x: [*1..10])
      assert_equal ['text/plain', 'RedAmber::DataFrame : 10 x 1 Vector'], df.to_iruby
    end

    test 'wide dataframe' do
      raw_record = (1..16).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = RedAmber::DataFrame.new(raw_record)
      assert_equal ['text/plain', 'RedAmber::DataFrame : 1 x 16 Vectors'], df.to_iruby
    end
  end

  sub_test_case 'to_iruby in tdr mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'TDR'
    end

    test 'empty' do
      df = DataFrame.new
      assert_equal ['text/plain', '(empty DataFrame)'], df.to_iruby
    end

    test 'simple dataframe' do
      df = DataFrame.new(x: [1, 2, Float::NAN], y: ['', ' ', nil], z: [true, false, nil])
      html = <<~OUTPUT
        RedAmber::DataFrame : 3 x 3 Vectors
        Vectors : 1 numeric, 1 string, 1 boolean
        # key type    level data_preview
        0 :x  double      3 [1.0, 2.0, NaN], 1 NaN
        1 :y  string      3 ["", " ", nil], 1 nil
        2 :z  boolean     3 [true, false, nil], 1 nil
      OUTPUT
      assert_equal html, df.to_iruby[1]
    end

    test 'long dataframe' do
      df = RedAmber::DataFrame.new(x: [*1..10])
      html = <<~OUTPUT
        RedAmber::DataFrame : 10 x 1 Vector
        Vector : 1 numeric
        # key type  level data_preview
        0 :x  uint8    10 [1, 2, 3, 4, 5, ... ]
      OUTPUT
      assert_equal html, df.to_iruby[1]
    end

    test 'wide dataframe' do
      raw_record = (1..11).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = RedAmber::DataFrame.new(raw_record)
      html = <<~OUTPUT
        RedAmber::DataFrame : 1 x 11 Vectors
        Vectors : 11 numeric
        # key type  level data_preview
        0 :A  uint8     1 [1]
        1 :B  uint8     1 [2]
        2 :C  uint8     1 [3]
        3 :D  uint8     1 [4]
        4 :E  uint8     1 [5]
        5 :F  uint8     1 [6]
        6 :G  uint8     1 [7]
        7 :H  uint8     1 [8]
        8 :I  uint8     1 [9]
        9 :J  uint8     1 [10]
         ... 1 more Vector ...
      OUTPUT
      assert_equal html, df.to_iruby[1]
    end
  end

  sub_test_case 'to_iruby in tdra mode' do
    setup do
      ENV['RED_AMBER_OUTPUT_MODE'] = 'TDRA'
    end

    test 'wide dataframe' do
      raw_record = (1..11).each.with_object({}) { |i, h| h[(64 + i).chr] = [i] }
      df = RedAmber::DataFrame.new(raw_record)
      html = <<~OUTPUT
        RedAmber::DataFrame : 1 x 11 Vectors
        Vectors : 11 numeric
        #  key type  level data_preview
        0  :A  uint8     1 [1]
        1  :B  uint8     1 [2]
        2  :C  uint8     1 [3]
        3  :D  uint8     1 [4]
        4  :E  uint8     1 [5]
        5  :F  uint8     1 [6]
        6  :G  uint8     1 [7]
        7  :H  uint8     1 [8]
        8  :I  uint8     1 [9]
        9  :J  uint8     1 [10]
        10 :K  uint8     1 [11]
      OUTPUT
      assert_equal html, df.to_iruby[1]
    end
  end

  sub_test_case '#shape_str' do
    setup do
      @df = DataFrame.new(x: [1, 2, 3])
    end

    test '#shape_str' do
      assert_equal 'RedAmber::DataFrame : 3 x 1 Vector', @df.shape_str
      e = "RedAmber::DataFrame : 3 x 1 Vector, #{format('0x%016x', @df.object_id)}"
      assert_equal e, @df.shape_str(with_id: true)
    end
  end
end
