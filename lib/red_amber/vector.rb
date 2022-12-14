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

    using RefineArrayLike

    # Quicker constructor of Vector.
    #
    def self.create(arrow_array)
      instance = allocate
      instance.instance_variable_set(:@data, arrow_array)
      instance
    end

    # Create a Vector.
    #
    # @note default is headless Vector and '@key == nil'
    def initialize(*array)
      @data =
        case array
        in [Vector => v]
          v.data
        in [Range => r]
          Arrow::Array.new(Array(r))
        in [Arrow::Array | Arrow::ChunkedArray]
          array[0]
        in [arrow_array_like] if arrow_array_like.respond_to?(:to_arrow_array)
          arrow_array_like.to_arrow_array
        else
          Arrow::Array.new(array.flatten)
        end
    end

    attr_reader :data
    alias_method :to_arrow_array, :data

    attr_accessor :key

    def to_s
      @data.to_a.inspect
    end

    def inspect(limit: 80)
      if ENV.fetch('RED_AMBER_OUTPUT_MODE', 'Table').casecmp('MINIMUM').zero?
        # Better performance than `.upcase == 'MINIMUM'`
        "#{self.class}(:#{type}, size=#{size})"
      else
        sio = StringIO.new << '['
        each.with_index do |e, i|
          next_str = "#{sio.size > 1 ? ', ' : ''}#{e.inspect}"
          if (sio.size + next_str.size) < limit
            sio << next_str
          else
            sio << ', ... ' if i < size
            break
          end
        end
        sio << ']'

        format "#<#{self.class}(:#{type}, size=#{size}):0x%016x>\n%s\n",
               object_id, sio.string
      end
    end

    def to_ary
      @data.values
    end

    alias_method :to_a, :to_ary
    alias_method :values, :to_ary
    alias_method :entries, :to_ary

    def indices
      (0...size).to_a
    end

    alias_method :indexes, :indices
    alias_method :indeces, :indices

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
      list? ? :list : @data.value_type.nick.to_sym
    end

    def boolean?
      @data.boolean?
    end

    def numeric?
      @data.numeric?
    end

    def float?
      @data.float?
    end

    def integer?
      @data.integer?
    end

    def string?
      @data.string?
    end

    def dictionary?
      @data.dictionary?
    end

    def temporal?
      @data.temporal?
    end

    def list?
      @data.list?
    end

    def type_class
      @data.type_class
    end

    def each
      return enum_for(:each) unless block_given?

      size.times do |i|
        yield data[i]
      end
    end

    def map(&block)
      return enum_for(:map) unless block

      Vector.new(to_a.map(&block))
    end
    alias_method :collect, :map

    # undocumented
    def chunked?
      @data.is_a? Arrow::ChunkedArray
    end

    # undocumented
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
