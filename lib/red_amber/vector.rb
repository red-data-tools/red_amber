# frozen_string_literal: true

module RedAmber
  # Values in variable (columnar) data object
  #   @data : holds Arrow::ChunkedArray
  class Vector
    # mix-in
    include VectorFunctions
    include VectorUpdatable
    include VectorSelectable
    include Helper

    def initialize(*array)
      @key = nil # default is 'headless'
      if array.empty? || array[0].nil?
        Vector.new([])
      else
        array.flatten!
        case array[0]
        when Vector
          @data = array[0].data
          return
        when Arrow::Array, Arrow::ChunkedArray
          @data = array[0]
          return
        when Range
          @data = Arrow::Array.new(Array(array[0]))
          return
        end
        begin
          @data = Arrow::Array.new(Array(array))
        rescue Error
          raise VectorArgumentError, "Invalid argument: #{array}"
        end
      end
    end

    attr_reader :data
    attr_accessor :key

    def to_s
      @data.to_a.inspect
    end

    def inspect(limit: 80)
      sio = StringIO.new << '['
      to_a.each_with_object(sio).with_index do |(e, s), i|
        next_str = "#{s.size > 1 ? ', ' : ''}#{e.inspect}"
        if (s.size + next_str.size) < limit
          s << next_str
        else
          s << ', ... ' if i < size
          break
        end
      end
      sio << ']'

      format "#<#{self.class}(:#{type}, size=#{size}):0x%016x>\n%s\n", object_id, sio.string
    end

    def values
      @data.values
    end
    alias_method :to_a, :values
    alias_method :entries, :values

    def indices
      (0...size).to_a
    end
    alias_method :indexes, :indices
    alias_method :indeces, :indices

    def to_ary
      to_a
    end

    def size
      # only defined :length in Arrow?
      @data.length
    end
    alias_method :length, :size
    alias_method :n_rows, :size
    alias_method :nrow, :size

    def empty?
      size.zero?
    end

    def type
      @data.value_type.nick.to_sym
    end

    def boolean?
      type_class == Arrow::BooleanDataType
    end

    def numeric?
      type_class < Arrow::NumericDataType
    end

    def float?
      type_class < Arrow::FloatingPointDataType
    end

    def integer?
      type_class < Arrow::IntegerDataType
    end

    def string?
      type_class == Arrow::StringDataType
    end

    def temporal?
      type_class < Arrow::TemporalDataType
    end

    def type_class
      @data.value_data_type.class
    end

    def each
      return enum_for(:each) unless block_given?

      size.times do |i|
        yield data[i]
      end
    end

    def chunked?
      @data.is_a? Arrow::ChunkedArray
    end

    def n_chunks
      chunked? ? @data.n_chunks : 0
    end

    # def each_chunk() end

    def tally
      hash = values.tally
      if (type_class < Arrow::FloatingPointDataType) && is_nan.any
        a = 0
        hash.each do |key, value|
          if key.is_a?(Float) && key.nan?
            hash.delete(key)
            a += value
          end
        end
        hash[Float::NAN] = a
      end
      hash
    end

    def value_counts
      values, counts = Arrow::Function.find(:value_counts).execute([data]).value.fields
      values.zip(counts).to_h
    end

    def n_nulls
      @data.n_nulls
    end
    alias_method :n_nils, :n_nulls

    def n_nans
      numeric? ? is_nan.to_a.count(true) : 0
    end

    def has_nil?
      is_nil.any
    end
  end
end
