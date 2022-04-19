# frozen_string_literal: true

require 'test_helper'

class RedAmberTest < Test::Unit::TestCase
  def setup
    @hash = { 'name' => %w[Yasuko Rui Hinata], 'age' => [68, 49, 28] }
    @hash_sym = @hash.each_with_object({}) do |kv, h|
      k, v = kv
      h[k.to_sym] = v
    end
    @types = %i[string uint8]
    @table = Arrow::Table.new(@hash)
    @df = RedAmber::DataFrame.new(@hash)
  end

  def test_new_hash
    assert_equal(@table, @df.table)
  end

  def test_n_rows
    assert_equal(@hash.first.last.size, @df.n_rows)
    assert_equal(@hash.first.last.size, @df.nrow)
    assert_equal(@hash.first.last.size, @df.length)
  end

  def test_n_columns
    assert_equal(@hash.keys.size, @df.n_columns)
    assert_equal(@hash.keys.size, @df.ncol)
    assert_equal(@hash.keys.size, @df.width)
  end

  def test_shape
    assert_equal([@hash.first.last.size, @hash.keys.size], @df.shape)
  end

  def test_to_h
    assert_equal(@hash_sym, @df.to_h)
  end

  def test_column_names
    assert_equal(@hash_sym.keys, @df.column_names)
    assert_equal(@hash_sym.keys, @df.keys)
  end

  def test_types
    assert_equal(@types, @df.types)
  end
end
