# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-in for class Vector
  #   Functions to select some data.
  module VectorSelectable
    using RefineArray

    def drop_nil
      datum = find(:drop_null).execute([data])
      Vector.create(datum.value)
    end

    # vector version of selection by indices
    # TODO: support for the option `boundscheck: true``
    def take(*indices)
      case indices
      in [Vector => v] if v.numeric?
        take_by_vector(v)
      in []
        Vector.new
      else
        v = Vector.new(indices.flatten)
        raise VectorArgumentError, "argument must be a integers: #{indices}" unless v.numeric?

        take_by_vector(v)
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
        return filter_by_array(v.data) if v.boolean?

        raise VectorTypeError, 'Argument is not a boolean.'
      in [Arrow::BooleanArray => ba]
        filter_by_array(ba)
      in []
        Vector.new
      else
        booleans.flatten!
        return filter_by_array(Arrow::BooleanArray.new(booleans)) if booleans.booleans?

        raise VectorTypeError, 'Argument is not a boolean.'
      end
    end
    alias_method :select, :filter
    alias_method :find_all, :filter

    #   @param indices
    #   @param booleans
    def [](*args)
      case args
      in [Vector => v]
        return take_by_vector(v) if v.numeric?
        return filter_by_array(v.data) if v.boolean?

        raise VectorTypeError, "Argument must be numeric or boolean: #{args}"
      in [Arrow::BooleanArray => ba]
        return filter_by_array(ba)
      in []
        return Vector.new
      in [Arrow::Array => aa]
        array = aa
      in [Range => r]
        array = parse_range(r, size)
      else
        array = Arrow::Array.new(args.flatten)
      end

      return filter_by_array(array) if array.is_a?(Arrow::BooleanArray)

      vector = Vector.new(array)
      return take_by_vector(vector) if vector.numeric?

      raise VectorArgumentError, "Invalid argument: #{args}"
    end

    #   @param values [Array, Arrow::Array, Vector]
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

      datum = find(:take).execute([data, index_array]) # :array_take will fail with ChunkedArray
      Vector.create(datum.value)
    end

    # Accepts booleans by Arrow::BooleanArray
    def filter_by_array(boolean_array)
      raise VectorArgumentError, 'Booleans must be same size as self.' unless boolean_array.length == size

      datum = find(:array_filter).execute([data, boolean_array])
      Vector.create(datum.value)
    end
  end
end
