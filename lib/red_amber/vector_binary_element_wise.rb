# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      private

      def define_binary_element_wise(function)
        define_method(function) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end
      end

      def define_binary_element_wise_logical(method, function)
        define_method(method) do |other, **options|
          datum = exec_func_binary(function, other, options)
          Vector.create(datum.value)
        end
      end

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

    # [Binary element-wise]: vector.func(other) => vector

    define_binary_element_wise(:atan2)

    define_binary_element_wise(:and_not)

    define_binary_element_wise(:and_not_kleene)

    define_binary_element_wise(:bit_wise_and)

    define_binary_element_wise(:bit_wise_or)

    define_binary_element_wise(:bit_wise_xor)

    define_binary_element_wise(:logb)

    # [Logical binary element-wise]: vector.func(other) => vector

    define_binary_element_wise_logical(:'&', :and_kleene) # rubocop:disable Lint/SymbolConversion)

    define_binary_element_wise_logical(:and_kleene, :and_kleene)

    define_binary_element_wise_logical(:and_org, :and)

    define_binary_element_wise_logical(:'|', :or_kleene) # rubocop:disable Lint/SymbolConversion)

    define_binary_element_wise_logical(:or_kleene, :or_kleene)

    define_binary_element_wise_logical(:or_org, :or)

    # [Binary element-wise with operator]: vector.func(other) => vector

    define_binary_element_wise_operator(:add, '+')

    define_binary_element_wise_operator(:divide, '/')

    define_binary_element_wise_operator(:multiply, '*')

    define_binary_element_wise_operator(:power, '**')

    define_binary_element_wise_operator(:subtract, '-')

    define_binary_element_wise_operator(:xor, '^')

    define_binary_element_wise_operator(:shift_left, '<<')

    define_binary_element_wise_operator(:shift_right, '>>')

    define_binary_element_wise_operator(:equal, '==')
    alias_method :eq, :equal

    define_binary_element_wise_operator(:greater, '>')
    alias_method :gt, :greater

    define_binary_element_wise_operator(:greater_equal, '>=')
    alias_method :ge, :greater_equal

    define_binary_element_wise_operator(:less, '<')
    alias_method :lt, :less

    define_binary_element_wise_operator(:less_equal, '<=')
    alias_method :le, :less_equal

    define_binary_element_wise_operator(:not_equal, '!=')
    alias_method :ne, :not_equal
  end
end
