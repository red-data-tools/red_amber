# frozen_string_literal: true

module RedAmber
  # Columnar data object
  #   @data : holds Arrow::ChunkedArray
  class Vector
    # mix-in
    include VectorFunctions

    # chunked_array may come from column.data
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
      format "#<#{self.class}(:#{type}, size=#{size}):0x%016x>\n#{self}", object_id
    end

    def values
      @data.values
    end
    alias_method :to_a, :values
    alias_method :entries, :values

    def size
      # only defined :length in Arrow?
      @data.length
    end
    alias_method :length, :size
    alias_method :n_rows, :size
    alias_method :nrow, :size

    def type
      @data.value_type.nick.to_sym
    end

    def boolean?
      type == :boolean
    end

    def numeric?
      %i[int8 uint8 int16 uint16 int32 uint32 int64 uint64 float double].member? type
    end

    def string?
      type == :string
    end

    def data_type
      @data.value_type
    end

    # def each() end

    def chunked?
      @data.is_a? Arrow::ChunkedArray
    end

    def n_chunks
      chunked? ? @data.n_chunks : 0
    end

    # def each_chunk() end

    def tally
      values.tally
    end

    def n_nulls
      @data.n_nulls
    end
    alias_method :n_nils, :n_nulls

    def n_nans
      numeric? ? is_nan.to_a.count(true) : 0
    end
  end
end
