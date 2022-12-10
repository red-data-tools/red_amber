# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-in for class Vector
  #   Functions to select some data.
  module VectorSelectable
    using RefineArray
    using RefineArrayLike

    def drop_nil
      datum = find(:drop_null).execute([data])
      Vector.create(datum.value)
    end

    # vector version of selection by indices
    # TODO: support for the option `boundscheck: true``
    def take(*indices)
      case indices
      in [Vector => v] if v.numeric?
        Vector.create(take_by_vector(v))
      in []
        Vector.new
      else
        v = Vector.new(indices.flatten)
        raise VectorArgumentError, "argument must be a integers: #{indices}" unless v.numeric?

        Vector.create(take_by_vector(v))
      end
    end

    # TODO: support for the option `null_selection_behavior: :drop``
    def filter(*booleans, &block)
      if block
        raise VectorArgumentError, 'Must not specify both arguments and block.' unless booleans.empty?

        booleans = [yield]
      end

      case booleans
      in [Vector => v]
        raise VectorTypeError, 'Argument is not a boolean.' unless v.boolean?

        Vector.create(filter_by_array(v.data))
      in [Arrow::BooleanArray => ba]
        Vector.create(filter_by_array(ba))
      in []
        Vector.new
      else
        booleans.flatten!
        a = Arrow::Array.new(booleans)
        if a.boolean?
          Vector.create(filter_by_array(a))
        elsif booleans.compact.empty? # [nil, nil] becomes string array
          Vector.new
        else
          raise VectorTypeError, "Argument is not a boolean: #{booleans}"
        end
      end
    end
    alias_method :select, :filter
    alias_method :find_all, :filter

    # @param indices
    # @param booleans
    def [](*args)
      array =
        case args
        in [Vector => v]
          return scalar_or_array(take_by_vector(v)) if v.numeric?
          return scalar_or_array(filter_by_array(v.data)) if v.boolean?

          raise VectorTypeError, "Argument must be numeric or boolean: #{args}"
        in [Arrow::BooleanArray => ba]
          return scalar_or_array(filter_by_array(ba))
        in []
          return nil
        in [Arrow::Array => arrow_array]
          arrow_array
        in [Range => r]
          Arrow::Array.new(parse_range(r, size))
        else
          Arrow::Array.new(args.flatten)
        end

      return scalar_or_array(filter_by_array(array)) if array.boolean?

      vector = Vector.new(array)
      return scalar_or_array(take_by_vector(vector)) if vector.numeric?

      raise VectorArgumentError, "Invalid argument: #{args}"
    end

    # @param values [Array, Arrow::Array, Vector]
    def is_in(*values)
      self_data = chunked? ? data.pack : data

      array =
        case values
        in [Vector] | [Arrow::Array] | [Arrow::ChunkedArray]
          values[0].to_a
        else
          Array(values).flatten
        end

      Vector.create(self_data.is_in(array))
    end

    # Arrow's support required
    def index(element)
      to_a.index(element)
    end

    private

    # Accepts indices by numeric Vector
    def take_by_vector(indices)
      indices = (indices < 0).if_else(indices + size, indices) if (indices < 0).any?

      min, max = indices.min_max
      raise VectorArgumentError, "Index out of range: #{min}" if min < 0
      raise VectorArgumentError, "Index out of range: #{max}" if max >= size

      index_array =
        if indices.float?
          Arrow::UInt64ArrayBuilder.build(indices.data)
        else
          indices.data
        end

      find(:take).execute([data, index_array]).value # :array_take will fail with ChunkedArray
    end

    # Accepts booleans by Arrow::BooleanArray
    def filter_by_array(boolean_array)
      raise VectorArgumentError, 'Booleans must be same size as self.' unless boolean_array.length == size

      find(:array_filter).execute([data, boolean_array]).value
    end

    def scalar_or_array(arrow_array)
      a = arrow_array.to_a
      a.size > 1 ? a : a[0]
    end
  end
end
