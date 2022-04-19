# frozen_string_literal: true

module RedAmber
  # Columnar data object
  #   @data : holds Arrow::ChunkedArray
  class Vector
    # chunked_array may come from column.data
    # Arrow::ChunkedArray.new
    def initialize(array)
      @data = array
    end

    attr_reader :data

    def to_s
      @data.to_a.inspect
    end

    def inspect
      format "#<#{self.class}:0x%016x>\n#{self}", object_id
    end
  end
end
