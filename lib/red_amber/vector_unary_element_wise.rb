# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      private

      # @!macro [attach] define_unary_element_wise
      #   [Unary element-wise function] Returns a Vector.
      #
      def define_unary_element_wise(function)
        define_method(function) do |**options|
          datum = exec_func_unary(function, options)
          Vector.create(datum.value)
        end
      end
    end

    # @!macro array_sort_options
    #   @param order [:ascending, :descending]
    #     ascending: Arrange values in increasing order.
    #     descending: Arrange values in decreasing order.

    # rubocop:disable Layout/LineLength

    # @!macro round_mode
    #   @param round_mode [:down, :up, :towards_zero, :towards_infinity, :half_down, :half_up, :half_towards_zero, :half_towards_infinity, :half_to_even, :half_to_odd]
    #     Rounding and tie-breaking mode.
    #     - down: Round to nearest integer less than or equal in magnitude (aka “floor”).
    #     - up: Round to nearest integer greater than or equal in magnitude (aka “ceil”).
    #     - towards_zero: Get the integral part without fractional digits (aka “trunc”).
    #     - towards_infinity: Round negative values with :down rule and positive values
    #       with :up rule (aka “away from zero”).
    #     - half_down: Round ties with :down rule (also called
    #       “round half towards negative infinity”).
    #     - half_up: Round ties with :up rule (also called
    #       “round half towards positive infinity”).
    #     - half_towards_zero: Round ties with :towards_zero rule (also called
    #       “round half away from infinity”).
    #     - half_towards_infinity: Round ties with :towards_infinity rule (also called
    #       “round half away from zero”).
    #     - half_to_even: Round ties to nearest even integer.
    #     - half_to_odd: Round ties to nearest odd integer.

    # rubocop:enable Layout/LineLength

    # Calculate the absolute value of self element-wise.
    #
    # Results will wrap around on integer overflow.
    # @return [Vector]
    #   abs of each element of self.
    #
    define_unary_element_wise :abs

    # Calculate the absolute value of self element-wise.
    #
    # This function is a overflow-checking variant of #abs.
    # @return (see #abs)
    #
    define_unary_element_wise :abs_checked

    # Compute the inverse cosine of self element-wise.
    #
    # NaN is returned for invalid input values.
    # @return [Vector]
    #   acos of each element of self.
    #
    define_unary_element_wise :acos

    # Compute the inverse cosine of self element-wise.
    #
    # This function is a overflow-checking variant of #acos.
    # @return (see #acos)
    #
    define_unary_element_wise :acos_checked

    # Compute the inverse sine of self element-wise.
    #
    # NaN is returned for invalid input values.
    # @return [Vector]
    #   asin of each element of self.
    #
    define_unary_element_wise :asin

    # Compute the inverse sine of self element-wise.
    #
    # This function is a overflow-checking variant of #asin.
    # @return (see #asin)
    #
    define_unary_element_wise :asin_checked

    # Return the indices that would sort self.
    #
    # Computes indices Vector that define a stable sort of self.
    # By default, nils are considered greater than any other value
    # and are therefore sorted at the end of the Vector.
    # For floating-point types, NaNs are considered greater than any
    # other non-nil value, but smaller than nil.
    # @!method array_sort_indices(order: :ascending)
    # @macro array_sort_options
    # @return [Vector]
    #   sort indices of self.
    #
    define_unary_element_wise :array_sort_indices
    alias_method :sort_indexes, :array_sort_indices
    alias_method :sort_indices, :array_sort_indices
    alias_method :sort_index, :array_sort_indices

    # Compute the inverse tangent of self element-wise.
    #
    # the return value is in the range [-pi/2, pi/2].
    # For a full return range [-pi, pi], see {.atan2} .
    # @return [Vector]
    #   atan of each element of self.
    #
    define_unary_element_wise :atan

    # Bit-wise negate by element-wise.
    #
    # nil values reeturn nil.
    # @return [Vector]
    #   bit wise not of each element of self.
    #
    define_unary_element_wise :bit_wise_not

    # Round up to the nearest integer.
    #
    # Compute the smallest integer value not less in magnitude than each element.
    # @return [Vector]
    #   ceil of each element of self.
    # @example
    #   double = Vector.new([15.15, 2.5, 3.5, -4.5, -5.5])
    #   double.ceil
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd00>
    #   [16.0, 3.0, 4.0, -4.0, -5.0]
    #
    define_unary_element_wise :ceil

    # Compute the cosine of self element-wise.
    #
    # NaN is returned for invalid input values.
    # @return [Vector]
    #   cos of each element of self.
    #
    define_unary_element_wise :cos

    # Compute the cosine of self element-wise.
    #
    # This function is a overflow-checking variant of #cos.
    # @return (see #cos)
    #
    define_unary_element_wise :cos_checked

    # Compute cumulative sum over the numeric Vector.
    #
    # This function is a overflow-checking variant of #cumsum.
    # @note Self must be numeric.
    # @note Return error for integer overflow.
    # @return [Vector]
    #   cumulative sum of self.
    #
    define_unary_element_wise :cumulative_sum_checked

    # Compute cumulative sum over the numeric Vector.
    #
    # @note Self must be numeric.
    # @note Try to cast to Int64 if integer overflow occured.
    # @return [Vector]
    #   cumulative sum of self.
    #
    def cumsum
      cumulative_sum_checked
    rescue Arrow::Error::Invalid
      Vector.create(Arrow::Int64Array.new(data)).cumulative_sum_checked
    end

    # Carry non-nil values backward to fill nil slots.
    #
    # Propagate next valid value backward to previous nil values.
    # Or nothing if all next values are nil.
    # @note Use `fill_nil(value)` to replace nil by a value.
    # @see #fill_nil
    # @return [Vector]
    #   a Vector which filled nil backward.
    # @example
    #   integer = Vector.new([0, 1, nil, 3, nil])
    #   integer.fill_nil_backward
    #
    #   # =>
    #   #<RedAmber::Vector(:uint8, size=5):0x000000000000f974>
    #   [0, 1, 3, 3, nil]
    #
    define_unary_element_wise :fill_null_backward
    alias_method :fill_nil_backward, :fill_null_backward

    # Carry non-nil values forward to fill nil slots.
    #
    # Propagate last valid value backward to next nil values.
    # Or nothing if all previous values are nil.
    # @note Use `fill_nil(value)` to replace nil by a value.
    # @see #fill_nil
    # @return [Vector]
    #   a Vector which filled nil forward.
    # @example
    #   integer = Vector.new([0, 1, nil, 3, nil])
    #   integer.fill_nil_forward
    #
    #   # =>
    #   #<RedAmber::Vector(:uint8, size=5):0x000000000000f960>
    #   [0, 1, 1, 3, 3]
    #
    define_unary_element_wise :fill_null_forward
    alias_method :fill_nil_forward, :fill_null_forward

    # Round down to the nearest integer.
    #
    # Compute the largest integer value not greater in magnitude than each element.
    # @return [Vector]
    #   floor of each element of self.
    # @example
    #   double = Vector.new([15.15, 2.5, 3.5, -4.5, -5.5])
    #   double.floor
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd14>
    #   [15.0, 2.0, 3.0, -5.0, -6.0]
    #
    define_unary_element_wise :floor

    # Return true if value is finite.
    #
    # For each input value, emit true if the value is finite.
    # (i.e. neither NaN, inf, nor -inf).
    # @return [Vector]
    #   boolean Vector wheather each element is finite.
    #
    define_unary_element_wise :is_finite

    # Return true if value is infinity.
    #
    # For each input value, emit true if the value is infinite (inf or -inf).
    # @return [Vector]
    #   boolean Vector wheather each element is inf.
    #
    define_unary_element_wise :is_inf

    # return true if value is nil or NaN.
    #
    # For each input value, emit true if the value is nil or NaN.
    # @return [Vector]
    #   boolean Vector wheather each element is na.
    #
    def is_na # rubocop:disable Naming/PredicateName
      numeric? ? (is_nil | is_nan) : is_nil
    end

    # Return true if NaN.
    #
    # For each input value, emit true if the value is NaN.
    # @return [Vector]
    #   boolean Vector wheather each element is nan.
    #
    define_unary_element_wise :is_nan

    # Return true if nil.
    #
    # @note Arrow::NullOptions is not supported yet.
    # For each input value, emit true if the value is nil.
    # @return [Vector]
    #   boolean Vector wheather each element is null.
    #
    define_unary_element_wise :is_null
    alias_method :is_nil, :is_null

    # Return true if non-nil.
    #
    # For each input value, emit true if the value is valid (i.e. non-nil).
    # @return [Vector]
    #   boolean Vector wheather each element is valid.
    #
    define_unary_element_wise :is_valid

    # Compute natural logarithm.
    #
    # Non-positive values return -inf or NaN. Nil values return nil.
    # @return [Vector]
    #   natural logarithm of each element of self.
    #
    define_unary_element_wise :ln

    # Compute natural logarithm.
    #
    # This function is a overflow-checking variant of #ln.
    # @return (see #ln)
    #
    define_unary_element_wise :ln_checked

    # Compute base 10 logarithm.
    #
    # Non-positive values return -inf or NaN. Nil values return nil.
    # @return [Vector]
    #   base 10 logarithm of each element of self.
    #
    define_unary_element_wise :log10

    # Compute base 10 logarithm.
    #
    # This function is a overflow-checking variant of #log10.
    # @return (see #log10)
    #
    define_unary_element_wise :log10_checked

    # Compute natural log of (1+x).
    #
    # Non-positive values return -inf or NaN. Nil values return nil.
    # This function may be more precise than log(1 + x) for x close to zero.
    # @return [Vector]
    #   natural log of (each element + 1) of self.
    #
    define_unary_element_wise :log1p

    # Compute natural log of (1+x).
    #
    # This function is a overflow-checking variant of #log1p.
    # @return (see #log1p)
    #
    define_unary_element_wise :log1p_checked

    # Compute base 2 logarithm.
    #
    # Non-positive values return -inf or NaN. Nil values return nil.
    # @return [Vector]
    #   base 2 logarithm of each element of self.
    #
    define_unary_element_wise :log2

    # Compute base 2 logarithm.
    #
    # This function is a overflow-checking variant of #log2.
    # @return (see #log2)
    #
    define_unary_element_wise :log2_checked

    # Round to a given precision.
    #
    # Options are used to control the number of digits and rounding mode.
    # Default behavior is to round to the nearest integer and
    # use half-to-even rule to break ties.
    # @!method round(n_digits: 0, round_mode: :half_to_even)
    # @param n_digits [Integer]
    #   Rounding precision (number of digits to round to).
    # @macro round_mode
    # @return [Vector]
    #   round of each element of self.
    # @example
    #   double = Vector.new([15.15, 2.5, 3.5, -4.5, -5.5])
    #   double.round
    #   # or double.round(n_digits: 0, mode: :half_to_even)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd28>
    #   [15.0, 2.0, 4.0, -4.0, -6.0]
    #
    #   double.round(mode: :towards_infinity)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd3c>
    #   [16.0, 3.0, 4.0, -5.0, -6.0]
    #
    #   double.round(mode: :half_up)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd50>
    #   [15.0, 3.0, 4.0, -4.0, -5.0]
    #
    #   double.round(mode: :half_towards_zero)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd64>
    #   [15.0, 2.0, 3.0, -4.0, -5.0]
    #
    #   double.round(mode: :half_towards_infinity)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd78>
    #   [15.0, 3.0, 4.0, -5.0, -6.0]
    #
    #   double.round(mode: :half_to_odd)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cd8c>
    #   [15.0, 3.0, 3.0, -5.0, -5.0]
    #
    #   double.round(n_digits: 1)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cda0>
    #   [15.2, 2.5, 3.5, -4.5, -5.5]
    #
    #   double.round(n_digits: -1)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000cdb4>
    #   [20.0, 0.0, 0.0, -0.0, -10.0]
    #
    define_unary_element_wise :round

    # Round to a given multiple.
    #
    # Options are used to control the rounding multiple and rounding mode.
    # Default behavior is to round to the nearest integer and
    # use half-to-even rule to break ties.
    # @!method round_to_multiple(multiple: 1.0, round_mode: :half_to_even)
    # @param multiple [Float, Integer]
    #   Rounding scale (multiple to round to).
    #   Should be a positive numeric scalar of a type compatible with the argument
    #   to be rounded. The cast kernel is used to convert the rounding multiple
    #   to match the result type.
    # @macro round_mode
    # @return [Vector]
    #   round to multiple of each element of self.
    #
    def round_to_multiple(multiple: 1.0, round_mode: :half_to_even)
      datum = exec_func_unary(:round_to_multiple,
                              multiple: Arrow::DoubleScalar.new(multiple),
                              round_mode: round_mode)
      Vector.create(datum.value)
    end

    # Get the signedness of the arguments element-wise.
    #
    # Output is any of (-1,1) for nonzero inputs and 0 for zero input.
    # NaN values return NaN. Integral values return signedness as Int8 and
    # floating-point values return it with the same type as the input values.
    # @return [Vector]
    #   sign of each element of self.
    #
    define_unary_element_wise :sign

    # Compute the sine of self element-wise.
    #
    # NaN is returned for invalid input values.
    # @return [Vector]
    #   sine of each element of self.
    #
    define_unary_element_wise :sin

    # Compute the sine of self element-wise.
    #
    # This function is a overflow-checking variant of #sin.
    # @return (see #sin)
    #
    define_unary_element_wise :sin_checked

    # Compute square root of self.
    #
    # NaN is returned for invalid input values.
    # @return [Vector]
    #   sqrt of each element of self.
    #
    define_unary_element_wise :sqrt

    # Compute square root of self.
    #
    # This function is a overflow-checking variant of #sqrt.
    # @return (see #sqrt)
    #
    define_unary_element_wise :sqrt_checked

    # Compute the tangent of self element-wise.
    #
    # NaN is returned for invalid input values.
    # @return [Vector]
    #   tangent of each element of self.
    #
    define_unary_element_wise :tan

    # Compute the tangent of self element-wise.
    #
    # This function is a overflow-checking variant of #tan.
    # @return (see #tan)
    #
    define_unary_element_wise :tan_checked

    # Compute the integral part
    #
    # Compute the nearest integer not greater in magnitude than each element.
    # @return [Vector]
    #   trunc of each element of self.
    #
    define_unary_element_wise :trunc

    # Compute unique elements
    #
    # Return an array with distinct values.  Nils in the input are ignored.
    # @return [Vector]
    #   uniq element of self.
    #
    define_unary_element_wise :unique
    alias_method :uniq, :unique

    # Invert boolean values
    #
    # @return [Vector]
    #   not of each element of self.
    #
    define_unary_element_wise :invert
    alias_method :'!', :invert # rubocop:disable Lint/SymbolConversion
    alias_method :not, :invert

    # Negate the argument element-wise
    #
    # Results will wrap around on integer overflow.
    # @return [Vector]
    #   negate of each element of self.
    #
    define_unary_element_wise :negate
    alias_method :'-@', :negate # rubocop:disable Lint/SymbolConversion

    # Negate the argument element-wise
    #
    # This function is a overflow-checking variant of #negate.
    # @return (see #negate)
    #
    define_unary_element_wise :negate_checked
  end
end
