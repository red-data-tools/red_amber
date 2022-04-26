# frozen_string_literal: true

module RedAmber
  # Columnar data object
  #   @data : holds Arrow::ChunkedArray
  class Vector
    # mix-in
    include VectorFunctions

    # chunked_array may come from column.data
    # Arrow::ChunkedArray, Arrow::Array, Array or ::Vector
    def initialize(array)
      case array
      when Vector
        @data = array.data
      when Arrow::Array, Arrow::ChunkedArray
        @data = array
      when Array
        @data = Arrow::Array.new(array)
      else
        raise ArgumentError, 'Unknown array in argument'
      end
    end

    attr_reader :data

    def to_s
      @data.to_a.inspect
    end

    def inspect
      format "#<#{self.class}:0x%016x>\n#{self}", object_id
    end

    def values
      @data.values
    end
    alias_method :to_a, :values
    alias_method :entries, :values

    def size
      @data.size
    end
    alias_method :length, :size
    alias_method :n_rows, :size
    alias_method :nrow, :size

    # def each(); end

    def n_nulls
      @data.n_nulls
    end
  end
end
