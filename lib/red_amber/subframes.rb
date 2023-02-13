# frozen_string_literal: true

module RedAmber
  # class SubFrames treats a set of subsets of a DataFrame
  # [Experimental feature] It may be removed or be changed in the future.
  class SubFrames
    include Helper

    using RefineArray
    using RefineArrayLike

    class << self
      # @!macro subframes_initialize
      #   Create a new SubFrames object from a DataFrame and the array of indices.
      #
      #   @param dataframe [DataFrame]
      #     source dataframe.
      #   @param subset_indices [Array<#numeric?>]
      #     an Array of index array-likes to create subsets of DataFrame.
      #     All index array-likes are responsible to #numeric?.
      #   @return [SubFrames]
      #     new SubFrames.
      #   @since 0.3.1

      # @macro subframes_initialize
      # @note Same as SubFrames.new
      #
      def by_indices(dataframe, subset_indices)
        new(dataframe, subset_indices)
      end

      # Create a new SubFrames by the array of filters.
      #
      # @param dataframe [DataFrame]
      #   source dataframe.
      # @param subset_filters [Array<#boolean?>]
      #   an Array of boolean filters to specify subsets of DataFrame.
      #   All boolean filters are responsible to #boolean?.
      # @return [SubFrames]
      #   new SubFrames.
      # @since 0.3.1
      #
      def by_filters(dataframe, subset_filters)
        subset_indices = subset_filters.map do |f|
          dataframe.indices.filter(f)
        end
        new(dataframe, subset_indices)
      end
    end

    # @macro subframes_initialize
    #
    def initialize(dataframe, subset_indices)
      unless dataframe.is_a?(DataFrame)
        raise SubFramesArgumentError, "not a DataFrame: #{dataframe}"
      end

      @universal_frame = dataframe
      @universal_indices = dataframe.indices
      @subset_indices =
        if subset_indices.empty? || dataframe.empty?
          []
        else
          subset_indices.map do |idxs|
            vector =
              if idxs.is_a?(Vector)
                idxs
              else
                Vector.new(idxs)
              end
            raise SubFramesArgumentError, "illegal type: #{idxs}" unless vector.numeric?

            unless vector.is_in(@universal_indices).all?
              raise SubFramesArgumentError, "index out of range: #{vector.to_a}"
            end

            vector
          end
        end
    end

    attr_reader :universal_frame, :subset_indices

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
    # @return [String]
    #   return class name, object id, universal DataFrame,
    #   size and subset sizes in a String.
    # @since 0.3.1
    #
    def inspect
      limit = 16
      sizes_truncated = (size > limit ? sizes.take(limit) << '...' : sizes).join(', ')
      "#<#{self.class} : #{format('0x%016x', object_id)}>\n" \
        "@universal_frame = #<#{@universal_frame.shape_str(with_id: true)}>\n" \
        "#{size} SubFrame#{pl(size)}: " \
        "[#{sizes_truncated}] in size#{pl(size)}.\n"
    end
  end
end
