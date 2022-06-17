# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-ins for class Vector
  # Functions to make up some data (especially missing) for new data.
  module VectorUpdatable
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

    def replace_with(booleans, replacements = nil)
      specifier =
        if booleans.is_a?(Arrow::BooleanArray)
          booleans
        elsif booleans.is_a?(Vector) && booleans.boolean?
          booleans.data
        elsif booleans.is_a?(Array) && booleans?(booleans)
          Arrow::BooleanArray.new(booleans)
        else
          raise VectorTypeError, 'Not a valid type'
        end
      raise VectorArgumentError, 'Booleans size unmatch' if specifier.length != size
      raise VectorArgumentError, 'Booleans not have any `true`' unless specifier.any?

      r = Array(replacements) # scalar to [scalar]
      r = [nil] if r.empty?

      replacer =
        if r.size == 1
          case replacements
          when Arrow::Array then replacements
          when Vector then replacements.data
          else
            Arrow::Array.new(r * specifier.to_a.count(true)) # broadcast
          end
        else
          Arrow::Array.new(r)
        end
      replacer = data.class.new(replacer) if replacer.uniq == [nil]

      raise VectorArgumentError, 'Replacements size unmatch' if Array(specifier).count(true) != replacer.length

      values = replacer.class.new(data)

      datum = find('replace_with_mask').execute([values, specifier, replacer])
      take_out_element_wise(datum)
    end

    # (related functions)
    # fill_null_backward, fill_null_forward

    # [Ternary element-wise]: boolean_vector.func(if_true, else) => vector
    def if_else(true_choice, false_choice)
      true_choice = true_choice.data if true_choice.is_a? Vector
      false_choice = false_choice.data if false_choice.is_a? Vector
      raise VectorTypeError, 'Reciever must be a boolean' unless boolean?

      datum = find(:if_else).execute([data, true_choice, false_choice])
      take_out_element_wise(datum)
    end

    private

    def booleans?(enum)
      enum.all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
    end
  end
end
