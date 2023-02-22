# frozen_string_literal: true

module RedAmber
  # class SubFrames treats a set of subsets of a DataFrame
  # [Experimental feature] Class SubFrames may be removed or be changed in the future.
  class SubFrames
    include Enumerable # may change to use Forwardable.
    include Helper

    using RefineArray
    using RefineArrayLike

    class << self
      # Create SubFrames from a Group.
      #
      # [Experimental feature] this method may be removed or be changed in the future.
      # @param group [Group]
      #   a Group to be used to create SubFrames.
      # @return [SubFrames]
      #   a created SubFrames.
      # @example
      #   dataframe
      #
      #   # =>
      #   #<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
      #   x y        z
      #   <uint8> <string> <boolean>
      #   0       1 A        false
      #   1       2 A        true
      #   2       3 B        false
      #   3       4 B        (nil)
      #   4       5 B        true
      #   5       6 C        false
      #
      #   group = Group.new(dataframe, [:y])
      #   sf = SubFrames.by_group(group)
      #
      #   # =>
      #   #<RedAmber::SubFrames : 0x000000000000fbb8>
      #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fb7c>
      #   3 SubFrames: [2, 3, 1] in sizes.
      #   ---
      #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000000fbcc>
      #           x y        z
      #     <uint8> <string> <boolean>
      #   0       1 A        false
      #   1       2 A        true
      #   ---
      #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fbe0>
      #           x y        z
      #     <uint8> <string> <boolean>
      #   0       3 B        false
      #   1       4 B        (nil)
      #   2       5 B        true
      #   ---
      #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000000fbf4>
      #           x y        z
      #     <uint8> <string> <boolean>
      #   0       6 C        false
      #
      # @since 0.3.1
      #
      def by_group(group)
        SubFrames.new(group.dataframe, group.filters)
      end

      # Create a new SubFrames object from a DataFrame and an array of indices.
      #
      # @api private
      # @note this method doesn't check arguments.
      # @param dataframe [DataFrame]
      #   a source dataframe.
      # @param subset_indices [Array, Array<Vector>]
      #   an Array of numeric indices to create subsets of DataFrame.
      # @return [SubFrames]
      #   a new SubFrames object.
      # @since 0.3.1
      #
      def by_indices(dataframe, subset_indices)
        instance = allocate
        instance.instance_variable_set(:@baseframe, dataframe)
        enum =
          Enumerator.new(subset_indices.size) do |y|
            subset_indices.each do |i|
              y.yield dataframe.take(i)
            end
          end
        instance.instance_variable_set(:@enum, enum)
        instance
      end

      # Create a new SubFrames object from a DataFrame and an array of filters.
      #
      # @api private
      # @note this method doesn't check arguments.
      # @param dataframe [DataFrame]
      #   a source dataframe.
      # @param subset_filters [Array, Array<Vector>]
      #   an Array of booleans to specify subsets of DataFrame.
      #   Each filters must have same length as dataframe.
      # @return [SubFrames]
      #   a new SubFrames object.
      # @since 0.3.1
      #
      def by_filters(dataframe, subset_filters)
        instance = allocate
        instance.instance_variable_set(:@baseframe, dataframe)
        enum =
          Enumerator.new(subset_filters.size) do |y|
            subset_filters.each do |i|
              y.yield dataframe.filter(i)
            end
          end
        instance.instance_variable_set(:@enum, enum)
        instance
      end

      # Create a new SubFrames from an Array of DataFrames.
      #
      # @api private
      # @note dataframes must have same schema.
      # @param dataframes [Array<DataFrame>]
      #   an array of DataFrames which have same schema.
      # @return [SubFrames]
      #   a new SubFrames object.
      # @since 0.3.1
      #
      def by_dataframes(dataframes)
        instance = allocate
        enum =
          Enumerator.new(dataframes.size) do |y|
            dataframes.each do |i|
              y.yield i
            end
          end
        instance.instance_variable_set(:@enum, enum)
        instance.instance_variable_set(:@baseframe, enum.reduce(&:concatenate))
        instance
      end
    end

    # Create a new SubFrames object from a DataFrame and an array of indices or filters.
    #
    # @overload initialize(dataframe, subset_specifier)
    #   Create a new SubFrames object.
    #
    #   @param dataframe [DataFrame]
    #     a source dataframe.
    #   @param subset_specifier [Array<Vector>, Array<array-like>]
    #     an Array of numeric indices or boolean filters
    #     to create subsets of DataFrame.
    #   @return [SubFrames]
    #     new SubFrames.
    #   @example
    #     dataframe
    #
    #     # =>
    #     #<RedAmber::DataFrame : 6 x 3 Vectors, 0x00000000000039e4>
    #       x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       2 A        true
    #     2       3 B        false
    #     3       4 B        (nil)
    #     4       5 B        true
    #     5       6 C        false
    #
    #     SubFrames.new(dataframe, [[0, 2, 3], [4, 1]])
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x0000000000003a34>
    #     @baseframe=#<RedAmber::DataFrame : 5 x 3 Vectors, 0x0000000000003a48>
    #     2 SubFrames: [3, 2] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x0000000000003a5c>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       3 B        false
    #     2       4 B        (nil)
    #     ---
    #     #<RedAmber::DataFrame : 2 x 3 Vectors, 0x0000000000003a70>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       5 B        true
    #     1       2 A        true
    #
    # @overload initialize(dataframe)
    #   Create a new SubFrames object by block.
    #
    #   @param dataframe [DataFrame]
    #     a source dataframe.
    #   @yield [DataFrame]
    #     the block is called with the parameter `dataframe`.
    #   @yieldreturn [Array<numeric_array_like>, Array<boolean_array_like>]
    #     an Array of index or boolean array-likes to create subsets of DataFrame.
    #     All array-likes are responsible to #numeric? or #boolean?.
    #   @return [SubFrames]
    #     a new SubFrames object.
    #   @example
    #     SubFrames.new(dataframe) do |df|
    #       booleans = df[:z]
    #       [booleans, !booleans]
    #     end
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x0000000000003aac>
    #     @baseframe=#<RedAmber::DataFrame : 5 x 3 Vectors, 0x0000000000003ac0>
    #     2 SubFrames: [2, 3] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 2 x 3 Vectors, 0x0000000000003ad4>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       2 A        true
    #     1       5 B        true
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x0000000000003ae8>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       3 B        false
    #     2       6 C        false
    #
    # @since 0.3.1
    #
    def initialize(dataframe, subset_specifier = nil, &block)
      unless dataframe.is_a?(DataFrame)
        raise SubFramesArgumentError, "not a DataFrame: #{dataframe}"
      end

      if block
        unless subset_specifier.nil?
          raise SubFramesArgumentError, 'Must not specify both arguments and block.'
        end

        subset_specifier = yield(dataframe)
      end

      if subset_specifier.nil? || subset_specifier.empty? || dataframe.empty?
        @baseframe = DataFrame.new
        @frames = [@baseframe]
        @enum = @frames.each
      else
        @baseframe = nil
        @enum =
          Enumerator.new(subset_specifier.size) do |yielder|
            subset_specifier.map do |i|
              df =
                if i.numeric?
                  dataframe.take(i)
                elsif i.boolean?
                  dataframe.filter(i)
                else
                  raise SubFramesArgumentError, "illegal type: #{i}"
                end
              yielder.yield df
            end
          end
      end
    end

    # Return concatenated SubFrames as a DataDrame.
    #
    # Once evaluated, memorize it as @baseframe.
    # @return [DataFrame]
    #   a concatenated DataFrame.
    # @since 0.3.1
    #
    def baseframe
      @baseframe ||= reduce(&:concatenate)
    end
    alias_method :concatenate, :baseframe
    alias_method :concat, :baseframe

    # Iterates over sub DataFrames or returns an Enumerator.
    #
    # This method will memorize sub DataFrames and always returns the same object.
    # The Class SubFrames is including Enumerable module.
    # So many methods in Enumerable are available.
    #
    # @overload each
    #   Returns a new Enumerator if no block given.
    #
    #   @return [Enumerator]
    #     Enumerator of each elements.
    #
    # @overload each
    #   When a block given, passes each sub DataFrames to the block.
    #
    #   @yield [DataFrame]
    #     each sub DataFrame.
    #   @yieldparam subframe [DataFrame]
    #     passes sub DataFrame by a block parameter.
    #   @yieldreturn [Object]
    #     evaluated result value from the block.
    #   @return [self]
    #     returns self.
    #
    # @example Returns Enumerator
    #   sf.each
    #
    #   # =>
    #   #<Enumerator: ...>
    #
    # @example `to_a` from Enumerable.
    #   sf.to_a
    #
    #   # =>
    #   [#<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000002a120>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ,
    #    #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000002a134>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ,
    #    #<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000002a148>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #   ]
    #
    # @example Concatenate SubFrames. This example is used in #concatenate.
    #   sf.reduce(&:concatenate)
    #
    #   # =>
    #   #<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000004883c>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   2       3 B        false
    #   3       4 B        (nil)
    #   4       5 B        true
    #   5       6 C        false
    #
    # @since 0.3.1
    #
    def each(&block)
      return enum_for(:each) unless block

      frames.each(&block)
      nil
    end

    # Aggregate SubFrames to create a DataFrame.
    #
    # This method will check if built-in aggregation function is used.
    # @todo Support user-defined aggregation functions.
    #
    # @overload aggregate(group_keys, aggregations)
    #
    #   Aggregate SubFrames for first values of the columns of
    #   `group_keys` and the aggregated results of key-function pairs.
    #
    #   @param group_keys [Symbol, String, Array<Symbol, String>]
    #     group key name(s) to output values.
    #   @param aggregations [Hash<Array<Symbol, String> => Array<:Symbol>>]
    #     a Hash of variable (column) name and
    #     Vector aggregate function name to apply.
    #   @return [DataFrame]
    #     an aggregated DataFrame.
    #   @example
    #     subframes
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x0000000000003980>
    #     @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x0000000000003994>
    #     3 SubFrames: [2, 3, 1] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 2 x 3 Vectors, 0x00000000000039a8>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       2 A        true
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x00000000000039bc>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       3 B        false
    #     1       4 B        (nil)
    #     2       5 B        true
    #     ---
    #     #<RedAmber::DataFrame : 1 x 3 Vectors, 0x00000000000039d0>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       6 C        false
    #
    #     subframes.aggregate(:y, { x: :sum })
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000003b24>
    #       y          sum_x
    #       <string> <uint8>
    #     0 A              3
    #     1 B             12
    #     2 C              6
    #
    # @overload aggregate(group_keys, aggregations)
    #
    #   Aggregate SubFrames for first values of the columns of
    #   `group_keys` and the aggregated results of all combinations
    #   of supplied keys and functions.
    #
    #   @param group_keys [Symbol, String, Array<Symbol, String>]
    #     group key name(s) to output values.
    #   @param aggregations [Array[Array<Symbol, String>, Array<:Symbol>]]
    #     an Array of Array of variable (column) names and
    #     Array of Vector aggregate function names to apply.
    #   @return [DataFrame]
    #     an aggregated DataFrame.
    #   @example
    #     sf.aggregate(:y, [[:x, :z], [:count, :sum]])
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 5 Vectors, 0x000000000000fcbc>
    #       y        count_x count_z   sum_x   sum_z
    #       <string> <uint8> <uint8> <uint8> <uint8>
    #     0 A              2       2       3       1
    #     1 B              3       2      12       1
    #     2 C              1       1       6       0
    #
    # @since 0.3.1
    #
    def aggregate(group_keys, aggregations)
      aggregator =
        case aggregations
        in Hash
          sf = self
          aggregations.map do |key, func|
            unless Vector.aggregate?(func)
              raise SubFramesArgumentError, "not an aggregation function: #{func}"
            end

            ["#{func}_#{key}", sf.each.map { |df| df[key].send(func) }]
          end
        in [Array => keys, Array => functions]
          functions.each do |func|
            unless Vector.aggregate?(func)
              raise SubFramesArgumentError, "not an aggregation function: #{func}"
            end
          end
          sf = self
          functions.product(keys).map do |func, key|
            ["#{func}_#{key}", sf.each.map { |df| df[key].send(func) }]
          end
        else
          raise SubFramesArgumentError, "invalid argument: #{aggregations}"
        end

      if group_keys.empty?
        DataFrame.new(aggregator)
      else
        baseframe
          .pick(group_keys)
          .slice(offset_indices)
          .assign(aggregator)
      end
    end

    # Returns a SubFrames of DataFrames returned by the block.
    #
    # Returns an Enumerator with no block given.
    # @yieldparam dataframe [DataFrame]
    #   gives each element.
    # @yieldreturn [Array<DataFrame>]
    #   the block should return DataFrames with same schema.
    # @return [SubFrames]
    #   a new SubFrames.
    # @example Map as it is.
    #   subframes
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000001359c>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x00000000000135b0>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x00000000000135c4>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x00000000000135d8>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x00000000000135ec>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    #   subframes.map { _1 }
    #
    #   # This will create a new SubFrame and a new baseframe,
    #   # But each element DataFrames are re-used.
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000001e6cc>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000001e6e0>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x00000000000135c4>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x00000000000135d8>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x00000000000135ec>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    # @example Assign a new column.
    #   subframes.map { |df| df.assign(x_plus1: df[:x] + 1) }
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x0000000000040948>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 4 Vectors, 0x000000000004095c>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 4 Vectors, 0x0000000000040970>
    #           x y        z         x_plus1
    #     <uint8> <string> <boolean> <uint8>
    #   0       1 A        false           2
    #   1       2 A        true            3
    #   ---
    #   #<RedAmber::DataFrame : 3 x 4 Vectors, 0x0000000000040984>
    #           x y        z         x_plus1
    #     <uint8> <string> <boolean> <uint8>
    #   0       3 B        false           4
    #   1       4 B        (nil)           5
    #   2       5 B        true            6
    #   ---
    #   #<RedAmber::DataFrame : 1 x 4 Vectors, 0x0000000000040998>
    #           x y        z         x_plus1
    #     <uint8> <string> <boolean> <uint8>
    #   0       6 C        false           7
    #
    # @since 0.3.1
    #
    def map(&block)
      return enum_for(:map) unless block

      self.class.by_dataframes(super(&block))
    end
    alias_method :collect, :map

    # Number of subsets.
    #
    # @return [Integer]
    #   number of subsets in self.
    # @since 0.3.1
    #
    def size
      @size ||= @enum.size
    end

    # Size list of subsets.
    #
    # @return [Array<Integer>]
    #   sizes of sub DataFrames.
    # @since 0.3.1
    #
    def sizes
      @sizes ||= @enum.map(&:size)
    end

    # Indices at the top of each sub DataFrames.
    #
    # @return [Array<Integer>]
    #   indices of offset of each sub DataFrames.
    # @example When `sizes` is [2, 3, 1].
    #   sf.offset_indices # => [0, 2, 5]
    # @since 0.3.1
    #
    def offset_indices
      sum = 0
      sizes.map do |size|
        sum += size
        sum - size
      end
    end

    # Test if subset is empty?.
    #
    # @return [true, false]
    #   true if self is an empty subset.
    # @since 0.3.1
    #
    def empty?
      sizes == [0]
    end

    # Test if self has only one subset and it is comprehensive.
    #
    # @return [true, false]
    #   true if only member of self is equal to universal DataFrame.
    # @since 0.3.1
    #
    def universal?
      size == 1 && @enum.first == baseframe
    end

    # Return string representation of self.
    #
    # @param limit [Integer]
    #   maximum number of DataFrames to show.
    # @return [String]
    #   return string representation of each sub DataFrame.
    # @example
    #   df
    #
    #   # =>
    #   #<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000caa8>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   2       3 B        false
    #   3       4 B        (nil)
    #   4       5 B        true
    #   5       6 C        false
    #
    #   puts SubFrames.new(df, [[0, 1], [2, 3, 4], [5]])
    #
    #   # =>
    #     x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ---
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    # @since 0.3.1
    #
    def to_s(limit: 16)
      _to_s(limit: limit)
    end

    # Return summary information of self.
    #
    # @param limit [Integer]
    #   maximum number of DataFrames to show.
    # @return [String]
    #   return class name, object id, universal DataFrame,
    #   size and subset sizes in a String.
    # @example
    #   df
    #
    #   # =>
    #   #<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000caa8>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   2       3 B        false
    #   3       4 B        (nil)
    #   4       5 B        true
    #   5       6 C        false
    #
    #   SubFrames.new(df, [[0, 1], [2, 3, 4], [5]])
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000000c1fc>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000c170>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000002a120>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000002a134>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000002a148>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    # @since 0.3.1
    #
    def inspect(limit: 16)
      sizes_truncated = (size > limit ? sizes.take(limit) << '...' : sizes).join(', ')
      "#<#{self.class} : #{format('0x%016x', object_id)}>\n" \
        "@baseframe=#<#{baseframe.shape_str(with_id: true)}>\n" \
        "#{size} SubFrame#{pl(size)}: " \
        "[#{sizes_truncated}] in size#{pl(size)}.\n" \
        "---\n#{_to_s(limit: limit, with_id: true)}"
    end

    private

    def frames
      @frames ||= @enum.to_a
    end

    def _to_s(limit: 16, with_id: false)
      a = take(limit).map do |df|
        if with_id
          "#<#{df.shape_str(with_id: with_id)}>\n" \
            "#{df.to_s(head: 2, tail: 2)}"
        else
          df.to_s(head: 2, tail: 2)
        end
      end
      a << "+ #{size - limit} more DataFrame#{pl(size - limit)}.\n" if size > limit
      a.join("---\n")
    end
  end
end
