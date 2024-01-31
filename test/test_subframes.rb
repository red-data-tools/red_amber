# frozen_string_literal: true

require 'test_helper'

class SubFranesTest < Test::Unit::TestCase
  include RedAmber
  include TestHelper

  setup do
    @df = DataFrame.new(
      x: [*1..6],
      y: %w[A A B B B C],
      z: [false, true, false, nil, true, false]
    )
    # @df is:
    #         x y        z
    #   <uint8> <string> <boolean>
    # 0       1 A        false
    # 1       2 A        true
    # 2       3 B        false
    # 3       4 B        (nil)
    # 4       5 B        true
    # 5       6 C        false
    @sf = SubFrames.new(@df, [[0, 1], [2, 3, 4], [5]])
  end

  sub_test_case '.by_group' do
    test '.by_group' do
      group = Group.new(@df, [:y])
      sf = SubFrames.by_group(group)
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       6 C        false
      STR
    end
  end

  sub_test_case '.by_indices' do
    test '.by_indices a SubFrames with Vector' do
      sf = SubFrames.by_indices(@df, [Vector.new(0, 2)])
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
      STR
    end
  end

  sub_test_case '.by_filters' do
    test '.by_filters a SubFrames with Array' do
      sf = SubFrames.by_filters(@df, [[true, false, true, false, nil, false]])
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
      STR
    end

    test '.by_filters a SubFrames with Vector' do
      sf = SubFrames.by_filters(@df, [Vector.new(true, false, true, false, nil, false)])
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
      STR
    end
  end

  sub_test_case '.new' do
    test '.new illegal dataframe' do
      assert_raise(SubFramesArgumentError) { SubFrames.new('a', []) }
    end

    test '.new illegal dataframe by a block' do
      assert_raise(SubFramesArgumentError) { SubFrames.new('a') { [] } }
    end

    test '.new empty dataframe' do
      sf = SubFrames.new(DataFrame.new, [[0, 1, 2]])
      assert_equal 0, sf.size
      assert_equal [], sf.sizes
      assert_true sf.first.nil?
    end

    test '.new empty dataframe by a block' do
      sf = SubFrames.new(DataFrame.new) { [[0, 1, 2]] }
      assert_equal 0, sf.size
      assert_equal [], sf.sizes
      assert_true sf.first.nil?
    end

    test '.new empty selector, nil' do
      sf = SubFrames.new(@df)
      assert_equal 0, sf.size
      assert_equal [], sf.sizes
      assert_true sf.first.nil?
    end

    test '.new empty selector, []' do
      sf = SubFrames.new(@df, [])
      assert_equal 0, sf.size
      assert_equal [], sf.sizes
      assert_true sf.first.nil?
    end

    test '.new empty selector by a block, nil' do
      sf = SubFrames.new(@df) { nil }
      assert_equal 0, sf.size
      assert_equal [], sf.sizes
      assert_true sf.first.nil?
    end

    test '.new empty selector by a block, []' do
      sf = SubFrames.new(@df) { [] }
      assert_equal 0, sf.size
      assert_equal [], sf.sizes
      assert_true sf.first.nil?
    end

    test '.new illegal selector' do
      assert_raise(SubFramesArgumentError) { SubFrames.new(@df, [%w[0 1]]) }
    end

    test '.new illegal selector by a block' do
      assert_raise(SubFramesArgumentError) { SubFrames.new(@df) { [%w[0 1]] } }
    end

    test '.new both selector and block' do
      assert_raise(SubFramesArgumentError) { SubFrames.new(@df, [[0]]) { [[0]] } }
    end

    test '.new a SubFrames with index Array' do
      sf = SubFrames.new(@df, [[0, 2]])
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
      STR
    end

    test '.new a SubFrames with index Array by a block' do
      sf = SubFrames.new(@df) { [[0, 2]] }
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
      STR
    end

    test '.new a SubFrames with index Vector' do
      sf = SubFrames.new(@df, [Vector.new(0, 2)])
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
      STR
    end

    test '.new a SubFrames with index Vector by a block' do
      sf = SubFrames.new(@df) { [Vector.new(0, 2, 5)] }
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
        2       6 C        false
      STR
    end

    test '.new index out of range' do
      sf = SubFrames.new(@df, [[0, 2, 6]])
      assert_kind_of Enumerator, sf.each
      assert_raise(Arrow::Error::Index) { sf.first }
    end

    test '.new index out of range by a block' do
      sf = SubFrames.new(@df) { [[0, 2, 6]] }
      assert_kind_of Enumerator, sf.each
      assert_raise(Arrow::Error::Index) { sf.first }
    end

    test '.new a SubFrames with boolean Array' do
      sf = SubFrames.new(@df, [[true, false, true, false, nil, true]])
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
        2       6 C        false
      STR
    end

    test '.new a SubFrames with boolean Array by a block' do
      sf = SubFrames.new(@df) { [[true, false, true, false, nil, true]] }
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
        2       6 C        false
      STR
    end

    test '.new a SubFrames with boolean Vector' do
      sf = SubFrames.new(@df, [Vector.new(true, false, true, false, nil, true)])
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       3 B        false
        2       6 C        false
      STR
    end

    test '.new a SubFrames with boolean Vector by a block' do
      sf = SubFrames.new(@df) { |df| [df.y == 'B'] }
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
      STR
    end
  end

  sub_test_case '#each' do
    test '#each w/o block' do
      assert_kind_of Enumerator, @sf.each
      assert_equal 3, @sf.each.size
    end

    test '#each yielded block' do
      expect = [[[1, 'A', false], [2, 'A', true]],
                [[3, 'B', false], [4, 'B', nil], [5, 'B', true]],
                [[6, 'C', false]]]
      assert_equal expect, @sf.each.with_object([]) { |df, a| a << df.to_a }
    end

    test '#each for stepwise iteration' do
      sf = SubFrames.by_indices(@df, [[1], [1, 2]])
      enum = sf.each
      assert_kind_of Enumerator, enum
      assert_equal 2, enum.size
      first = sf.first
      assert_equal first, enum.next
      assert_equal first, sf.take(2).first
    end
  end

  sub_test_case '#aggregate' do
    setup do
      @df = DataFrame.new(
        x: [*1..6],
        y: %w[A A B B B C],
        z: [false, true, false, nil, true, false]
      )
      @sf = SubFrames.new(@df, [[0, 1], [2, 3, 4], [5]])
      @expected = <<~STR
          y          sum_x
          <string> <uint8>
        0 A              3
        1 B             12
        2 C              6
      STR
    end

    test '#aggregate nothing' do
      assert_raise(SubFramesArgumentError) { @sf.aggregate }
    end

    test '#aggregate invalid argument' do
      assert_raise(SubFramesArgumentError) { @sf.aggregate([:y], ['x', :sum]) }
    end

    # It is not a aggregation function, but returns a concatenated string.
    test '#aggregate by an element-wise function by block' do
      aggregated = @sf.aggregate(:y, :abs_x) { [y.first, x.abs] }
      assert_kind_of DataFrame, aggregated
      assert_equal <<~STR, aggregated.to_s
          y        abs_x
          <string> <string>
        0 A        [1, 2]
        1 B        [3, 4, 5]
        2 C        [6]
      STR
    end

    # It is not a aggregation function, but returns a concatenated string.
    test '#aggregate by an element-wise function by a Hash' do
      aggregated = @sf.aggregate([:y], { x: :abs })
      assert_kind_of DataFrame, aggregated
      assert_equal <<~STR, aggregated.to_s
          y        abs_x
          <string> <string>
        0 A        [1, 2]
        1 B        [3, 4, 5]
        2 C        [6]
      STR
    end

    test '#aggregate by a Hash' do
      aggregated = @sf.aggregate([:y], { x: :sum })
      assert_kind_of DataFrame, aggregated
      assert_equal @expected, aggregated.to_s
    end

    test '#aggregate by an Array w/o group key' do
      aggregated = @sf.aggregate([], [%i[x z], %i[sum count]])
      assert_kind_of DataFrame, aggregated
      assert_equal <<~STR, aggregated.to_s
            sum_x   sum_z count_x count_z
          <uint8> <uint8> <uint8> <uint8>
        0       3       1       2       2
        1      12       1       3       2
        2       6       0       1       1
      STR
    end

    test '#aggregate by an Array with group key' do
      aggregated = @sf.aggregate([:y], [%i[x z], %i[sum count]])
      assert_kind_of DataFrame, aggregated
      assert_equal <<~STR, aggregated.to_s
          y          sum_x   sum_z count_x count_z
          <string> <uint8> <uint8> <uint8> <uint8>
        0 A              3       1       2       2
        1 B             12       1       3       2
        2 C              6       0       1       1
      STR
    end

    test '#aggregate by args and block' do
      aggregated = @sf.aggregate(:y, :sum_x) { [y.first, x.sum] }
      assert_kind_of DataFrame, aggregated
      assert_equal @expected, aggregated.to_s
    end

    test '#aggregate by array and block' do
      aggregated = @sf.aggregate(%i[y sum_x]) { [y.first, x.sum] }
      assert_kind_of DataFrame, aggregated
      assert_equal @expected, aggregated.to_s
    end

    test '#aggregate by block with a hash' do
      aggregated = @sf.aggregate { { y: y.first, sum_x: x.sum } }
      assert_kind_of DataFrame, aggregated
      assert_equal @expected, aggregated.to_s
    end

    test '#aggregate by block with an array' do
      aggregated = @sf.aggregate { [[:y, y.first], [:sum_x, x.sum]] }
      assert_kind_of DataFrame, aggregated
      assert_equal @expected, aggregated.to_s
    end

    test '#aggregate by block with an Array' do
      assert_raise(TypeError) { @sf.aggregate { [:y, y.first] } }
    end

    test '#aggregate by block with an Array w/o group key' do
      aggregations =
        %i[sum count].product(%i[x z]).map do |func, key|
          [:"#{func}_#{key}", key, func]
        end
      aggregated =
        @sf.aggregate do |df|
          aggregations.map do |label, key, func|
            [label, df.send(key).send(func)]
          end
        end
      assert_kind_of DataFrame, aggregated
      assert_equal <<~STR, aggregated.to_s
            sum_x   sum_z count_x count_z
          <uint8> <uint8> <uint8> <uint8>
        0       3       1       2       2
        1      12       1       3       2
        2       6       0       1       1
      STR
    end

    test '#aggregate by block with an Array and group key' do
      aggregations = [%i[y y first]]
      %i[sum count].product(%i[x z]).each do |func, key|
        aggregations << [:"#{func}_#{key}", key, func]
      end
      aggregated =
        @sf.aggregate do |df|
          aggregations.map do |label, key, func|
            [label, df.send(key).send(func)]
          end
        end
      assert_kind_of DataFrame, aggregated
      assert_equal <<~STR, aggregated.to_s
          y          sum_x   sum_z count_x count_z
          <string> <uint8> <uint8> <uint8> <uint8>
        0 A              3       1       2       2
        1 B             12       1       3       2
        2 C              6       0       1       1
      STR
    end
  end

  sub_test_case '#map' do
    test '#map w/o block' do
      assert_kind_of Enumerator, @sf.map
      assert_equal 3, @sf.map.size
    end

    test '#map empty SubFrames' do
      empty = SubFrames.new(DataFrame.new, [])
      assert_kind_of Enumerator, empty.map
      assert_true empty.map.first.nil?
      assert_equal [], empty.map.to_a
    end

    test '#map as it is' do
      sf = @sf.map { |df| df }
      assert_kind_of SubFrames, sf
      assert_false @sf.equal?(sf) # object ids are not equal
      assert_equal @sf.to_a, sf.to_a # but have same contents
    end

    test '#map create a new column' do
      sf = @sf.map { |df| df.assign(plus1: df[:x] + 1) }
      assert_equal <<~STR, sf.to_s
                x y        z           plus1
          <uint8> <string> <boolean> <uint8>
        0       1 A        false           2
        1       2 A        true            3
        ---
                x y        z           plus1
          <uint8> <string> <boolean> <uint8>
        0       3 B        false           4
        1       4 B        (nil)           5
        2       5 B        true            6
        ---
                x y        z           plus1
          <uint8> <string> <boolean> <uint8>
        0       6 C        false           7
      STR
      assert_equal @df.assign(plus1: @df[:x] + 1), sf.baseframe
    end
  end

  sub_test_case '#assign' do
    setup do
      @expected = <<~STR
                x y        z           plus1
          <uint8> <string> <boolean> <uint8>
        0       1 A        false           2
        1       2 A        true            3
        ---
                x y        z           plus1
          <uint8> <string> <boolean> <uint8>
        0       3 B        false           4
        1       4 B        (nil)           5
        2       5 B        true            6
        ---
                x y        z           plus1
          <uint8> <string> <boolean> <uint8>
        0       6 C        false           7
      STR
      @expected_baseframe = @df.assign(:plus1) { x + 1 }
    end

    test '#assign create a new column by arg and block' do
      sf = @sf.assign(:plus1) { x + 1 }
      assert_kind_of SubFrames, sf
      assert_equal @expected, sf.to_s
      assert_equal @expected_baseframe, sf.baseframe
    end

    test '#assign create a new column by block only' do
      sf = @sf.assign { { plus1: x + 1 } }
      assert_kind_of SubFrames, sf
      assert_equal @expected, sf.to_s
      assert_equal @expected_baseframe, sf.baseframe
    end
  end

  sub_test_case '#select' do
    test '#select w/o block' do
      assert_kind_of Enumerator, @sf.select
      assert_equal 3, @sf.select.size
    end

    test '#select all' do
      sf = @sf.select { true }
      assert_kind_of SubFrames, sf
      assert_false @sf.equal?(sf) # object ids are not equal
      assert_equal @sf.to_a, sf.to_a # but have same contents
    end

    test '#select nothing' do
      sf = @sf.select { false }
      assert_kind_of SubFrames, sf
      assert_true sf.empty?
      assert_equal_array [], sf.baseframe.to_a
    end

    test '#select elements' do
      sf = @sf.select { |df| df.size < 3 }
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       6 C        false
      STR
      assert_equal @df.remove(2..4), sf.baseframe
    end
  end

  sub_test_case '#reject' do
    test '#reject w/o block' do
      assert_kind_of Enumerator, @sf.reject
      assert_equal 3, @sf.reject.size
    end

    test '#reject all' do
      sf = @sf.reject { true }
      assert_kind_of SubFrames, sf
      assert_true sf.empty?
      assert_equal_array [], sf.baseframe.to_a
    end

    test '#reject nothing' do
      sf = @sf.reject { false }
      assert_kind_of SubFrames, sf
      assert_false @sf.equal?(sf) # object ids are not equal
      assert_equal @sf.to_a, sf.to_a # but have same contents
    end

    test '#reject elements' do
      sf = @sf.reject { |df| df.size > 2 }
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       6 C        false
      STR
      assert_equal @df.remove(2..4), sf.baseframe
    end
  end

  sub_test_case '#filter_map' do
    test '#filter_map w/o block' do
      assert_kind_of Enumerator, @sf.filter_map
      assert_equal 3, @sf.filter_map.size
    end

    test '#filter_map all' do
      sf = @sf.filter_map { _1 }
      assert_kind_of SubFrames, sf
      assert_false @sf.equal?(sf) # object ids are not equal
      assert_equal @sf.to_a, sf.to_a # but have same contents
    end

    test '#filter_map nothing' do
      sf = @sf.filter_map { false }
      assert_kind_of SubFrames, sf
      assert_true sf.empty?
      assert_equal_array [], sf.baseframe.to_a
    end

    test '#filter_map empty Dataframes' do
      sf = @sf.filter_map { DataFrame.new }
      assert_kind_of SubFrames, sf
      assert_equal [0, 0, 0], sf.sizes
      assert_equal_array [], sf.baseframe.to_a
      assert_true sf.first.empty?
    end

    test '#filter_map elements' do
      sf =
        @sf.filter_map do |df|
          if df.size > 1
            df.assign(:y) do
              y.merge(indices('1'), sep: '')
            end
          end
        end
      assert_equal <<~STR, sf.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A1       false
        1       2 A2       true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B1       false
        1       4 B2       (nil)
        2       5 B3       true
      STR
      assert_equal <<~STR, sf.baseframe.to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A1       false
        1       2 A2       true
        2       3 B1       false
        3       4 B2       (nil)
        4       5 B3       true
      STR
    end
  end

  sub_test_case '#take' do
    test '#take(0)' do
      assert_true @sf.take(0).empty?
    end

    test '#take all' do
      assert_equal @sf, @sf.take(@sf.size)
      assert_equal @sf, @sf.take(@sf.size + 1)
    end

    test '#take(1)' do
      assert_equal <<~STR, @sf.take(1).to_s
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
      STR
    end
  end

  # Tests for #size, #sizes, #offset_indices, #empty? and #universal?
  sub_test_case 'properties' do
    test 'properties of empty SubFrame' do
      empty_subframe = SubFrames.new(@df, [])
      assert_equal 0, empty_subframe.size
      assert_equal [], empty_subframe.sizes
      assert_equal [], empty_subframe.offset_indices
      assert_true empty_subframe.empty?
      assert_false empty_subframe.universal?
    end

    test 'properties of SubFrames' do
      selector = [[0, 1], [2, 3, 4], [5]]
      sf = SubFrames.new(@df, selector)
      assert_equal 3, sf.size
      assert_equal [2, 3, 1], sf.sizes
      assert_equal [0, 2, 5], sf.offset_indices
      assert_false sf.empty?
      assert_false sf.universal?
    end

    test 'properties of universal SubFrame' do
      selector = [[*0..5]]
      universal = SubFrames.new(@df, selector)
      assert_equal 1, universal.size
      assert_equal [6], universal.sizes
      assert_equal [0], universal.offset_indices
      assert_false universal.empty?
      assert_true universal.universal?
    end

    test 'proprties of Subframes from Filters' do
      selector = [[false, true, true, nil, false, true]]
      sf = SubFrames.new(@df, selector)
      assert_equal 1, sf.size
      assert_equal [3], sf.sizes
      assert_equal [1], sf.offset_indices
      assert_false sf.empty?
      assert_false sf.universal?
    end
  end

  sub_test_case '#inspect' do
    test '#inspect empty SubFrame' do
      sf = SubFrames.new(@df, [])
      enum = sf.each
      assert_equal <<~STR, sf.inspect
        #<RedAmber::SubFrames : #{format('0x%016x', sf.object_id)}>
        @baseframe=#<RedAmber::DataFrame : (empty), #{format('0x%016x', sf.baseframe.object_id)}>
        0 SubFrame: [] in size.
        ---
      STR
    end

    test '#inspect SubFrames' do
      sf = SubFrames.new(@df, [[0, 1], [2, 3, 4], [5]])
      enum = sf.each
      assert_equal <<~STR, sf.inspect
        #<RedAmber::SubFrames : #{format('0x%016x', sf.object_id)}>
        @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, #{format('0x%016x', sf.baseframe.object_id)}>
        3 SubFrames: [2, 3, 1] in sizes.
        ---
        #<RedAmber::DataFrame : 2 x 3 Vectors, #{format('0x%016x', enum.next.object_id)}>
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
        #<RedAmber::DataFrame : 3 x 3 Vectors, #{format('0x%016x', enum.next.object_id)}>
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        ---
        #<RedAmber::DataFrame : 1 x 3 Vectors, #{format('0x%016x', enum.next.object_id)}>
                x y        z
          <uint8> <string> <boolean>
        0       6 C        false
      STR
    end

    test '#inspect universal SubFrame' do
      sf = SubFrames.new(@df, [[*0..5]])
      enum = sf.each
      assert_equal <<~STR, sf.inspect
        #<RedAmber::SubFrames : #{format('0x%016x', sf.object_id)}>
        @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, #{format('0x%016x', sf.baseframe.object_id)}>
        1 SubFrame: [6] in size.
        ---
        #<RedAmber::DataFrame : 6 x 3 Vectors, #{format('0x%016x', enum.next.object_id)}>
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        :       : :        :
        4       5 B        true
        5       6 C        false
      STR
    end

    test '#inspect @baseframe is a Enumerator' do
      sf = SubFrames.new(@df, [[0, 1], [2, 3, 4], [5]]).map { _1 }
      enum = sf.each
      assert_equal <<~STR, sf.inspect
        #<RedAmber::SubFrames : #{format('0x%016x', sf.object_id)}>
        @baseframe=#<(Not prepared)>
        3 SubFrames: [2, 3, 1] in sizes.
        ---
        #<RedAmber::DataFrame : 2 x 3 Vectors, #{format('0x%016x', enum.next.object_id)}>
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
        #<RedAmber::DataFrame : 3 x 3 Vectors, #{format('0x%016x', enum.next.object_id)}>
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        ---
        #<RedAmber::DataFrame : 1 x 3 Vectors, #{format('0x%016x', enum.next.object_id)}>
                x y        z
          <uint8> <string> <boolean>
        0       6 C        false
      STR
    end
  end

  sub_test_case '#to_s' do
    test '#to_s' do
      expected = <<~STR
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       6 C        false
      STR
      assert_equal expected, @sf.to_s
    end

    test '#to_s set limit' do
      expected = <<~STR
                x y        z
          <uint8> <string> <boolean>
        0       1 A        false
        1       2 A        true
        ---
                x y        z
          <uint8> <string> <boolean>
        0       3 B        false
        1       4 B        (nil)
        2       5 B        true
        ---
        + 1 more DataFrame.
      STR
      assert_equal expected, @sf.to_s(limit: 2)
    end
  end

  sub_test_case '#concatenate' do
    test '#concatenate' do
      assert_kind_of DataFrame, @sf.concatenate
      assert_equal_array @df.to_a, @sf.concatenate
    end
  end

  sub_test_case '#frames' do
    setup do
      @sf_frames = SubFrames.by_indices(@df, [[0, 1], [2, 3, 4], [5]])
    end

    test '#frames(0)' do
      assert_equal [], @sf_frames.frames(0)
    end

    test '#frames(1)' do
      expected = [@df[0, 1]]
      assert_equal expected, @sf_frames.frames(1)
      assert_equal [], @sf_frames.frames(0)
    end

    test '#frames all' do
      expected = [@df[0, 1], @df[2, 3, 4], @df[5]]
      assert_equal expected, @sf_frames.frames
      assert_equal [], @sf_frames.frames(0)
    end
  end
end
