# frozen_string_literal: true

module RedAmber
  # Mix-ins for the class DataFrame
  module DataFrameIndexable
    # Returns row indices (start...(size+start)) in a Vector.
    #
    # @param start [Object]
    #   object which have `#succ` method.
    # @return [Array]
    #   a Vector of row indices.
    # @example When self.size == 5
    #   indices # => Vector[0, 1, 2, 3, 4]
    #
    #   indices(1) # => Vector[1, 2, 3, 4, 5]
    #
    #   indices('a') # => Vector['a', 'b', 'c', 'd', 'e']
    #
    def indices(start = 0)
      Vector.new((start..).take(size))
    end
    alias_method :indexes, :indices

    # Return sorted indexes of self by a Vector.
    #
    # @param sort_keys [Arrow::SortKey]
    #   :key, "key" or "+key" denotes ascending,
    #   "-key" denotes descending order
    # @return [RedAmber::Vector]
    #   sorted indices in Vector
    # @example
    #   df
    #
    #   # =>
    #           x y
    #     <uint8> <string>
    #     0       3 B
    #     1       5 A
    #     2       1 B
    #     3       4 A
    #     4       2 C
    #
    #   df.sort_indices('x')
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=5):0x0000000000003854>
    #   [2, 4, 0, 3, 1]
    #
    def sort_indices(*sort_keys)
      indices = @table.sort_indices(sort_keys.flatten)
      Vector.create(indices)
    end

    # Sort the contents of self.
    #
    # @param sort_keys [Arrow::SortKey]
    #   :key, "key" or "+key" denotes ascending,
    #   "-key" denotes descending order
    # @return [RedAmber::DataFrame]
    #   sorted DataFrame
    # @example Sort by a key
    #   df
    #
    #   # =>
    #           x y
    #     <uint8> <string>
    #     0       3 B
    #     1       5 A
    #     2       1 B
    #     3       4 A
    #     4       2 C
    #
    #   df.sort('y')
    #
    #   # =>
    #   #<RedAmber::DataFrame : 5 x 2 Vectors, 0x000000000000382c>
    #           x y
    #     <uint8> <string>
    #   0       5 A
    #   1       4 A
    #   2       3 B
    #   3       1 B
    #   4       2 C
    #
    # @example Sort by two keys
    #   df.sort('y', 'x')
    #
    #   # =>
    #   #<RedAmber::DataFrame : 5 x 2 Vectors, 0x0000000000003890>
    #           x y
    #     <uint8> <string>
    #   0       4 A
    #   1       5 A
    #   2       1 B
    #   3       3 B
    #   4       2 C
    #
    # @example Sort in descending order
    #   df.sort('-x')
    #
    #   # =>
    #   #<RedAmber::DataFrame : 5 x 2 Vectors, 0x0000000000003840>
    #           x y
    #     <uint8> <string>
    #   0       5 A
    #   1       4 A
    #   2       3 B
    #   3       2 C
    #   4       1 B
    #
    def sort(*sort_keys)
      indices = @table.sort_indices(sort_keys.flatten)

      take(indices)
    end
  end
end
