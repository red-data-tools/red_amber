# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      # Compute the inverse tangent of y/x.
      #
      # [Binary element-wise function] Returns a Vector.
      # The return value is in the range [-pi, pi].
      # @param y [Vector, array-like]
      #   numeric array-like.
      # @param x [Vector, array-like]
      #   numeric array-like.
      # @return [Vector]
      #   inverse tangent of y/x.
      #
      def atan2(y, x) # rubocop:disable Naming/MethodParameterName
        y = y.data if y.is_a? Vector
        x = x.data if x.is_a? Vector

        datum = Arrow::Function.find(:atan2).execute([y, x])
        Vector.create(datum.value)
      end

      private

      # @!macro [attach] define_binary_element_wise
      #   [Binary element-wise function] Returns a Vector.
      #
      def define_binary_element_wise(function)
        define_method(function) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end
      end

      # @!macro [attach] define_binary_element_wise_logical
      #   [Binary element-wise function] Returns a Vector.
      #
      def define_binary_element_wise_logical(method, function)
        define_method(method) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end
      end
    end

    # @!macro kleene_logic_and
    #   This function behaves as follows with nils:
    #   - true and nil = nil
    #   - nil and true = nil
    #   - false and nil = false
    #   - nil and false = false
    #   - nil and nil = nil
    #   In other words, in this context a nil value really means "unknown",
    #   and an unknown value 'and' false is always false.

    # @!macro kleene_logic_and_not
    #   This function behaves as follows with nils:
    #   - true and not nil = nil
    #   - nil and not false = nil
    #   - false and not nil = false
    #   - nil and not true = false
    #   - nil and not nil = nil
    #   In other words, in this context a nil value really means "unknown",
    #   and an unknown value 'and not' true is always false,
    #   as is false 'and not' an unknown value.

    # @!macro kleene_logic_or
    #   This function behaves as follows with nils:
    #   - true or nil = true
    #   - nil or true = true
    #   - false or nil = nil
    #   - nil or false = nil
    #   - nil or nil = nil
    #   In other words, in this context a nil value really means "unknown",
    #   and an unknown value 'or' true is always true.

    # rubocop:disable Lint/SymbolConversion)

    # Logical 'and' boolean values with Kleene logic.
    #
    # @macro kleene_logic_and
    # For a different nil behavior, see function {#and_org}.
    # @!method and_kleene(other)
    # @param other [Vector, array-like]
    #   boolean array-like.
    # @return [Vector]
    #   and_kleene of self and other.
    define_binary_element_wise :and_kleene
    alias_method :'&', :and_kleene

    # Logical 'and not' boolean values.
    #
    # When a nil is encountered in either input, a nil is output.
    # For a different nil behavior, see function {#and_not_kleene}.
    # @!method and_not(other)
    # @param other [Vector, array-like]
    #   boolean array-like.
    # @return [Vector]
    #   and not of self and other.
    #
    define_binary_element_wise :and_not

    # Logical 'and not' boolean values with Kleene logic.
    #
    # @macro kleene_logic_and_not
    # For a different nil behavior, see function {#and_not}.
    # @!method and_not_kleene(other)
    # @param other [Vector, array-like]
    #   boolean array-like.
    # @return [Vector]
    #   and not kleene of self and other.
    #
    define_binary_element_wise :and_not_kleene

    # Logical 'and' boolean values.
    #
    # When a nil is encountered in either input, a nil is output.
    # For a different nil behavior, see function {#and_kleene}.
    # @!method and_org(other)
    # @param other [Vector, array-like]
    #   boolean array-like.
    # @return [Vector]
    #   evacuated `and` of self and other.
    #
    define_binary_element_wise_logical(:and_org, :and)

    # Bit-wise AND of self and other by element-wise.
    #
    # Nil values return nil.
    # @!method bit_wise_and(other)
    # @param other [Vector, array-like]
    #   integer array-like.
    # @return [Vector]
    #   bit wise and of self and other.
    #
    define_binary_element_wise :bit_wise_and

    # Bit-wise OR of self and other by element-wise.
    #
    # Nil values return nil.
    # @!method bit_wise_or(other)
    # @param other [Vector, array-like]
    #   integer array-like.
    # @return [Vector]
    #   bit wise or of self and other.
    #
    define_binary_element_wise :bit_wise_or

    # Bit-wise XOR of self and other by element-wise.
    #
    # Nil values return nil.
    # @!method bit_wise_xor(other)
    # @param other [Vector, array-like]
    #   integer array-like.
    # @return [Vector]
    #   bit wise xor of self and other.
    #
    define_binary_element_wise :bit_wise_xor

    # Compute base `b` logarithm of self.
    #
    # Non positive values return -inf or NaN. Nil values return nil.
    # @!method logb(b)
    # @param b [Integer]
    #   base.
    # @return [Vector]
    #   logb of self and other.
    #
    define_binary_element_wise :logb

    # Compute base `b` logarithm of self.
    #
    # This function is a overflow-checking variant of #logb.
    # @return (see #logb)
    #
    define_binary_element_wise :logb_checked

    # Logical 'or' boolean values with Kleene logic.
    #
    # @macro kleene_logic_or
    # For a different nil behavior, see function {#or_org}.
    # @!method or_kleene(other)
    # @param other [Vector, array-like]
    #   boolean array-like.
    # @return [Vector]
    #   or_kleene of self and other.
    #
    define_binary_element_wise :or_kleene
    alias_method :'|', :or_kleene

    # Logical 'or' boolean values.
    #
    # When a nil is encountered in either input, a nil is output.
    # For a different nil behavior, see function {#or_kleene}.
    # @!method or_org(other)
    # @param other [Vector, array-like]
    #   boolean array-like.
    # @return [Vector]
    #   evacuated `or` of self and other.
    #
    define_binary_element_wise_logical(:or_org, :or)

    # Add the arguments element-wise.
    #
    # Results will wrap around on integer overflow.
    # @!method add(other)
    # @param other [Vector, Numeric]
    #   other numeric Vector or numeric scalar.
    # @return [Vector]
    #   adddition of self and other.
    #
    define_binary_element_wise :add
    alias_method :'+', :add

    # Add the arguments element-wise.
    #
    # This function is a overflow-checking variant of #add.
    # @return (see #add)
    #
    define_binary_element_wise :add_checked

    # Divide the arguments element-wise.
    #
    # Integer division by zero returns an error. However, integer overflow
    # wraps around, and floating-point division by zero returns an infinite.
    # @!method divide(divisor)
    # @param divisor [Vector, Numeric]
    #   numeric vector or numeric scalar as divisor.
    # @return [Vector]
    #   division of self by other.
    #
    define_binary_element_wise :divide
    alias_method :'/', :divide

    # Divide the arguments element-wise.
    #
    # This function is a overflow-checking variant of #divide.
    # @return (see #divide)
    #
    define_binary_element_wise :divide_checked

    # Returns element-wise modulo.
    #
    # This is equivalent to `self-divisor*(self/divisor).floor`.
    # @note Same behavior as Ruby.
    # @param divisor [Vector, numeric]
    #   divisor numeric Vector or numeric scalar.
    # @return [Vector]
    #   modulo of dividing self by divisor.
    #
    def modulo(divisor)
      divisor = divisor.data if divisor.is_a?(Vector)
      d = find(:divide).execute([data, divisor])
      d = find(:floor).execute([d]) if d.value.is_a?(Arrow::DoubleArray)
      m = find(:multiply).execute([d, divisor])
      datum = find(:subtract).execute([data, m])
      Vector.create(datum.value)
    end
    alias_method :'%', :modulo

    # Returns element-wise modulo.
    #
    # This function is a overflow-checking variant of #modulo.
    # @return (see #modulo)
    #
    def modulo_checked(divisor)
      divisor = divisor.data if divisor.is_a?(Vector)
      d = find(:divide_checked).execute([data, divisor])
      d = find(:floor).execute([d]) if d.value.is_a?(Arrow::DoubleArray)
      m = find(:multiply_checked).execute([d, divisor])
      datum = find(:subtract_checked).execute([data, m])
      Vector.create(datum.value)
    end

    # Multiply the arguments element-wise.
    #
    # Results will wrap around on integer overflow.
    # @!method multiply(other)
    # @param other [Vector, Numeric]
    #   other numeric vector or numeric scalar.
    # @return [Vector]
    #   multiplication of self and other.
    #
    define_binary_element_wise :multiply
    alias_method :mul, :multiply
    alias_method :'*', :multiply

    # Multiply the arguments element-wise.
    #
    # This function is a overflow-checking variant of #multiply.
    # @return (see #multiply)
    #
    define_binary_element_wise :multiply_checked

    # Raise arguments to power element-wise.
    #
    # Integer to negative integer power returns an error.
    # However, integer overflow wraps around.
    # If either self or exponent is nil the result will be nil.
    # @!method power(exponent)
    # @param exponent [Vector, Numeric]
    #   numeric vector or numeric scalar as exponent.
    # @return [Vector]
    #   power operation of self and other.
    #
    define_binary_element_wise :power
    alias_method :pow, :power
    alias_method :'**', :power

    # Raise arguments to power element-wise.
    #
    # This function is a overflow-checking variant of #power.
    # @return (see #power)
    #
    define_binary_element_wise :power_checked

    # Returns element-wise quotient by double Vector.
    #
    # @param divisor [Vector, numeric]
    #   divisor numeric Vector or numeric scalar.
    # @return [Vector]
    #   quotient of dividing self by divisor.
    #
    def fdiv(divisor)
      divisor = divisor.data if divisor.is_a?(Vector)
      datum = find(:divide).execute([Arrow::DoubleArray.new(data), divisor])
      Vector.create(datum.value)
    end

    # Returns element-wise quotient by double Vector.
    #
    # This function is a overflow-checking variant of #quotient.
    # @return (see #quotient)
    #
    def fdiv_checked(divisor)
      divisor = divisor.data if divisor.is_a?(Vector)
      datum = find(:divide_checked).execute([Arrow::DoubleArray.new(data), divisor])
      Vector.create(datum.value)
    end

    # Returns element-wise remainder.
    #
    # This is equivalent to `self-divisor*(self/divisor).trunc`.
    # @note Same behavior as Ruby's remainder.
    # @param divisor [Vector, numeric]
    #   divisor numeric Vector or numeric scalar.
    # @return [Vector]
    #   modulo of dividing self by divisor.
    #
    def remainder(divisor)
      divisor = divisor.data if divisor.is_a?(Vector)
      d = find(:divide).execute([data, divisor])
      d = find(:trunc).execute([d]) if d.value.is_a?(Arrow::DoubleArray)
      m = find(:multiply).execute([d, divisor])
      datum = find(:subtract).execute([data, m])
      Vector.create(datum.value)
    end

    # Returns element-wise modulo.
    #
    # This function is a overflow-checking variant of #modulo.
    # @return (see #modulo)
    #
    def remainder_checked(divisor)
      divisor = divisor.data if divisor.is_a?(Vector)
      d = find(:divide_checked).execute([data, divisor])
      d = find(:trunc).execute([d]) if d.value.is_a?(Arrow::DoubleArray)
      m = find(:multiply_checked).execute([d, divisor])
      datum = find(:subtract_checked).execute([data, m])
      Vector.create(datum.value)
    end

    # Subtract the arguments element-wise.
    #
    # Results will wrap around on integer overflow.
    # @!method subtract(other)
    # @param other [Vector, Numeric]
    #   other numeric vector or numeric scalar.
    # @return [Vector]
    #   subtraction of self and other.
    #
    define_binary_element_wise :subtract
    alias_method :sub, :subtract
    alias_method :'-', :subtract

    # Subtract the arguments element-wise.
    #
    # This function is a overflow-checking variant of #subtract.
    # @return (see #subtract)
    #
    define_binary_element_wise :subtract_checked

    # Left shift of self by other.
    #
    # The shift operates as if on the two's complement representation of the number.
    # In other words, this is equivalent to multiplying self by 2 to the power 'amount',
    # even if overflow occurs.
    # self is returned if 'amount' (the amount to shift by) is negative or
    # greater than or equal to the precision of self.
    # @!method shift_left(amount)
    # @param amount [integer]
    #   the amount to shift by.
    # @return [Vector]
    #  shift_left of self by amount.
    #
    define_binary_element_wise :shift_left
    alias_method :'<<', :shift_left

    # Left shift of self by other.
    #
    # This function is a overflow-checking variant of #shift_left.
    # @return (see #shift_left)
    #
    define_binary_element_wise :shift_left_checked

    # Right shift of self by other.
    #
    # This is equivalent to dividing `x` by 2 to the power `y`.
    # Self is returned if 'amount' (the amount to shift by) is: negative or
    # greater than or equal to the precision of self.
    # @!method shift_right(amount)
    # @param amount [integer]
    #   the amount to shift by.
    # @return [Vector]
    #   shift_right of self by amount.
    #
    define_binary_element_wise :shift_right
    alias_method :'>>', :shift_right

    # Right shift of self by other.
    #
    # This function is a overflow-checking variant of #shift_right.
    # @return (see #shift_right)
    #
    define_binary_element_wise :shift_right_checked

    # Logical 'xor' boolean values
    #
    # When a nil is encountered in either input, a nil is output.
    # @!method xor(other)
    # @param other [Vector]
    #   other boolean vector or boolean scalar.
    # @return [Vector]
    #   eq of self and other by a boolean Vector.
    #
    define_binary_element_wise :xor
    alias_method :'^', :xor

    # Compare values for equality (self == other)
    #
    # A nil on either side emits a nil comparison result.
    # @!method equal(other)
    # @param other [Vector]
    #   other vector or scalar.
    # @return [Vector]
    #   eq of self and other by a boolean Vector.
    #
    define_binary_element_wise :equal
    alias_method :'==', :equal
    alias_method :eq, :equal

    # Compare values for ordered inequality (self > other).
    #
    # A nil on either side emits a nil comparison result.
    # @!method greater(other)
    # @param other [Vector]
    #   other vector or scalar.
    # @return [Vector]
    #   gt of self and other by a boolean Vector.
    #
    define_binary_element_wise :greater
    alias_method :'>', :greater
    alias_method :gt, :greater

    # Compare values for ordered inequality (self >= other).
    #
    # A nil on either side emits a nil comparison result.
    # @!method greater_equal(other)
    # @param other [Vector]
    #   other vector or scalar.
    # @return [Vector]
    #   ge of self and other by a boolean Vector.
    #
    define_binary_element_wise :greater_equal
    alias_method :'>=', :greater_equal
    alias_method :ge, :greater_equal

    # Compare values for ordered inequality (self < other).
    #
    # A nil on either side emits a nil comparison result.
    # @!method less(other)
    # @param other [Vector]
    #   other vector or scalar.
    # @return [Vector]
    #   lt of self and other by a boolean Vector.
    #
    define_binary_element_wise :less
    alias_method :'<', :less
    alias_method :lt, :less

    # Compare values for ordered inequality (self <= other).
    #
    # A nil on either side emits a nil comparison result.
    # @!method less_equal(other)
    # @param other [Vector]
    #   other vector or scalar.
    # @return [Vector]
    #   le of self and other by a boolean Vector.
    #
    define_binary_element_wise :less_equal
    alias_method :'<=', :less_equal
    alias_method :le, :less_equal

    # Compare values for inequality (self != other).
    #
    # A nil on either side emits a nil comparison result.
    # @!method not_equal(other)
    # @param other [Vector]
    #   other vector or scalar.
    # @return [Vector]
    #   ne of self and other by a boolean Vector.
    #
    define_binary_element_wise :not_equal
    alias_method :'!=', :not_equal
    alias_method :ne, :not_equal

    # rubocop:enable Lint/SymbolConversion)
  end
end
