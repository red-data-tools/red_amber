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
end
