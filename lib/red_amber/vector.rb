# frozen_string_literal: true

module RedAmber
  # Values in variable (columnar) data object
  #   @data : holds Arrow::ChunkedArray
  class Vector
    # mix-in
    include Helper
    include ArrowFunction
    include VectorUpdatable
    include VectorSelectable

    using RefineArrayLike

    # Quicker constructor of Vector.
    #
    def self.create(arrow_array)
      instance = allocate
      instance.instance_variable_set(:@data, arrow_array)
      instance
    end

    # Return true if it is an aggregation function.
    #
    # @param function [Symbol] function name to test.
    # @return [Booleans] true if function is a aggregation function, otherwise false.
    #
    # @example
    #   Vector.aggregate?(:mean) # => true
    #
    #   Vector.aggregate?(:round) # => false
    #
    # @since 0.3.1
    #
    def self.aggregate?(function)
      %i[
        all all? any any? approximate_median count count_distinct count_uniq
        max mean median min min_max product quantile sd std stddev sum
        unbiased_variance var variance
      ].include?(function.to_sym)
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

    def coerce(other)
      [Vector.new(Array(other) * size), self]
    end

    # Spread the return value of an aggregate function as if
    #   it is a element-wise function.
    #
    # @overload propagate(function)
    #   Returns a Vector of same size as self spreading the value from function.
    #
    #   @param function [Symbol] a name of aggregation function for self.
    #     Return value of the function must be a scalar.
    #   @return [Vector] Returns a Vector that is the same size as self
    #     and such that all elements are the same as the result of aggregation `function`.
    #   @example propagate by an aggragation function name
    #     vec = Vector.new(1, 2, 3, 4)
    #     vec.propagate(:mean)
    #     # =>
    #     #<RedAmber::Vector(:double, size=4):0x000000000001985c>
    #     [2.5, 2.5, 2.5, 2.5]
    #
    # @overload propagate
    #   Returns a Vector of same size as self spreading the value from block.
    #
    #   @yield [self] gives self to the block.
    #   @yieldparam self [Vector] self.
    #   @yieldreturn [scalar] a scalar value.
    #   @return [Vector] Returns a Vector that is the same size as self
    #     and such that all elements are the same as the yielded value from the block.
    #   @example propagate by a block
    #     vec.propagate { |v| v.mean.round }
    #     # =>
    #     #<RedAmber::Vector(:uint8, size=4):0x000000000000cb98>                     
    #     [3, 3, 3, 3]
    #
    # @since 0.3.1
    #
    def propagate(function = nil, &block)
      value =
        if block
          raise VectorArgumentError, "can't specify both function and block" if function

          yield self
        else
          function = function&.to_sym
          unless function && respond_to?(function) && Vector.aggregate?(function)
            raise VectorArgumentError, "illegal function: #{function.inspect}"
          end

          send(function)
        end
      Vector.new([value] * size)
    end

    private # =======

    def exec_func_unary(function, options)
      options = nil if options.empty?
      find(function).execute([data], options)
    end

    def exec_func_binary(function, other, options)
      options = nil if options.empty?
      case other
      when Vector
        find(function).execute([data, other.data], options)
      when Arrow::Array, Arrow::ChunkedArray, Arrow::Scalar,
           Array, Numeric, String, TrueClass, FalseClass
        find(function).execute([data, other], options)
      end
    end

    def get_scalar(datum)
      output = datum.value
      case output
      when Arrow::StringScalar then output.to_s
      when Arrow::StructScalar
        output.value.map { |s| s.is_a?(Arrow::StringScalar) ? s.to_s : s.value }
      else
        output.value
      end
    end
  end
end
