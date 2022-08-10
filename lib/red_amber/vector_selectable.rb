# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-ins for class Vector
  # Functions to select some data.
  module VectorSelectable
    def drop_nil
      datum = find(:drop_null).execute([data])
      Vector.new(datum.value)
    end

    # vector calculation version of selection by indices
    # TODO: support for option {boundscheck: true}
    def take(*indices)
      indices.flatten!
      return Vector.new([]) if indices.empty?

      indices = indices[0] if indices.one? && !indices[0].is_a?(Numeric)
      indices = Vector.new(indices) unless indices.is_a?(Vector)

      take_by_vector(indices) # returns sub Vector
    end

    # TODO: support for option {null_selection_behavior: :drop}
    def filter(*booleans)
      booleans.flatten!
      return Vector.new([]) if booleans.empty?

      b = booleans[0]
      boolean_array =
        case b
        when Vector
          raise VectorTypeError, 'Argument is not a boolean.' unless b.boolean?

          b.data
        when Arrow::BooleanArray
          b
        else
          raise VectorTypeError, 'Argument is not a boolean.' unless booleans?(booleans)

          Arrow::BooleanArray.new(booleans)
        end

      filter_by_array(boolean_array) # returns sub Vector
    end

    #   @param indices
    #   @param booleans
    def [](*args)
      args.flatten!
      return Vector.new([]) if args.empty?

      arg = args[0]
      case arg
      when Vector
        return take_by_vector(arg) if arg.numeric?
        return filter_by_array(arg.data) if arg.boolean?

        raise VectorTypeError, "Argument must be numeric or boolean: #{arg}"
      when Arrow::BooleanArray
        return filter_by_array(arg)
      when Arrow::Array
        array = arg
      when Range
        array = normalize_element(arg)
      else
        unless arg.is_a?(Numeric) || booleans?([arg])
          raise VectorArgumentError, "Argument must be numeric or boolean: #{args}"
        end
      end
      array ||= Arrow::Array.new(args)
      return filter_by_array(array) if array.is_a?(Arrow::BooleanArray)

      vector = Vector.new(array)
      return take_by_vector(vector) if vector.numeric?

      raise VectorArgumentError, "Invalid argument: #{args}"
    end

    #   @param values [Array, Arrow::Array, Vector]
    def is_in(*values)
      values.flatten!
      array =
        case values[0]
        when Vector
          values[0].data
        when Arrow::Array
          values[0]
        end
      array ||= data.class.new(values)
      Vector.new(data.is_in(array))
    end

    # Arrow's support required
    def index(element)
      to_a.index(element)
    end

    private

    # Accepts indices by numeric Vector
    def take_by_vector(indices)
      raise VectorTypeError, "Indices must be numeric Vector: #{indices}" unless indices.numeric?
      raise VectorArgumentError, "Index out of range: #{indices.min}" if indices.min <= -size - 1

      normalized_indices = (indices < 0).if_else(indices + size, indices) # normalize index from tail
      raise VectorArgumentError, "Index out of range: #{normalized_indices.max}" if normalized_indices.max >= size

      index_array = Arrow::UInt64ArrayBuilder.build(normalized_indices.data) # round to integer array

      datum = find(:take).execute([data, index_array]) # :array_take will fail with ChunkedArray
      Vector.new(datum.value)
    end

    # Accepts booleans by Arrow::BooleanArray
    def filter_by_array(boolean_array)
      raise VectorArgumentError, 'Booleans must be same size as self.' unless boolean_array.length == size

      datum = find(:array_filter).execute([data, boolean_array])
      Vector.new(datum.value)
    end
  end
end
