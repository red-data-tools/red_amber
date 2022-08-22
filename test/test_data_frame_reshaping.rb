# frozen_string_literal: true

require 'test_helper'

class DataFrameReshapingTest < Test::Unit::TestCase
  include RedAmber

  sub_test_case 'transpose' do
    setup do
      @df = DataFrame.new(
        index: %w[name1 name2 name3],
        One: [1.1, 1.2, 1.3],
        Two: [2.1, 2.2, 2.3],
        Three: [3.1, 3.2, 3.3]
      )
    end

    test '#transpose' do
      str = <<~STR
          name            name1    name2    name3
          <dictionary> <double> <double> <double>
        1 One               1.1      1.2      1.3
        2 Two               2.1      2.2      2.3
        3 Three             3.1      3.2      3.3
      STR
      assert_equal str, @df.transpose.to_s

      df = @df[@df.keys[1..], @df.keys[0]] # :index is at right
      assert_equal str, df.transpose(key: :index).to_s

      assert_raise(DataFrameArgumentError) { @df.transpose(key: :not_exist) }
    end

    test '#transpose with :new_key' do
      str = <<~STR
          name4           name1    name2    name3
          <dictionary> <double> <double> <double>
        1 One               1.1      1.2      1.3
        2 Two               2.1      2.2      2.3
        3 Three             3.1      3.2      3.3
      STR
      assert_equal str, @df.transpose(new_key: :name1).to_s
    end
  end

  sub_test_case 'to_long' do
    setup do
      @df = DataFrame.new(
        names: %w[name1 name2 name3],
        One: [1.1, 1.2, 1.3],
        Two: [2.1, 2.2, 2.3],
        Three: [3.1, 3.2, 3.3]
      )
    end

    test '#to_long' do
      assert_raise(DataFrameArgumentError) { @df.to_long(:not_exist) }
      assert_raise(DataFrameArgumentError) { @df.to_long(:names, name: :names) }
      assert_raise(DataFrameArgumentError) { @df.to_long(:names, value: :names) }

      assert_equal <<~STR, @df.to_long(:names).to_s
          names    name            value
          <string> <dictionary> <double>
        1 name1    One               1.1
        2 name1    Two               2.1
        3 name1    Three             3.1
        4 name2    One               1.2
        5 name2    Two               2.2
        6 name2    Three             3.2
        7 name3    One               1.3
        8 name3    Two               2.3
        9 name3    Three             3.3
      STR

      assert_equal <<~STR, @df.to_long.to_s
           name         value
           <dictionary> <string>
         1 names        name1
         2 One          1.1
         3 Two          2.1
         4 Three        3.1
         5 names        name2
         : :            :
        10 One          1.3
        11 Two          2.3
        12 Three        3.3
      STR
    end
  end

  sub_test_case 'to_wide' do
    setup do
      df = DataFrame.new(
        names: %w[name1 name2 name3],
        One: [1.1, 1.2, 1.3],
        Two: [2.1, 2.2, 2.3],
        Three: [3.1, 3.2, 3.3]
      )
      @df = df.to_long(:names)
      @str = df.to_s
    end

    test '#to_wide' do
      assert_raise(DataFrameArgumentError) { @df.to_wide(name: :not_exist) }
      assert_raise(DataFrameArgumentError) { @df.to_wide(value: :not_exist) }
      assert_equal @str, @df.to_wide.to_s
    end

    test '#to_wide with options' do
      df = @df.rename(name: :key1, value: :key2)
      assert_equal @str, df.to_wide(name: :key1, value: :key2).to_s
    end
  end
end
