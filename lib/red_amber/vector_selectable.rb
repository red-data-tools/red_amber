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
    def take(*indices)
      indices.flatten!
      return Vector.new([]) if indices.empty?

      indices = indices[0] if indices.one? && !indices[0].is_a?(Numeric)
      indices = Vector.new(indices) unless indices.is_a?(Vector)
      raise VectorTypeError, 'Indices must be numeric Vector or Array.' unless indices.numeric?
      raise VectorArgumentError, "Index out of range: #{indices.min}" if indices.min <= -size - 1

      index_vector = (indices < 0).if_else(indices + size, indices) # normalize index from tail
      raise VectorArgumentError, "Index out of range: #{index_vector.max}" if index_vector.max >= size

      index_array = Arrow::UInt64ArrayBuilder.build(index_vector.data) # round to integer array

      datum = find(:array_take).execute([data, index_array])
      take_out_element_wise(datum)
    end
  end
end
