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
      #   @!method $1(other)
      #   [Binary element-wise function] Returns a Vector.
      #   @param other [Vector] other operand.
      #
      def define_binary_element_wise(function)
        define_method(function) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end
      end

      # @!macro [attach] define_binary_element_wise_logical
      #   @!method $1(other)
      #   [Binary element-wise function] Returns a Vector.
      #   @param other [Vector] other operand.
      #
      def define_binary_element_wise_logical(method, function)
        define_method(method) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end
      end

      # @!macro [attach] define_binary_element_wise_operator
      #   @!method $1(other)
      #   [Binary element-wise function] Returns a Vector.
      #
      #   @!method $2(other)
      #
      def define_binary_element_wise_operator(function, operator)
        define_method(function) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end

        define_method(operator) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end
      end
    end

    # @return [Vector] and not of self and other.
    define_binary_element_wise(:and_not)

    # @return [Vector] and not kleene of self and other.
    define_binary_element_wise(:and_not_kleene)

    # @return [Vector] bit wise and of self and other.
    define_binary_element_wise(:bit_wise_and)

    # @return [Vector] bit wise or of self and other.
    define_binary_element_wise(:bit_wise_or)

    # @return [Vector] bit wise xor of self and other.
    define_binary_element_wise(:bit_wise_xor)

    # @return [Vector] logb of self and other.
    define_binary_element_wise(:logb)

    # @return [Vector] & of self and other.
    define_binary_element_wise_logical(:'&', :and_kleene) # rubocop:disable Lint/SymbolConversion)

    # @return [Vector] & of self and other.
    define_binary_element_wise_logical(:and_kleene, :and_kleene)

    # @return [Vector] evacuated `and`` of self and other.
    define_binary_element_wise_logical(:and_org, :and)

    # @return [Vector] | of self and other.
    define_binary_element_wise_logical(:'|', :or_kleene) # rubocop:disable Lint/SymbolConversion)

    # @return [Vector] | of self and other.
    define_binary_element_wise_logical(:or_kleene, :or_kleene)

    # @return [Vector] evacuated `or` of self and other.
    define_binary_element_wise_logical(:or_org, :or)

    # @param other [Vector, Numeric] other operand.
    # @return [Vector] adddition of self and other.
    define_binary_element_wise_operator(:add, '+')

    # @param other [Vector, Numeric] other operand.
    # @return [Vector] division of self and other.
    define_binary_element_wise_operator(:divide, '/')

    # @param other [Vector, Numeric] other operand.
    # @return [Vector] multiplication of self and other.
    define_binary_element_wise_operator(:multiply, '*')

    # @param other [Vector, Numeric] other operand.
    # @return [Vector] power operation of self and other.
    define_binary_element_wise_operator(:power, '**')

    # @param other [Vector, Numeric] other operand.
    # @return [Vector] subtraction of self and other.
    define_binary_element_wise_operator(:subtract, '-')

    # @param other [Vector] other operand.
    # @return [Vector] xor of self and other.
    define_binary_element_wise_operator(:xor, '^')

    # @param other [integer] amount of shift.
    # @return [Vector] shift left of self by other.
    define_binary_element_wise_operator(:shift_left, '<<')

    # @param other [integer] amount of shift.
    # @return [Vector] shift right of self by other.
    define_binary_element_wise_operator(:shift_right, '>>')

    # @param other [Vector] other operand.
    # @return [Vector] eq of self and other by a boolean Vector.
    define_binary_element_wise_operator(:xor, '^')
    define_binary_element_wise_operator(:equal, '==')
    alias_method :eq, :equal

    # @param other [Vector] other operand.
    # @return [Vector] gt of self and other by a boolean Vector.
    define_binary_element_wise_operator(:greater, '>')
    alias_method :gt, :greater

    # @param other [Vector] other operand.
    # @return [Vector] ge of self and other by a boolean Vector.
    define_binary_element_wise_operator(:greater_equal, '>=')
    alias_method :ge, :greater_equal

    # @param other [Vector] other operand.
    # @return [Vector] lt of self and other by a boolean Vector.
    define_binary_element_wise_operator(:less, '<')
    alias_method :lt, :less

    # @param other [Vector] other operand.
    # @return [Vector] le of self and other by a boolean Vector.
    define_binary_element_wise_operator(:less_equal, '<=')
    alias_method :le, :less_equal

    # @param other [Vector] other operand.
    # @return [Vector] ne of self and other by a boolean Vector.
    define_binary_element_wise_operator(:not_equal, '!=')
    alias_method :ne, :not_equal
  end
end
