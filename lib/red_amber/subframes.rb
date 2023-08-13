# frozen_string_literal: true

module RedAmber
  # class SubFrames treats subsets of a DataFrame
  # [Experimental feature] Class SubFrames may be removed or be changed in the future.
  class SubFrames
    include Enumerable # may change to use Forwardable.
    include Helper

    using RefineArray
    using RefineArrayLike

    # Entity to select sub-dataframes
    class Selectors
      attr_reader :selectors, :size, :sizes

      def initialize(selectors)
        @selectors = selectors
        @size = selectors.size
        @sizes = []
      end

      # Generic iterator method
      def each
        @selectors.each
      end
    end

    # Boolean selectors of sub-dataframes
    class Filters < Selectors
      # Return sizes of filter
      # @return [Array<Integer>]
      #   sizes of each sub dataframes.
      #   Counts true for each filter.
      def sizes
        @sizes = @selectors.map { |s| s.to_a.count { _1 } } # rubocop:disable Performance/Size
      end
    end

    # Index selectors of sub-dataframes
    class Indices < Selectors
      # Return sizes of selector indices.
      # @return [Array<Integer>]
      #   sizes of each sub dataframes.
      def sizes
        @sizes = @selectors.map(&:size)
      end
    end

    private_constant :Selectors, :Filters, :Indices

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
      # @since 0.4.0
      #
      def by_group(group)
        SubFrames.by_filters(group.dataframe, group.filters)
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
      # @since 0.4.0
      #
      def by_indices(dataframe, subset_indices)
        instance = allocate
        instance.instance_variable_set(:@baseframe, dataframe)
        instance.instance_variable_set(:@selectors, Indices.new(subset_indices))
        instance.instance_variable_set(:@frames, [])
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
      # @since 0.4.0
      #
      def by_filters(dataframe, subset_filters)
        instance = allocate
        instance.instance_variable_set(:@baseframe, dataframe)
        instance.instance_variable_set(:@selectors, Filters.new(subset_filters))
        instance.instance_variable_set(:@frames, [])
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
      # @since 0.4.0
      #
      def by_dataframes(dataframes)
        instance = allocate
        case Array(dataframes)
        when [] || [nil]
          instance.instance_variable_set(:@baseframe, DataFrame.new)
          instance.instance_variable_set(:@selectors, [])
          instance.instance_variable_set(:@frames, [])
        else
          instance.instance_variable_set(:@baseframe, nil)
          instance.instance_variable_set(:@selectors, nil)
          instance.instance_variable_set(:@frames, dataframes)
        end
        instance
      end

      private

      # This method upgrades a iterating method from Enumerable to return SubFrames.

      # @!macro [attach] define_subframable_method
      #
      #   [Returns SubFrames] Use `#each.$1` if you want to get DataFrames by Array.
      #   Returns an Enumerator with no block given.
      #   @yieldparam dataframe [DataFrame]
      #     gives each element.
      #   @yieldreturn [Array<DataFrame>]
      #     the block should return DataFrames with same schema.
      #   @return [SubFrames]
      #     a new SubFrames.
      #
      # @since 0.4.0
      #
      def define_subframable_method(method)
        define_method(method) do |&block|
          return enum_for(:each) { size } unless block # rubocop:disable Lint/ToEnumArguments

          SubFrames.by_dataframes(super(&block))
        end
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
    #     # --- This object is used as common source in this class ---
    #     subframes = SubFrames.new(dataframe, [[0 ,1], [2, 3, 4], [5]])
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x000000000000cf6c>
    #     @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000cf80>
    #     3 SubFrames: [2, 3, 1] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000000cf94>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       2 A        true
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000cfa8>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       3 B        false
    #     1       4 B        (nil)
    #     2       5 B        true
    #     ---
    #     #<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000000cfbc>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       6 C        false
    #
    # @overload initialize(dataframe)
    #   Create a new SubFrames object by block.
    #
    #   @param dataframe [DataFrame]
    #     a source dataframe.
    #   @yieldparam dataframe [DataFrame]
    #     the block is called with `dataframe`.
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
    # @since 0.4.0
    #
    def initialize(dataframe, selectors = nil, &block)
      unless dataframe.is_a?(DataFrame)
        raise SubFramesArgumentError, "not a DataFrame: #{dataframe}"
      end

      if block
        unless selectors.nil?
          raise SubFramesArgumentError, 'Must not specify both arguments and block.'
        end

        selectors = yield(dataframe)
      end

      if dataframe.empty? || selectors.nil? || selectors.size.zero? # rubocop:disable Style/ZeroLengthPredicate
        @baseframe = DataFrame.new
        @selectors = Selectors.new([])
      else
        @baseframe = dataframe
        @selectors =
          if selectors.first.boolean?
            Filters.new(selectors)
          elsif selectors.first.numeric?
            Indices.new(selectors)
          else
            raise SubFramesArgumentError, "illegal type: #{selectors}"
          end
      end
      @frames = []
    end

    # Return concatenated SubFrames as a DataFrame.
    #
    # Once evaluated, memorize it as @baseframe.
    # @return [DataFrame]
    #   a concatenated DataFrame.
    # @since 0.4.0
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
    #   @yieldparam subframe [DataFrame]
    #     passes sub DataFrame by a block parameter.
    #   @yieldreturn [Object]
    #     evaluated result value from the block.
    #   @return [self]
    #     returns self.
    #
    # @example Returns Enumerator
    #   subframes.each
    #
    #   # =>
    #   #<Enumerator: ...>
    #
    # @example `to_a` from Enumerable.
    #   subframes.to_a
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
    #   subframes.reduce(&:concatenate)
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
    # @since 0.4.0
    #
    def each(&block)
      return enum_for(__method__) { size } unless block

      if @selectors
        @selectors.each.with_index do |selector, i|
          if i < @frames.size
            yield @frames[i]
          else
            frame = get_subframe(selector)
            @frames << frame
            yield frame
          end
        end
      else
        @frames.each(&block)
      end
      nil
    end

    # Aggregate SubFrames to create a DataFrame.
    #
    # This method creates a DataFrame with one row corresponding to one sub dataframe.
    # @note This method does not check if aggregation function is used.
    #
    # @overload aggregate(keys)
    #
    #   Aggregate SubFrames creating DataFrame with label `keys` and
    #   its column values by block.
    #
    #   @param keys [Symbol, Array<Symbol>]
    #     a key or keys of result. Key names may be renamed to new label.
    #   @yieldparam dataframe [DataFrame]
    #     passes each dataframe in self to the block. Block is called by instance_eval,
    #     so inside of the block is the context of passed dataframe.
    #   @yieldreturn [Array]
    #     aggregated values from the columns of passed dataframe.
    #   @return [DataFrame]
    #     created DataFrame.
    #   @example Aggregate by key labels in arguments and values from block.
    #     subframes.aggregate(:y, :sum_x) { [y.one, x.sum] }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000003b24>
    #       y          sum_x
    #       <string> <uint8>
    #     0 A              3
    #     1 B             12
    #     2 C              6
    #
    #   @example Aggregate by key labels in an Array and values from block.
    #     subframes.aggregate([:y, :sum_x]) { [y.one, x.sum] }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000003b24>
    #       y          sum_x
    #       <string> <uint8>
    #     0 A              3
    #     1 B             12
    #     2 C              6
    #
    # @overload aggregate
    #
    #   Aggregate SubFrames creating DataFrame with pairs of key and aggregated values
    #   in Hash from the block.
    #
    #   @yieldparam dataframe [DataFrame]
    #     passes each dataframe in self to the block. Block is called by instance_eval,
    #     so inside of the block is the context of passed dataframe.
    #   @yieldreturn [Hash<key => aggregated_value>]
    #     pairs of key name and aggregated values from the columns of passed dataframe.
    #     Key names may be renamed to new label in the result.
    #   @return [DataFrame]
    #     created DataFrame.
    #   @example Aggregate by key and value pairs from block.
    #     subframes.aggregate do
    #       { y: y.one, sum_x: x.sum }
    #     end
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000003b24>
    #       y          sum_x
    #       <string> <uint8>
    #     0 A              3
    #     1 B             12
    #     2 C              6
    #
    # @overload aggregate
    #
    #   Aggregate SubFrames creating DataFrame with an Array of key and aggregated value
    #   from the block.
    #
    #   @yieldparam dataframe [DataFrame]
    #     passes each dataframe in self to the block. Block is called by instance_eval,
    #     so inside of the block is the context of passed dataframe.
    #   @yieldreturn [Array<key, aggregated_value>]
    #     pairs of key name and aggregated values from the columns of passed dataframe.
    #     Key names may be renamed to new label in the result.
    #   @return [DataFrame]
    #     created DataFrame.
    #   @example Aggregate by key and value arrays from block.
    #     subframes.aggregate do
    #       [[:y, y.first], [:sum_x, x.sum]]
    #     end
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
    #   `group_keys` and the aggregated results of key-function pairs.
    #   [Experimental] This API may be changed in the future.
    #
    #   @param group_keys [Symbol, String, Array<Symbol, String>]
    #     group key name(s) to output values.
    #   @param aggregations [Hash<Array<Symbol, String> => Array<:Symbol>>]
    #     a Hash of variable (column) name and
    #     Vector aggregate function name to apply.
    #   @return [DataFrame]
    #     an aggregated DataFrame.
    #   @example Aggregate with a group key and key function pairs by a Hash.
    #     subframes.aggregate(:y, { x: :sum, z: :count })
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000003b24>
    #       y          sum_x count_z
    #       <string> <uint8> <uint8>
    #     0 A              3       2
    #     1 B             12       2
    #     2 C              6       1
    #
    # @overload aggregate(group_keys, aggregations)
    #
    #   Aggregate SubFrames for first values of the columns of
    #   `group_keys` and the aggregated results of all combinations
    #   of supplied keys and functions.
    #   [Experimental] This API may be changed in the future.
    #
    #   @param group_keys [Symbol, String, Array<Symbol, String>]
    #     group key name(s) to output values.
    #   @param aggregations [Array[Array<Symbol, String>, Array<:Symbol>]]
    #     an Array of Array of variable (column) names and
    #     Array of Vector aggregate function names to apply.
    #   @return [DataFrame]
    #     an aggregated DataFrame.
    #   @example Aggregate with group keys and keys and functions by an Array.
    #     sf.aggregate(:y, [[:x, :z], [:count, :sum]])
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 5 Vectors, 0x000000000000fcbc>
    #       y        count_x   sum_x count_z   sum_z
    #       <string> <uint8> <uint8> <uint8> <uint8>
    #     0 A              2       3       2       1
    #     1 B              3      12       2       1
    #     2 C              1       6       1       0
    #
    # @since 0.4.0
    #
    def aggregate(*args, &block)
      aggregator =
        if block
          if args.empty?
            # aggregate { {key => value} or [[key, value], ...] }
            each_with_object(Hash.new { |h, k| h[k] = [] }) do |df, hash|
              df.instance_eval(&block).to_h.each do |k, v|
                hash[k] << v
              end
            end
          else
            # aggregate(keys) { values }
            values = each.map { |df| Array(df.instance_eval(&block)) }.transpose
            args.flatten.zip(values)
          end
        else
          # These functions may be removed in the future.
          case args
          in [group_keys1, Hash => h]
            # aggregate(group_keys, { key => func })
            ary = Array(group_keys1).map { |key| [:first, key] }
            ary.concat(h.to_a.map { [_2, _1] }) # rubocop:disable Style/NumberedParametersLimit
          in [group_keys2, [Array => keys, Array => funcs]]
            # aggregate(group_keys, [keys, funcs])
            ary = Array(group_keys2).map { |key| [:first, key] }
            ary.concat(funcs.product(keys))
          else
            raise SubFramesArgumentError, "invalid argument: #{args}"
          end
          sf = self
          ary.map do |func, key|
            label = func == :first ? key : "#{func}_#{key}"
            [label, sf.each.map { |df| df[key].send(func) }]
          end
        end
      DataFrame.new(aggregator)
    end

    # Returns a SubFrames containing DataFrames returned by the block.
    #
    # @example Map as it is.
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
    # @since 0.4.0
    #
    define_subframable_method :map
    alias_method :collect, :map

    # Update existing column(s) or create new columns(s) for each DataFrames in self.
    #
    # Column values are updated by an oveloaded common operation.
    #
    # @overload assign(key)
    #   Assign a column by argument and block.
    #
    #   @param key [Symbol, String]
    #     a key of column to assign.
    #   @yieldparam dataframe [DataFrame]
    #     gives overloaded dataframe in self to the block.
    #   @yieldreturn [Vector, Array, Arrow::Array]
    #     an updated column value which are overloaded.
    #   @return [SubFrames]
    #     a new SubFrames object with updated DataFrames.
    #   @example
    #     subframes.assign(:x_plus1) { x + 1 }
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x000000000000c3a0>
    #     @baseframe=#<RedAmber::DataFrame : 6 x 4 Vectors, 0x000000000000c3b4>
    #     3 SubFrames: [2, 3, 1] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 2 x 4 Vectors, 0x000000000000c3c8>
    #             x y        z         x_plus1
    #       <uint8> <string> <boolean> <uint8>
    #     0       1 A        false           2
    #     1       2 A        true            3
    #     ---
    #     #<RedAmber::DataFrame : 3 x 4 Vectors, 0x000000000000c3dc>
    #             x y        z         x_plus1
    #       <uint8> <string> <boolean> <uint8>
    #     0       3 B        false           4
    #     1       4 B        (nil)           5
    #     2       5 B        true            6
    #     ---
    #     #<RedAmber::DataFrame : 1 x 4 Vectors, 0x000000000000c3f0>
    #             x y        z         x_plus1
    #       <uint8> <string> <boolean> <uint8>
    #     0       6 C        false           7
    #
    # @overload assign(keys)
    #   Assign columns by arguments and block.
    #
    #   @param keys [Array<Symbol, String>]
    #     keys of columns to assign.
    #   @yieldparam dataframe [DataFrame]
    #     gives overloaded dataframes in self to the block.
    #   @yieldreturn [Array<Vector, Array, Arrow::Array>]
    #     an updated column values which are overloaded.
    #   @return [SubFrames]
    #     a new SubFrames object with updated DataFrames.
    #   @example
    #     subframes.assign(:sum_x, :frac_x) do
    #       group_sum = x.sum
    #       [[group_sum] * size, x / group_sum.to_f]
    #     end
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x000000000000fce4>
    #     @baseframe=#<RedAmber::DataFrame : 6 x 5 Vectors, 0x000000000000fcf8>
    #     3 SubFrames: [2, 3, 1] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 2 x 5 Vectors, 0x000000000000fd0c>
    #             x y        z           sum_x   frac_x
    #       <uint8> <string> <boolean> <uint8> <double>
    #     0       1 A        false           3     0.33
    #     1       2 A        true            3     0.67
    #     ---
    #     #<RedAmber::DataFrame : 3 x 5 Vectors, 0x000000000000fd20>
    #             x y        z           sum_x   frac_x
    #       <uint8> <string> <boolean> <uint8> <double>
    #     0       3 B        false          12     0.25
    #     1       4 B        (nil)          12     0.33
    #     2       5 B        true           12     0.42
    #     ---
    #     #<RedAmber::DataFrame : 1 x 5 Vectors, 0x000000000000fd34>
    #             x y        z           sum_x   frac_x
    #       <uint8> <string> <boolean> <uint8> <double>
    #     0       6 C        false           6      1.0
    #
    # @overload assign
    #   Assign column(s) by block.
    #
    #   @yieldparam dataframe [DataFrame]
    #     gives overloaded dataframes in self to the block.
    #   @yieldreturn [Hash, Array]
    #     pairs of keys and column values which are overloaded.
    #   @return [SubFrames]
    #     a new SubFrames object with updated DataFrames.
    #   @example Compute 'x * z' when (true, not_true) = (1, 0) in z
    #     subframes.assign do
    #       { 'x*z': x * z.if_else(1, 0) }
    #     end
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x000000000000fd98>
    #     @baseframe=#<RedAmber::DataFrame : 6 x 4 Vectors, 0x000000000000fdac>
    #     3 SubFrames: [2, 3, 1] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 2 x 4 Vectors, 0x000000000000fdc0>
    #             x y        z             x*z
    #       <uint8> <string> <boolean> <uint8>
    #     0       1 A        false           0
    #     1       2 A        true            2
    #     ---
    #     #<RedAmber::DataFrame : 3 x 4 Vectors, 0x000000000000fdd4>
    #             x y        z             x*z
    #       <uint8> <string> <boolean> <uint8>
    #     0       3 B        false           0
    #     1       4 B        (nil)       (nil)
    #     2       5 B        true            5
    #     ---
    #     #<RedAmber::DataFrame : 1 x 4 Vectors, 0x000000000000fde8>
    #             x y        z             x*z
    #       <uint8> <string> <boolean> <uint8>
    #     0       6 C        false           0
    #
    # @since 0.4.0
    #
    def assign(...)
      map { |df| df.assign(...) }
    end

    # Returns a SubFrames containing DataFrames selected by the block.
    #
    # With a block given, calls the block with successive DataFrames;
    # returns a SubFrames of those DataFrames for
    # which the block returns a truthy value.
    #
    # @example Select all.
    #   subframes.select { true }
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x0000000000003a84>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x0000000000003a98>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x0000000000003a0c>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x0000000000003a20>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x0000000000003a34>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    # @example Select nothing.
    #   subframes.select { false }
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x00000000000238c0>
    #   @baseframe=#<RedAmber::DataFrame : (empty), 0x00000000000238d4>
    #   0 SubFrame: [] in size.
    #   ---
    #
    # @example Select if Vector `:z` has any true.
    #   subframes.select { |df| df[:z].any? }
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000000fba4>
    #   @baseframe=#<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fbb8>
    #   2 SubFrames: [2, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x0000000000003a0c>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x0000000000003a20>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #
    # @since 0.4.0
    #
    define_subframable_method :select
    alias_method :filter, :select
    alias_method :find_all, :select

    # Returns a SubFrames containing DataFrames rejected by the block.
    #
    # With a block given, calls the block with successive DataFrames;
    # returns a SubFrames of those DataFrames for
    # which the block returns nil or false.
    # @example Reject all.
    #   subframes.reject { true }
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x00000000000238c0>
    #   @baseframe=#<RedAmber::DataFrame : (empty), 0x00000000000238d4>
    #   0 SubFrame: [] in size.
    #   ---
    #
    # @example Reject nothing.
    #   subframes.reject { false }
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x0000000000003a84>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x0000000000003a98>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x0000000000003a0c>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x0000000000003a20>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x0000000000003a34>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    # @example Reject if Vector `:z` has any true.
    #   subframes.reject { |df| df[:z].any? }
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x0000000000038d74>
    #   @baseframe=#<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000001ad10>
    #   1 SubFrame: [1] in size.
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000001ad10>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    # @since 0.4.0
    #
    define_subframable_method :reject

    # Returns a SubFrames containing truthy DataFrames returned by the block.
    #
    # With a block given, calls the block with successive DataFrames;
    # returns a SubFrames of those DataFrames for
    # which the block returns nil or false.
    # @example Filter for size is larger than 1 and append number to column 'y'.
    #   subframes.filter_map do |df|
    #     if df.size > 1
    #       df.assign(:y) do
    #         y.merge(indices('1'), sep: '')
    #       end
    #     end
    #   end
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000001da88>
    #   @baseframe=#<RedAmber::DataFrame : 5 x 3 Vectors, 0x000000000001da9c>
    #   2 SubFrames: [2, 3] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000001dab0>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A1       false
    #   1       2 A2       true
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000001dac4>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B1       false
    #   1       4 B2       (nil)
    #   2       5 B3       true
    #
    # @since 0.4.0
    #
    define_subframable_method :filter_map

    # Return 0...num sub-dataframes in self.
    #
    # @param num [Integer, Float]
    #   num of sub-dataframes to pick up. `num`` must be positive or zero.
    # @return [SubFrames]
    #   A new SubFrames.
    #   If n == 0, it returns empty SubFrames.
    #   If n >= size, it returns self.
    # @since 0.4.2
    #
    def take(num)
      if num.zero?
        SubFrames.new(DataFrame.new, [])
      elsif num >= size
        self
      else
        SubFrames.by_dataframes(frames(num))
      end
    end

    # Number of subsets.
    #
    # @return [Integer]
    #   number of subsets in self.
    # @since 0.4.0
    #
    def size
      @size ||=
        if @selectors
          @selectors.size
        else
          @frames.size
        end
    end

    # Size list of subsets.
    #
    # @return [Array<Integer>]
    #   sizes of sub DataFrames.
    # @since 0.4.0
    #
    def sizes
      @sizes ||=
        if @selectors
          @selectors.sizes
        else
          @frames.map(&:size)
        end
    end

    # Indices at the top of each sub DataFrames.
    #
    # @return [Array<Integer>]
    #   indices of offset of each sub DataFrames.
    # @example When `sizes` is [2, 3, 1].
    #   subframes.offset_indices # => [0, 2, 5]
    # @since 0.4.0
    #
    def offset_indices
      case @selectors
      when Filters
        @selectors.selectors.map do |selector|
          selector.each.with_index.find { |x, _| x }[1]
        end
      else # Indices, nil
        sum = 0
        sizes.map do |size|
          sum += size
          sum - size
        end
      end
    end

    # Test if subset is empty?.
    #
    # @return [true, false]
    #   true if self is an empty subset.
    # @since 0.4.0
    #
    def empty?
      size.zero?
    end

    # Test if self has only one subset and it is comprehensive.
    #
    # @return [true, false]
    #   true if the only member of self is equal to universal DataFrame.
    # @since 0.4.0
    #
    def universal?
      size == 1 && first == @baseframe
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
    # @since 0.4.0
    #
    def to_s(limit: 5)
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
    # @since 0.4.0
    #
    def inspect(limit: 5)
      shape =
        if @baseframe.nil?
          '(Not prepared)'
        else
          baseframe.shape_str(with_id: true)
        end
      sizes_truncated = (size > limit ? sizes.take(limit) << '...' : sizes).join(', ')
      "#<#{self.class} : #{format('0x%016x', object_id)}>\n" \
        "@baseframe=#<#{shape}>\n" \
        "#{size} SubFrame#{pl(size)}: " \
        "[#{sizes_truncated}] in size#{pl(size)}.\n" \
        "---\n#{_to_s(limit: limit, with_id: true)}"
    end

    # Return an Array of sub DataFrames
    #
    # @overload frames
    #   Returns all sub dataframes.
    #
    #   @return [Array<DataFrame>]
    #     sub DataFrames.
    #
    # @overload frames(n_frames)
    #   Returns partial sub dataframes.
    #
    #   @param n_frames [Integer]
    #     num of dataframes to retrieve.
    #   @return [Array<DataFrame>]
    #     sub DataFrames.
    #
    # @since 0.4.2
    #
    def frames(n_frames = nil)
      n_frames = size if n_frames.nil?

      if @frames.size < n_frames
        @frames = each.take(n_frames)
      else
        @frames.take(n_frames)
      end
    end

    private

    # Get sub dataframe specified by 'selector'
    def get_subframe(selector)
      df =
        case @selectors
        when Filters
          @baseframe.filter(selector)
        when Indices
          @baseframe.take(selector)
        end
      DataFrame.new_dataframe_with_schema(@baseframe, df)
    end

    # Subcontractor of to_s
    def _to_s(limit: 5, with_id: false)
      a = each.take(limit).map do |df|
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
