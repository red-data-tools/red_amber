# frozen_string_literal: true

require 'test_helper'

class VectorTest < Test::Unit::TestCase
  include RedAmber
  include Helper

  sub_test_case('replace') do
    test 'empty vector' do
      vec = Vector.new([])
      assert_true vec.replace(nil, nil).empty?
      assert_true vec.replace([], nil).empty?
      assert_true vec.replace([nil], nil).empty?
    end

    test 'replace UInt argument' do
      vec = Vector.new([1, 2, 3])
      assert_equal [0, 2, 0], vec.replace([0, 2], 0).to_a
      assert_equal [0, 2, 0], vec.replace([2, 0], [0]).to_a
      assert_equal [0, 2, 4], vec.replace([0, 2], [0, 4]).to_a
      assert_raise(VectorArgumentError) { vec.replace([0, 2], [0, 0, 0]) } # size mismatch
      assert_raise(VectorArgumentError) { vec.replace([0, 1, 2], [0, 0]) } # size mismatch
      assert_equal [5, 2, 4], vec.replace([0, 2, nil], [5, 4]).to_a
      assert_equal [0, 2, nil], vec.replace([0, 2], [0, nil]).to_a
    end

    test 'replace Int/Range argument mixture' do
      vec = Vector.new([1, 2, 3])
      assert_equal [0, 0, 0], vec.replace([0..1, 2], 0).to_a
      assert_equal [1, 2, 0], vec.replace([2, -1], 0).to_a
    end

    test 'replace Range' do
      vec = Vector.new([1, 2, 3])
      expected = [0, 0, 3]
      assert_equal expected, vec.replace([0..1], 0).to_a
      assert_equal expected, vec.replace([0...-1], 0).to_a
    end

    test 'replace UInt single' do
      vec = Vector.new([1, 2, 3])
      assert_equal [1, 2, 0], vec.replace([false, false, true], 0).to_a
      assert_equal [1, 2, 0], vec.replace([false, false, true], [0]).to_a
      assert_raise(VectorArgumentError) { vec.replace([true], 0) } # boolean size mismatch
      assert_raise(VectorArgumentError) { vec.replace([false, false, nil], 0) } # no true in boolean
      assert_raise(VectorArgumentError) { vec.replace([true, false, nil], [0, 0]) } # replacement size mismatch
    end

    test 'replace multi/broadcast' do
      vec = Vector.new([1, 2, 3])
      assert_equal [0, 2, 0], vec.replace([true, false, true], [0, 0]).to_a
      assert_equal [0, 2, 0], vec.replace([true, false, true], [0]).to_a
      assert_equal [0, 2, 0], vec.replace([true, false, true], 0).to_a
    end

    test 'replace multi/upcast' do
      vec = Vector.new([1, 2, 3])
      assert_equal [0, 2, -1], vec.replace([true, false, true], [0, -1]).to_a
      assert_equal :int8, vec.replace([true, false, true], [0, -1]).type
    end

    test 'replace containing nil' do
      vec = Vector.new([1, 2, 3])
      assert_equal [0, 2, nil], vec.replace([true, false, nil], [0]).to_a
    end

    test 'replace Arrow::Array' do
      vec = Vector.new([1, 2, 3])
      booleans = Arrow::Array.new([true, false, nil])
      assert_equal [0, 2, nil], vec.replace(booleans, [0]).to_a
    end

    test 'replace with nil' do
      vec = Vector.new([1, 2, 3])
      assert_equal [0, 2, nil], vec.replace([true, false, true], [0, nil]).to_a # 1 nil
      assert_equal [nil, 2, nil], vec.replace([true, false, true], [nil]).to_a # broadcast with nil
      assert_equal [nil, 2, nil], vec.replace([true, false, true], nil).to_a # broadcast with nil
      assert_raise(ArgumentError) { vec.replace([true, false, true]) } # w/o replacer
    end
  end

  sub_test_case('Ternary function #if_else') do
    setup do
      @empty = Vector.new([])
      @boolean = Vector.new([true, true, false, nil])
      @integer = Vector.new([1, 2, 3, nil])
      @double = Vector.new([1.0, Float::NAN, Float::INFINITY, nil])
      @string = Vector.new(%w[A B C] << nil)
    end

    test 'not a boolean' do
      assert_raise(RedAmber::VectorTypeError) { @integer.if_else(@integer, @integer) }
    end

    test 'empty' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(@empty, @integer) }
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(@integer, @empty) }
    end

    test 'scalar or scalar' do
      assert_equal [1, 1, 0, nil], @boolean.if_else(1, 0).to_a
      assert_raise(ArgumentError) { @boolean.if_else(1, nil) }
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(1, 'A') }
    end

    test 'array or scalar' do
      assert_equal [1, 2, 0, nil], @boolean.if_else([1, 2, 3, 4], 0).to_a
    end

    test 'array or array' do
      assert_equal [1, 2, 0, nil], @boolean.if_else([1, 2, 3, 4], [0, 0, 0, nil]).to_a
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else([1, 2, 3, 4], [nil, nil, nil, nil]) }
      assert_equal [1, 2, nil, nil], @boolean.if_else([1, 2, 3, 4], Arrow::UInt8Array.new([nil, nil, nil, nil])).to_a
    end

    test 'vector or scalar' do
      assert_equal [1, 2, 0, nil], @boolean.if_else(@integer, 0).to_a
    end

    test 'vector(integer) or vector(double)' do
      assert_equal [1.0, 2.0, Float::INFINITY, nil], @boolean.if_else(@integer, @double).to_a
    end

    test 'vector(integer) or vector(string)' do
      assert_raise(Arrow::Error::NotImplemented) { @boolean.if_else(@integer, @string) }
    end
  end

  sub_test_case '#primitive_invert' do
    test '#primitive_invert' do
      assert_raise(VectorTypeError) { Vector.new([1]).primitive_invert }
      assert_equal [false, true, true], Vector.new([true, false, nil]).primitive_invert.to_a
    end
  end

  sub_test_case '#shift' do
    test '#shift' do
      vector = Vector.new([1, 2, 3, 4, 5])
      assert_equal [nil, 1, 2, 3, 4], vector.shift
      assert_equal [3, 4, 5, nil, nil], vector.shift(-2)
      assert_equal [0, 0, 1, 2, 3], vector.shift(2, fill: 0)
    end
  end
end
