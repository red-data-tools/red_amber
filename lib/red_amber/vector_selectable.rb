# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-ins for class Vector
  # Functions to select some data.
  module VectorSelectable
    def drop_nil
      datum = find(:drop_null).execute([data])
      take_out_element_wise(datum)
    end

    # vector calculation version of selection by indices
    # TODO: support for option {boundscheck: true}
    def take(*indices)
      indices.flatten!
      return Vector.new([]) if indices.empty?

      indices = indices[0] if indices.one? && !indices[0].is_a?(Numeric)
      indices = Vector.new(indices) unless indices.is_a?(Vector)

      generic_take(indices) # returns sub Vector
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

      generic_filter(boolean_array) # returns sub Vector
    end

    #   @param indices
    #   @param booleans
    def [](*args)
      args.flatten!
      return Vector.new([]) if args.empty?

      arg = args[0]
      case arg
      when Vector
        return generic_take(arg) if arg.numeric?
        return generic_filter(arg.data) if arg.boolean?

        raise VectorTypeError, "Argument must be numeric or boolean: #{arg}"
      when Arrow::BooleanArray
        return generic_filter(arg)
      when Arrow::Array
        array = arg
      else
        unless arg.is_a?(Numeric) || booleans?([arg])
          raise VectorArgumentError, "Argument must be numeric or boolean: #{args}"
        end
      end
      array ||= Arrow::Array.new(args)
      return generic_filter(array) if array.is_a?(Arrow::BooleanArray)

      vector = Vector.new(array)
      return generic_take(vector) if vector.numeric?

      raise VectorArgumentError, "Invalid argument: #{args}"
    end

    private

    # Accepts indices by numeric Vector
    def generic_take(indices)
      raise VectorTypeError, "Indices must be numeric Vector: #{indices}" unless indices.numeric?
      raise VectorArgumentError, "Index out of range: #{indices.min}" if indices.min <= -size - 1

      normalized_indices = (indices < 0).if_else(indices + size, indices) # normalize index from tail
      raise VectorArgumentError, "Index out of range: #{normalized_indices.max}" if normalized_indices.max >= size

      index_array = Arrow::UInt64ArrayBuilder.build(normalized_indices.data) # round to integer array

      datum = find(:array_take).execute([data, index_array])
      take_out_element_wise(datum)
    end

    # Accepts booleans by Arrow::BooleanArray
    def generic_filter(boolean_array)
      raise VectorArgumentError, 'Booleans must be same size as self.' unless boolean_array.length == size

      datum = find(:array_filter).execute([data, boolean_array])
      take_out_element_wise(datum)
    end
  end
end
