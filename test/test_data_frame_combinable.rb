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
end
