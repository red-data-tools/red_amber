# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-ins for class Vector
  # Functions to make up some data (especially missing) for new data.
  module VectorCompensable
    # [Ternary]: replace_with(booleans, replacements) => vector
    # Replace items selected with a boolean mask
    #
    # (from Arrow C++ inline doc.)
    # Given an array and a boolean mask (either scalar or of equal length),
    # along with replacement values (either scalar or array),
    # each element of the array for which the corresponding mask element is
    # true will be replaced by the next value from the replacements,
    # or with null if the mask is null.
    # Hence, for replacement arrays, len(replacements) == sum(mask == true).

    def replace_with(booleans, replacements)
      boolean_ary =
        if booleans.is_a?(Arrow::BooleanArray)
          booleans
        elsif booleans.is_a?(Vector) && booleans.boolean?
          booleans.data
        elsif booleans.is_a?(Array) && booleans?(booleans)
          Arrow::BooleanArray.new(booleans)
        else
          raise VectorTypeError, 'Not a valid type'
        end
      raise VectorArgumentError, 'Booleans size unmatch' if boolean_ary.length != size
      raise VectorArgumentError, 'Booleans not have any `true`' unless boolean_ary.any?

      replacement_ary =
        if Array(replacements).one?
          case replacements
          when Arrow::Array then replacements
          when Vector then replacements.data
          else
            Arrow::Array.new(Array(replacements) * Array(boolean_ary).count(true)) # broadcast
          end
        else
          Arrow::Array.new(replacements)
        end
      if Array(boolean_ary).count(true) != replacement_ary.length
        raise VectorArgumentError, 'Replacements size unmatch'
      end

      values = replacement_ary.class.new(data)

      datum = find('replace_with_mask').execute([values, boolean_ary, replacement_ary])
      take_out_element_wise(datum)
    end

    # (related functions)
    # fill_null_backward, fill_null_forward

    private

    def booleans?(enum)
      enum.all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
    end
  end
end
