# frozen_string_literal: true

require 'test_helper'

class RefinementsTest < Test::Unit::TestCase
  include TestHelper
  include RedAmber

  using RefineArray

  sub_test_case 'refine Array' do
    setup do
      @integers = [1, 0, -1]
      @floats = [1.0, -1.0, Float::NAN]
      @booleans = [true, false, nil]
      @symbols = %i[a b c]
      @strings = %w[a b c]
      @symbols_or_strings = [:a, 'b', :c]
    end

    test 'Array#integer?' do
      assert_true @integers.integer?
      assert_true [].integer?
      assert_false @booleans.integer?
    end

    test 'Array#numeric?' do
      assert_true @integers.numeric?
      assert_true @floats.numeric?
      assert_true [].numeric?
      assert_false @booleans.numeric?
    end

    test 'Array#boolean?' do
      assert_true @booleans.boolean?
      assert_true [].boolean?
      assert_false @integers.boolean?
    end

    test 'Array#symbol?' do
      assert_true @symbols.symbol?
      assert_true [].symbol?
      assert_false @integers.symbol?
    end

    test 'Array#string?' do
      assert_true @strings.string?
      assert_true [].string?
      assert_false @integers.string?
    end

    test 'Array#symbol_or_string?' do
      assert_true @symbols_or_strings.symbol_or_string?
      assert_true [].symbol_or_string?
      assert_false @integers.symbol_or_string?
    end

    test 'Array#booleans_to_indices' do
      assert_equal [0], @booleans.booleans_to_indices
    end

    test 'Array#select_by_booleans' do
      assert_equal [:a], @symbols.select_by_booleans(@booleans)
    end

    test 'Array#reject_by_booleans' do
      assert_equal %i[b c], @symbols.reject_by_booleans(@booleans)
    end

    test 'Array#reject_by_indices' do
      assert_equal [], @symbols.reject_by_indices(@integers)
    end
  end

  using RefineArrayLike

  sub_test_case 'refine Array like' do
    test 'Array#to_arrow_array' do
      a = [1, 2, 3]
      assert_true a.respond_to?(:to_arrow_array)
      assert_kind_of Arrow::Array, a.to_arrow_array
      assert_equal_array [1, 2, 3], a.to_arrow_array
    end

    test 'Range#to_arrow_array' do
      r = (1..3)
      assert_true r.respond_to?(:to_arrow_array)
      assert_kind_of Arrow::Array, r.to_arrow_array
      assert_equal_array [1, 2, 3], r.to_arrow_array
    end

    test 'Arrow::Array#to_arrow_array' do
      aa = Arrow::Array.new([1, 2, 3])
      assert_true aa.respond_to?(:to_arrow_array)
      assert_kind_of Arrow::Array, aa.to_arrow_array
      assert_equal_array [1, 2, 3], aa.to_arrow_array
    end

    test 'Arrow::ChunkedArray#to_arrow_array' do
      ca = Arrow::ChunkedArray.new([[1, 2, 3]])
      assert_true ca.respond_to?(:to_arrow_array)
      assert_kind_of Arrow::ChunkedArray, ca.to_arrow_array
      assert_equal_array [1, 2, 3], ca.to_arrow_array
    end

    test 'Arrow::Array/ChunkedArray#type_class' do
      a = [1, 2, 3]
      assert_equal Arrow::UInt8DataType, Arrow::Array.new(a).type_class
      assert_equal Arrow::UInt8DataType, Arrow::ChunkedArray.new([a]).type_class
    end

    test 'Arrow::Array/ChunkedArray#boolean?' do
      a = [true, false, nil]
      assert_true Arrow::Array.new(a).boolean?
      assert_true Arrow::ChunkedArray.new([a]).boolean?
    end

    test 'Arrow::Array/ChunkedArray#numeric?' do
      a = [1, 2, 3]
      assert_true Arrow::Array.new(a).numeric?
      assert_true Arrow::ChunkedArray.new([a]).numeric?
    end

    test 'Arrow::Array/ChunkedArray#float?' do
      a = [1.0, 2.0, 3.0]
      assert_true Arrow::Array.new(a).float?
      assert_true Arrow::ChunkedArray.new([a]).float?
    end

    test 'Arrow::Array/ChunkedArray#integer?' do
      a = [1, 2, 3]
      assert_true Arrow::Array.new(a).integer?
      assert_true Arrow::ChunkedArray.new([a]).integer?
    end

    test 'Arrow::Array/ChunkedArray#unsigned_integer?' do
      a = [1, 2, 3]
      assert_true Arrow::Array.new(a).unsigned_integer?
      assert_true Arrow::ChunkedArray.new([a]).unsigned_integer?
    end

    test 'Arrow::Array/ChunkedArray#string?' do
      a = %w[a b c]
      assert_true Arrow::Array.new(a).string?
      assert_true Arrow::ChunkedArray.new([a]).string?
    end

    test 'Arrow::Array/ChunkedArray#dictionary?' do
      a = %i[a b c]
      assert_true Arrow::Array.new(a).dictionary?
      assert_true Arrow::ChunkedArray.new([a]).dictionary?
    end

    test 'Arrow::Array/ChunkedArray#temporal?' do
      a = [Date.today]
      assert_true Arrow::Array.new(a).temporal?
      assert_true Arrow::ChunkedArray.new([a]).temporal?
    end

    test 'Arrow::Array/ChunkedArray#primitive_invert?' do
      a = [true, false, nil]
      inv = a.map(&:!)
      assert_equal_array inv, Arrow::Array.new(a).primitive_invert
      assert_equal_array inv, Arrow::ChunkedArray.new([a]).primitive_invert
    end
  end

  using RefineArrowTable

  sub_test_case 'refine Arrow::Table' do
    setup do
      @table = Arrow::Table.new(x: [1, 2, 3], y: %w[A B C])
    end

    test 'Arrow::Table#keys' do
      assert_true @table.respond_to?(:keys)
      assert_equal %i[x y], @table.keys
    end

    test 'Arrow::Table#key?' do
      assert_true @table.respond_to?(:key?)
      assert_true @table.key?(:x)
      assert_false @table.key?(:a)
    end
  end

  using RefineHash

  sub_test_case 'refine Hash' do
    test 'Hash#to_arrow' do
      h = { x: [1, 2, 3] }
      assert_true h.respond_to?(:to_arrow)
      assert_kind_of Arrow::Table, h.to_arrow
      assert_equal Arrow::Table.new(x: [1, 2, 3]), h.to_arrow
    end
  end

  using RefineString

  sub_test_case 'refine String' do
    test 'String#width' do
      assert_equal 0, ''.width
      assert_equal 7, 'ABC予想'.width
    end
  end
end
