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
end
