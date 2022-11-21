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
    end
  end

  # Add additional capabilities to Array
  module RefineArray
    refine Array do
      def integers?
        all?(Integer)
      end

      def booleans?
        all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
      end

      def symbols?
        all?(Symbol)
      end

      def symbols_or_strings?
        all? { |e| e.is_a?(String) || e.is_a?(Symbol) }
      end

      # Convert booleans to indices
      def to_indices
        (0...size).select.with_index { |_, i| self[i] }
      end

      # take elements by indices
      def take_by(indices)
        indices.map { |i| self[i] }
      end

      # filter elements by booleans
      def filter_by(booleans)
        select.with_index { |_, i| booleans[i] }
      end
    end
  end
end
