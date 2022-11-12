# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-in for class Vector
  # Functions to make up some data (especially missing) for new data.
  module VectorUpdatable
    # Replace data
    # @param specifier [Array, Vector, Arrow::Array] index or booleans.
    # @param replacer [Scalar, Array, Vector, Arrow::Array] new data to replace for.
    # @return [Vector] Replaced new Vector.
    #   If specifier has no true, return self.
    #
    def replace(specifier, replacer)
      vector = parse_to_vector(Array(specifier))
      return self if vector.empty? || empty?

      booleans =
        if vector.boolean?
          vector
        elsif vector.numeric?
          Vector.new(indices).is_in(vector)
        else
          raise VectorArgumentError, "Invalid data type #{specifier}"
        end
      return self if booleans.sum.zero?

      replacer_array =
        case replacer
        in []
          return self
        in nil | [nil]
          return replace_to_nil(booleans.data)
        in Arrow::Array
        # nop
        in Vector
          replacer.data
        in Array
          Arrow::Array.new(replacer)
        else # Broadcast scalar to Array
          Arrow::Array.new(Array(replacer) * booleans.to_a.count(true))
        end
      raise VectorArgumentError, 'Replacements size unmatch' if booleans.sum != replacer_array.length

      replace_with(booleans.data, replacer_array)
    end

    # (related functions)
    # fill_null_backward, fill_null_forward

    # [Ternary element-wise]: boolean_vector.func(if_true, else) => vector
    def if_else(true_choice, false_choice)
      true_choice = true_choice.data if true_choice.is_a? Vector
      false_choice = false_choice.data if false_choice.is_a? Vector
      raise VectorTypeError, 'Reciever must be a boolean' unless boolean?

      datum = find(:if_else).execute([data, true_choice, false_choice])
      Vector.new(datum.value)
    end

    # same behavior as Ruby's invert
    # ![true, false, nil] #=> [false, true, true]
    def primitive_invert
      raise VectorTypeError, "Not a boolean Vector: #{self}" unless boolean?

      is_nil.if_else(false, self).invert
    end

    def shift(amount = 1, fill: nil)
      raise VectorArgumentError, 'Shift amount is too large' if amount.abs > size

      if amount.positive?
        replace(amount..-1, self[0...-amount]).replace(0...amount, fill)
      elsif amount.negative?
        replace(0...amount, self[-amount..]).replace(amount..-1, fill)
      else # amount == 0
        self
      end
    end

    private

    # Replace elements selected with a boolean mask
    #
    # @param boolean_mask [Arrow::BooleanArray] Boolean mask which indicates the position to be replaced.
    #   - Position with true will be replaced.
    #   - Position with nil will be nil.
    #
    # @param replacer [Arrow::Array] Values after replaced
    #   (either scalar or array). If Array is given, original values are replaced by
    #   each element of the array at the corresponding position of mask element.
    #   - `replacer.size` must be equal to `mask.count(true)`.
    #   - Types of self and replacer must be same
    #
    # @return [Vector] Replaced vector.
    #   Type of returned Vector is upcasted if needed.
    #
    def replace_with(boolean_mask, replacer)
      raise VectorArgumentError, 'Booleans size unmatch' if boolean_mask.length != size
      raise VectorArgumentError, 'Booleans not have any `true`' unless boolean_mask.any?

      values = replacer.class.new(data) # Upcast

      datum = find(:replace_with_mask).execute([values, boolean_mask, replacer])
      Vector.new(datum.value)
    end

    # Replace elements selected with a boolean mask by nil
    #
    # @param boolean_mask [Arrow::BooleanArray] Boolean mask which indicates the position to be replaced.
    #   - Position with true will be replaced by nil
    #   - Position with nil will remain as nil.
    # @return [Vector] Replaced vector.
    #
    def replace_to_nil(boolean_mask)
      nil_array = data.class.new([nil] * size) # Casted nil Array
      datum = find(:if_else).execute([boolean_mask, nil_array, data])
      Vector.new(datum.value)
    end
  end
end
