# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-in for class Vector
  # Functions to make up some data (especially missing) for new data.
  module VectorUpdatable
    # Add properties to Arrow::Array and Arrow::ChunkedArray
    using RefineArrayLike

    # Replace data
    # @param specifier [Array, Vector, Arrow::Array] index or booleans.
    # @param replacer [Scalar, Array, Vector, Arrow::Array] new data to replace for.
    # @return [Vector] Replaced new Vector.
    #   If specifier has no true, return self.
    #
    def replace(specifier, replacer)
      vector = Vector.new(parse_args(Array(specifier), size))
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
      if booleans.sum != replacer_array.length
        raise VectorArgumentError, 'Replacements size unmatch'
      end

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
      Vector.create(datum.value)
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

    # Split string Vector and returns Array of columns.
    #
    # @param sep [nil, String, Regexp] separater.
    #   If separator is nil (or no argeument given), the column will be splitted by
    #   Arrow's split function using any ASCII whitespace.
    #   Otherwise sep will passed to String#split.
    # @param limit [Integer] maximum number to limit separation. Passed to String#split.
    # @return [Array<Vector>] an Array of Vectors.
    # @note nil will separated as nil's at same row. ex) `nil => [nil, nil]`
    #
    def split_to_columns(sep = nil, limit = 0)
      l = split(sep, limit)
      l.list_separate
    end

    # Split string Vector and flatten into rows.
    #
    # @param sep [nil, String, Regexp] separater.
    #   If separator is nil (or no argeument given), the column will be splitted by
    #   Arrow's split function using any ASCII whitespace.
    #   Otherwise sep will passed to String#split.
    # @param limit [Integer] maximum number to limit separation. Passed to String#split.
    # @return [Vector] a flatten Vector.
    # @note nil will separated as nil's at same row. ex) `nil => [nil, nil]`
    #
    def split_to_rows(sep = nil, limit = 0)
      l = split(sep, limit)
      l.list_flatten
    end

    # return element size Array for list Vector.
    #
    # @api private
    #
    def list_sizes
      Vector.create find(:list_value_length).execute([data]).value
    end

    # Separate list Vector by columns.
    #
    # @api private
    #
    def list_separate
      len = list_sizes.data
      min, max = Arrow::Function.find(:min_max).execute([len]).value.value.map(&:value)

      result = []
      (0...min).each do |i|
        result << Vector.create(find(:list_element).execute([data, i]).value)
      end
      return result if min == max

      (min...max).each do |i|
        result << Vector.new(data.map { |e| e&.[](i) })
      end
      result
    end

    # Flatten list Vector for rows.
    #
    # @api private
    #
    def list_flatten
      Vector.create find(:list_flatten).execute([data]).value
    end

    # Split string Vector by each element with separator and returns list Array.
    #
    # @note if sep is not specified, use Arrow's ascii_split_whitespace.
    #   It will separate string by ascii whitespaces.
    # @note if sep specified, sep and limit will passed to String#split.
    #
    def split(sep = nil, limit = 0)
      if empty? || !string?
        raise VectorTypeError, "self is not a valid string Vector: #{self}"
      end
      if self[0].nil? && uniq.to_a == [nil] # Avoid heavy check to be activated always.
        raise VectorTypeError, 'self contains only nil'
      end

      list =
        if sep
          Arrow::Array.new(to_a.map { |e| e&.split(sep, limit) })
        else
          find(:ascii_split_whitespace).execute([data]).value
        end
      Vector.create(list)
    end

    # Merge String or other string Vector to self.
    #   Self must be a string Vector.
    #
    # @param other [String, Vector]
    #   merger from right. It will be broadcasted if it is a scalar String.
    # @param sep [String] separator.
    # @return [Vector] merged Vector
    #
    def merge(other, sep: ' ')
      if empty? || !string?
        raise VectorTypeError,
              "self is not a string Vector: #{self}"
      end
      unless sep.is_a?(String)
        raise VectorArgumentError, "separator is not a String: #{sep}"
      end

      other_array =
        case other
        in String => s
          [s] * size
        in (Vector | Arrow::Array | Arrow::ChunkedArray) => x if x.string?
          x.to_a
        else
          raise VectorArgumentError,
                "other is not a String or a string Vector: #{self}"
        end

      list = Arrow::Array.new(to_a.zip(other_array))
      datum = find(:binary_join).execute([list, sep])
      Vector.create(datum.value)
    end

    private

    # Replace elements selected with a boolean mask
    #
    # @param boolean_mask [Arrow::BooleanArray]
    #   Boolean mask which indicates the position to be replaced.
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
      Vector.create(datum.value)
    end

    # Replace elements selected with a boolean mask by nil
    #
    # @param boolean_mask [Arrow::BooleanArray]
    #   Boolean mask which indicates the position to be replaced.
    #   - Position with true will be replaced by nil
    #   - Position with nil will remain as nil.
    # @return [Vector] Replaced vector.
    #
    def replace_to_nil(boolean_mask)
      nil_array = data.class.new([nil] * size) # Casted nil Array
      datum = find(:if_else).execute([boolean_mask, nil_array, data])
      Vector.create(datum.value)
    end
  end
end
