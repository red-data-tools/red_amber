# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Mix-in for class Vector
  # Functions to make up some data (especially missing) for new data.
  module VectorUpdatable
    # Add properties to Arrow::Array and Arrow::ChunkedArray
    using RefineArrayLike

    # Replace data in self by position specifier and replacer.
    #
    # - Scalar value may be broadcasted.
    # - Returned value type may be automatically up-casted by replacer.
    #
    # @overload replace(booleans, replacer_by_scalar)
    #   Replace the value where true in boolean specifier to scalar replacer.
    #
    #   @param booleans [Array, Vector, Arrow::Array]
    #     boolean position specifier to specify the position to be replaced by true.
    #   @param replacer_by_scalar [Scalar]
    #     new data to replace for.
    #   @return [Vector]
    #     a new replaced Vector.
    #     If specifier has no true, returns self.
    #   @example Replace with boolean specifier and scalar replacer
    #     Vector.new([1, 2, 3]).replace([true, false, true], 0)
    #
    #     # =>
    #     #<RedAmber::Vector(:uint8, size=3):0x000000000001ee10>
    #     [0, 2, 0]
    #
    #   @example Type of result is up-casted by replacer.
    #     ector.new([1, 2, 3]).replace([true, false, true], -1.0)
    #
    #     # =>
    #     #<RedAmber::Vector(:double, size=3):0x0000000000025d78>
    #     [-1.0, 2.0, -1.0]
    #
    #   @example Position of nil in booleans is replaced with nil
    #     Vector.new([1, 2, 3]).replace([true, false, nil], -1)
    #
    #     # =>
    #     #<RedAmber::Vector(:int8, size=3):0x00000000000304d0>
    #     [-1, 2, nil]
    #
    #   @example Replace 'NA' to nil
    #     vector = Vector.new(['A', 'B', 'NA'])
    #     vector.replace(vector == 'NA', nil)
    #
    #     # =>
    #     #<RedAmber::Vector(:string, size=3):0x000000000000f8ac>
    #     ["A", "B", nil]
    #
    # @overload replace(indices, replacer_by_scalar)
    #   Replace the value at the index specifier to scalar replacer.
    #
    #   @param indices [Array, Vector, Arrow::Array]
    #     index specifier to specify the position to be replaced.
    #   @param replacer_by_scalar [Scalar]
    #     new data to replace for.
    #   @return [Vector]
    #     a new replaced Vector.
    #     If specifier is empty, returns self.
    #   @example Replace with index specifier and scalar replacer
    #     Vector.new([1, 2, 3]).replace([0, 2], 0)
    #
    #     # =>
    #     #<RedAmber::Vector(:uint8, size=3):0x000000000000c15c>
    #     [0, 2, 0]
    #
    # @overload replace(booleans, replacer_array)
    #   Replace the value where true in boolean specifier to replacer array.
    #
    #   @param booleans [Array, Vector, Arrow::Array]
    #     boolean position specifier to specify the position to be replaced by true.
    #   @param replacer_array [Vector, Array, Arrow::Array]
    #     new data to replace for.
    #     The number of true in booleans must be equal to the length of replacer array.
    #   @return [Vector]
    #     a new replaced Vector.
    #     If specifier has no true, returns self.
    #   @example Replace with boolean specifier and replacer array
    #     vector = Vector.new([1, 2, 3])
    #     booleans = [true, false, true]
    #     replacer = [4, 5]
    #     vector.replace(booleans, replacer)
    #
    #     # =>
    #     #<RedAmber::Vector(:uint8, size=3):0x000000000001ee10>
    #     [4, 2, 5]
    #
    # @overload replace(indices, replacer_array)
    #   Replace the value at the index specifier to replacer array.
    #
    #   @param indices [Array, Vector, Arrow::Array]
    #     index specifier to specify the position to be replaced.
    #   @param replacer_array [Vector, Array, Arrow::Array]
    #     new data to replace for.
    #     The length of index specifier must be equal to the length of replacer array.
    #   @return [Vector]
    #     a new replaced Vector.
    #     If specifier is empty, returns self.
    #   @example Replace with index specifier and replacer array
    #     vector = Vector.new([1, 2, 3])
    #     indices = [0, 2]
    #     replacer = [4, 5]
    #     vector.replace(indices, replacer)
    #
    #     # =>
    #     #<RedAmber::Vector(:uint8, size=3):0x000000000001ee10>
    #     [4, 2, 5]
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
          replacer
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

    # Replace nil to value.
    #
    # @note Use `fill_nil_backawrd` or `fill_nil_forward` to replace nil
    #   by adjacent values.
    # @see #fill_nil_backward
    # @see #fill_nil_forward
    # @param value [scalar]
    #   the value to replace with.
    # @return [Vector]
    #   replaced Vector
    # @since 0.5.0
    #
    def fill_nil(value)
      is_nil.if_else(value, self)
    end

    # Choose values based on self.
    #
    # [Ternary element-wise function] Returns a Vector.
    # - Self must be a boolean Vector.
    # - `true_choice`, `false_choice` must be of the same type scalar / array / Vector.
    # - `nil` values in self will be promoted to the output.
    #
    # @overload if_else(true_choise, false_choise)
    #   replace with a scalar.
    #
    #   @param true_choice [scalar]
    #     a value to be replaced with true.
    #   @param false_choice [scalar]
    #     a value to be replaced with false.
    #   @return [Vector]
    #     replaced result.
    #   @example Replace with scalar choices
    #     Vector.new(true, true, false, nil, false).if_else(1, 2)
    #
    #     # =>
    #     #<RedAmber::Vector(:uint8, size=5):0x000000000000c198>
    #     [1, 1, 2, nil, 2]
    #
    # @overload if_else(true_choise, false_choise)
    #   replace with a scalar.
    #
    #   @param true_choice [Vector, Array, Arrow::Array]
    #     values to be replaced with true.
    #     The size of true_choice must be same as self.
    #   @param false_choice [Vector, Array, Arrow::Array]
    #     values to be replaced with false.
    #     The size of false_choice must be same as self.
    #   @return [Vector]
    #     replaced result.
    #   @example Replace with Array choices
    #     boolean_vector = Vector.new(true, true, false, nil, false)
    #     true_choise = Vector.new([1.1, 2.2, 3.3, 4.4, 5.5])
    #     false_choise = -true_choise
    #     boolean_vector.if_else(true_choise, false_choise)
    #
    #     # =>
    #     #<RedAmber::Vector(:double, size=5):0x000000000000cd28>
    #     [1.1, 2.2, -3.3, nil, -5.5]
    #
    #   @example Normalize negative indices to positive ones
    #     indices = Vector.new([1, -1, 3, -4])
    #     array_size = 10
    #     normalized_indices = (indices < 0).if_else(indices + array_size, indices)
    #
    #     # =>
    #     #<RedAmber::Vector(:int16, size=4):0x000000000000f85c>
    #     [1, 9, 3, 6]
    #
    def if_else(true_choice, false_choice)
      true_choice = true_choice.data if true_choice.is_a? Vector
      false_choice = false_choice.data if false_choice.is_a? Vector
      raise VectorTypeError, 'Reciever must be a boolean' unless boolean?

      datum = find(:if_else).execute([data, true_choice, false_choice])
      Vector.create(datum.value)
    end

    # Another #invert which is same behavior as Ruby's invert.
    #
    # ![true, false, nil] #=> [false, true, true]
    # @return [Vector]
    #   follows Ruby's BasicObject#!'s behavior.
    # @example
    #   vector = Vector.new([true, true, false, nil])
    #
    #   # =>
    #   #<RedAmber::Vector(:boolean, size=4):0x000000000000fa8c>
    #   [true, true, false, nil]
    #
    #   # nil is converted to nil by Vector#invert.
    #   vector.invert
    #   # or
    #   !vector
    #
    #   #<RedAmber::Vector(:boolean, size=4):0x000000000000faa0>
    #   [false, false, true, nil]
    #
    #   # On the other hand,
    #   # Vector#primitive_invert follows Ruby's BasicObject#!'s behavior.
    #   vector.primitive_invert
    #
    #   # =>
    #   #<RedAmber::Vector(:boolean, size=4):0x000000000000fab4>
    #   [false, false, true, true]
    #
    def primitive_invert
      raise VectorTypeError, "Not a boolean Vector: #{self}" unless boolean?

      is_nil.if_else(false, self).invert
    end

    # Shift elements in self.
    #
    # @param amount [Integer]
    #   amount of shift. Positive value will shift right, negative will shift left.
    # @param fill [Object]
    #   complementary element to fill the new seat.
    # @return [Vector]
    #   shifted Vector.
    #
    def shift(amount = 1, fill: nil)
      raise VectorArgumentError, 'Shift amount is too large' if amount.abs >= size

      if amount.positive?
        filler = [fill] * amount
        Vector.new(filler.concat(Array(self[0...-amount])))
      elsif amount.negative?
        filler = [fill] * -amount
        Vector.new(Array(self[-amount...]).concat(filler))
      else # amount == 0
        self
      end
    end

    # Split string Vector and returns Array of columns.
    #
    # @param sep [nil, String, Regexp]
    #   separator.
    #   If separator is nil (or no argeument given),
    #   the column will be splitted by Arrow's split function
    #   using any ASCII whitespace.
    #   Otherwise, sep will passed to String#split.
    # @param limit [Integer]
    #   maximum number to limit separation. Passed to String#split.
    # @return [Array<Vector>]
    #   an Array of Vectors.
    # @note nil will separated as nil's at same row.
    #   ex) `nil => [nil, nil]`
    #
    def split_to_columns(sep = nil, limit = 0)
      l = split(sep, limit)
      l.list_separate
    end

    # Split string Vector and flatten into rows.
    #
    # @param sep [nil, String, Regexp]
    #   separater.
    #   If separator is nil (or no argeument given),
    #   the column will be splitted by Arrow's split function
    #   using any ASCII whitespace.
    #   Otherwise, sep will passed to String#split.
    # @param limit [Integer]
    #   maximum number to limit separation. Passed to String#split.
    # @return [Vector]
    #   a flatten Vector.
    # @note nil will separated as nil's at same row.
    #   ex) `nil => [nil, nil]`
    #
    def split_to_rows(sep = nil, limit = 0)
      l = split(sep, limit)
      l.list_flatten
    end

    # Return element size Array for list Vector.
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
    # @param sep [String]
    #   separator.
    # @return [Vector]
    #   merged Vector
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

    # Concatenate other array-like to self.
    #
    # @param other [Vector, Array, Arrow::Array, Arrow::ChunkedArray]
    #   other array-like to concatenate.
    # @return [Vector]
    #   concatenated Vector.
    # @example Concatenate to string
    #   string_vector
    #
    #   # =>
    #   #<RedAmber::Vector(:string, size=2):0x00000000000037b4>
    #   ["A", "B"]
    #
    #   string_vector.concatenate([1, 2])
    #
    #   # =>
    #   #<RedAmber::Vector(:string, size=4):0x0000000000003818>
    #   ["A", "B", "1", "2"]
    #
    # @example Concatenate to integer
    #   integer_vector
    #
    #   # =>
    #   #<RedAmber::Vector(:uint8, size=2):0x000000000000382c>
    #   [1, 2]
    #
    #   integer_vector.concatenate(["A", "B"])
    #   # =>
    #   #<RedAmber::Vector(:uint8, size=4):0x0000000000003840>
    #   [1, 2, 65, 66]
    #
    # @since 0.4.0
    #
    def concatenate(other)
      concatenated_array =
        case other
        when Vector
          data + other.data
        when Arrow::ChunkedArray
          data + other.pack
        else
          data + other
        end
      Vector.create(concatenated_array)
    end
    alias_method :concat, :concatenate

    # Cast self to `type`.
    #
    # @param type [symbol]
    #   type to cast.
    # @return [Vector]
    #   casted Vector.
    # @since 0.5.0
    #
    def cast(type)
      Vector.create(data.cast(type))
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
    # @return [Vector]
    #   replaced vector.
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
    # @return [Vector]
    #   replaced vector.
    #
    def replace_to_nil(boolean_mask)
      nil_array = data.class.new([nil] * size) # Casted nil Array
      datum = find(:if_else).execute([boolean_mask, nil_array, data])
      Vector.create(datum.value)
    end
  end
end
