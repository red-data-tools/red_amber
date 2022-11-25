# frozen_string_literal: true

module RedAmber
  # Add additional capabilities to Hash
  module RefineHash
    refine Hash do
      # Convert self to an Arrow::Table
      def to_arrow
        Arrow::Table.new(self)
      end
    end
  end

  # Add additional capabilities to Array-like classes
  module RefineArrayLike
    refine Array do
      def to_arrow_array
        Arrow::Array.new(self)
      end
    end

    refine Range do
      def to_arrow_array
        Arrow::Array.new(Array(self))
      end
    end

    refine Arrow::Array do
      def to_arrow_array
        self
      end
    end

    refine Arrow::ChunkedArray do
      def to_arrow_array
        self
      end
    end
  end

  # Add additional capabilities to Arrow::Table
  module RefineArrowTable
    refine Arrow::Table do
      def keys
        columns.map(&:name)
      end

      def key?(key)
        keys.include?(key)
      end
    end
  end

  # Add additional capabilities to Array
  module RefineArray
    refine Array do
      def integers?
        all? { |e| e.is_a?(Integer) } # rubocop:disable Performance/RedundantEqualityComparisonBlock
      end

      def booleans?
        all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
      end

      def symbols?
        all? { |e| e.is_a?(Symbol) } # rubocop:disable Performance/RedundantEqualityComparisonBlock
      end

      def strings?
        all? { |e| e.is_a?(String) } # rubocop:disable Performance/RedundantEqualityComparisonBlock
      end

      def symbols_or_strings?
        all? { |e| e.is_a?(Symbol) || e.is_a?(String) }
      end

      # convert booleans to indices
      def booleans_to_indices
        (0...size).select.with_index { |_, i| self[i] }
      end

      # select elements by booleans
      def select_by_booleans(booleans)
        select.with_index { |_, i| booleans[i] }
      end

      # reject elements by booleans
      def reject_by_booleans(booleans)
        reject.with_index { |_, i| booleans[i] }
      end

      # reject elements by indices
      # notice: order by indices is not considered.
      def reject_by_indices(indices)
        reject.with_index { |_, i| indices.include?(i) || indices.include?(i - size) }
      end
    end
  end
end
