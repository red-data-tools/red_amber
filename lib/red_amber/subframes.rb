# frozen_string_literal: true

module RedAmber
  # class SubFrames treats a set of subsets of a DataFrame
  # [Experimental feature] Class SubFrames may be removed or be changed in the future.
  class SubFrames
    include Enumerable
    include Helper

    using RefineArray
    using RefineArrayLike

    class << self
      # Create a new SubFrames object from a DataFrame and an array of indices.
      #
      # @api private
      # @note this method doesn't check arguments.
      # @param dataframe [DataFrame]
      #   a source dataframe.
      # @param subset_indices [Array<Vector>]
      #   an Array of numeric Vectors of indices to create subsets of DataFrame.
      # @return [SubFrames]
      #   new SubFrames.
      # @since 0.3.1
      #
      def by_indices(dataframe, subset_indices)
        instance = allocate
        instance.instance_variable_set(:@universal_frame, dataframe)
        instance.instance_variable_set(:@universal_indices, dataframe.indices)
        instance.instance_variable_set(:@subset_indices, subset_indices)
        instance
      end

      # Create a new SubFrames object from a DataFrame and an array of filters.
      #
      # @api private
      # @note this method doesn't check arguments.
      # @param dataframe [DataFrame]
      #   a source dataframe.
      # @param subset_filters [Array<Vector>]
      #   an Array of boolean Vectors to specify subsets of DataFrame.
      # @return [SubFrames]
      #   new SubFrames.
      # @since 0.3.1
      #
      def by_filters(dataframe, subset_filters)
        subset_indices = subset_filters.map do |f|
          dataframe.indices.filter(f)
        end
        by_indices(dataframe, subset_indices)
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
    #     new SubFrames.
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

      @universal_frame = dataframe
      @universal_indices = dataframe.indices
      @subset_indices =
        if subset_specifier.nil? || subset_specifier.empty? || dataframe.empty?
          []
        else
          subset_specifier.map do |i|
            vector =
              if i.boolean?
                @universal_indices.filter(i)
              elsif i.numeric?
                Vector.new(i)
              else
                raise SubFramesArgumentError, "illegal type: #{i}"
              end

            unless vector.is_in(@universal_indices).all?
              raise SubFramesArgumentError, "index out of range: #{vector.to_a}"
            end

            vector
          end
        end
    end

    # The source DataFrame object.
    #
    # @return [DataFrame]
    #   the value of instance variable `universal_frame`.
    #
    attr_reader :universal_frame

    # Index Vectors of subsets.
    #
    # @return [Array]
    #   the value of instance variable `subset_indices`.
    #
    attr_reader :subset_indices

    # Number of subsets.
    #
    # @return [Integer]
    #   number of subsets in self.
    # @since 0.3.1
    #
    def size
      @size ||= @subset_indices.size
    end

    # Size list of subsets.
    #
    # @return [Array<Integer>]
    #   sizes of sub DataFrames.
    # @since 0.3.1
    #
    def sizes
      @sizes ||= @subset_indices.map(&:size)
    end

    # Test if subset is empty?.
    #
    # @return [true, false]
    #   true if self is an empty subset.
    # @since 0.3.1
    #
    def empty?
      @subset_indices.empty?
    end

    # Test if self has only one subset and it is comprehensive.
    #
    # @return [true, false]
    #   true if only member of self is equal to universal DataFrame.
    # @since 0.3.1
    #
    def universal?
      size == 1 && (@subset_indices[0] == @universal_indices).all?
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
    #   @universal_frame=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000c170>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #           x y        z
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
    def inspect(limit: 16)
      sizes_truncated = (size > limit ? sizes.take(limit) << '...' : sizes).join(', ')
      "#<#{self.class} : #{format('0x%016x', object_id)}>\n" \
        "@universal_frame=#<#{@universal_frame.shape_str(with_id: true)}>\n" \
        "#{size} SubFrame#{pl(size)}: " \
        "[#{sizes_truncated}] in size#{pl(size)}.\n" \
        "---\n#{_to_s(limit: limit)}"
      # "---\n#{_to_s(limit: limit, with_id: true)}"
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

    # Iterates over sub DataFrames or returns an Enumerator.
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
    # @since 0.3.1
    #
    def each
      return enum_for(:each) unless block_given?

      @subset_indices.each do |i|
        yield @universal_frame.take(i.data)
      end
      self
    end

    private

    # def _to_s(limit: 16, with_id: false)
    def _to_s(limit: 16)
      a = take(limit).map do |df|
        # if with_id
        #   "#<#{df.shape_str(with_id: with_id)}>\n" \
        #     "#{df.to_s(head: 2, tail: 2)}"
        # else
        df.to_s(head: 2, tail: 2)
        # end
      end
      a << "+ #{size - limit} more DataFrame#{pl(size - limit)}.\n" if size > limit
      a.join("---\n")
    end
  end
end
