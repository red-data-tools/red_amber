# frozen_string_literal: true

require 'test_helper'

class SubFranesTest < Test::Unit::TestCase
  include RedAmber
  include TestHelper

  sub_test_case '.by_indices' do
    setup do
      @df = DataFrame.new(x: [*1..3])
    end

    test '.by_indices a SubFrames with Vector' do
      sf = SubFrames.by_indices(@df, [Vector.new(0, 2)])
      assert_equal_array [[0, 2]], sf.subset_indices
      assert_kind_of Vector, sf.subset_indices[0]
    end
  end

  sub_test_case '.by_filters' do
    setup do
      @df = DataFrame.new(x: [*1..3])
    end

    test '.by_filters a SubFrames with Array' do
      sf = SubFrames.by_filters(@df, [[true, false, true]])
      assert_equal_array [[0, 2]], sf.subset_indices
      assert_kind_of Vector, sf.subset_indices[0]
    end

    test '.by_filters a SubFrames with Vector' do
      sf = SubFrames.by_filters(@df, [Vector.new(true, false, true)])
      assert_equal_array [[0, 2]], sf.subset_indices
      assert_kind_of Vector, sf.subset_indices[0]
    end
  end

  sub_test_case '.new' do
    test '.new illegal dataframe' do
      assert_raise(SubFramesArgumentError) { SubFrames.new('a', []) }
    end

    test '.new empty dataframe' do
      sf = SubFrames.new(DataFrame.new, [[0, 1, 2]])
      assert_equal [], sf.subset_indices
    end

    setup do
      @df = DataFrame.new(x: [*1..3])
    end

    test '.new empty specifier' do
      assert_equal [], SubFrames.new(@df, []).subset_indices
    end

    test '.new illegal specifier' do
      assert_raise(SubFramesArgumentError) { SubFrames.new(@df, [%w[0 1]]) }
    end

    test '.new a SubFrames with index Array' do
      sf = SubFrames.new(@df, [[0, 2]])
      assert_equal_array [[0, 2]], sf.subset_indices
      assert_kind_of Vector, sf.subset_indices[0]
    end

    test '.new a SubFrames with index Vector' do
      sf = SubFrames.new(@df, [Vector.new(0, 2)])
      assert_equal_array [[0, 2]], sf.subset_indices
      assert_kind_of Vector, sf.subset_indices[0]
    end

    test '.new index out of range' do
      assert_raise(SubFramesArgumentError) { SubFrames.new(@df, [[0, 2, 4]]) }
    end

    test '.new a SubFrames with boolean Array' do
      sf = SubFrames.new(@df, [[true, false, true]])
      assert_equal_array [[0, 2]], sf.subset_indices
      assert_kind_of Vector, sf.subset_indices[0]
    end

    test '.new a SubFrames with boolean Vector' do
      sf = SubFrames.new(@df, [Vector.new(true, false, true)])
      assert_equal_array [[0, 2]], sf.subset_indices
      assert_kind_of Vector, sf.subset_indices[0]
    end
  end

  # Tests for #size, #sizes, #empty? and #universal?
  sub_test_case 'properties' do
    setup do
      @df = DataFrame.new(
        x: [*1..6],
        y: %w[A A B B B C],
        z: [false, true, false, nil, true, false]
      )
    end

    test 'properties of empty SubFrame' do
      empty_subframe = SubFrames.new(@df, [])
      assert_equal 0, empty_subframe.size
      assert_equal [], empty_subframe.sizes
      assert_true empty_subframe.empty?
      assert_false empty_subframe.universal?
    end

    test 'properties of SubFrames' do
      specifier = [[0, 1], [2, 3, 4], [5]]
      sf = SubFrames.new(@df, specifier)
      assert_equal 3, sf.size
      assert_equal [2, 3, 1], sf.sizes
      assert_false sf.empty?
      assert_false sf.universal?
    end

    test 'properties of universal SubFrame' do
      specifier = [[*0..5]]
      universal = SubFrames.new(@df, specifier)
      assert_equal 1, universal.size
      assert_equal [6], universal.sizes
      assert_false universal.empty?
      assert_true universal.universal?
    end
  end

  sub_test_case '#inspect' do
    setup do
      @df = DataFrame.new(
        x: [*1..6],
        y: %w[A A B B B C],
        z: [false, true, false, nil, true, false]
      )
    end

    test '#inspect empty SubFrame' do
      empty_subframe = SubFrames.new(@df, [])
      assert_equal <<~STR, empty_subframe.inspect
        #<RedAmber::SubFrames : #{format('0x%016x', empty_subframe.object_id)}>
        @universal_frame=#<RedAmber::DataFrame : 6 x 3 Vectors, #{format('0x%016x', @df.object_id)}>
        0 SubFrame: [] in size.
      STR
    end

    test '#inspect SubFrames' do
      specifier = [[0, 1], [2, 3, 4], [5]]
      sf = SubFrames.new(@df, specifier)
      assert_equal <<~STR, sf.inspect
        #<RedAmber::SubFrames : #{format('0x%016x', sf.object_id)}>
        @universal_frame=#<RedAmber::DataFrame : 6 x 3 Vectors, #{format('0x%016x', @df.object_id)}>
        3 SubFrames: [2, 3, 1] in sizes.
      STR
    end

    test '#inspect universal SubFrame' do
      specifier = [[*0..5]]
      universal = SubFrames.new(@df, specifier)
      assert_equal <<~STR, universal.inspect
        #<RedAmber::SubFrames : #{format('0x%016x', universal.object_id)}>
        @universal_frame=#<RedAmber::DataFrame : 6 x 3 Vectors, #{format('0x%016x', @df.object_id)}>
        1 SubFrame: [6] in size.
      STR
    end
  end
end
