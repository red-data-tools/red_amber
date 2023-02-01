# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      private

      def define_unary_element_wise(function)
        define_method(function) do |**options|
          datum = exec_func_unary(function, options)
          Vector.create(datum.value)
        end
      end

      def define_unary_element_wise_operator(function, operator)
        define_method(function) do |**options|
          datum = exec_func_unary(function, options)
          Vector.create(datum.value)
        end

        define_method(operator) do |**options|
          datum = exec_func_unary(function, options)
          Vector.create(datum.value)
        end
      end
    end

    # [Unary element-wise]: vector.func => vector

    define_unary_element_wise(:abs)

    define_unary_element_wise(:acos)

    define_unary_element_wise(:asin)

    define_unary_element_wise(:array_sort_indices)
    alias_method :sort_indexes, :array_sort_indices
    alias_method :sort_indices, :array_sort_indices
    alias_method :sort_index, :array_sort_indices

    define_unary_element_wise(:atan)

    define_unary_element_wise(:bit_wise_not)

    define_unary_element_wise(:ceil)

    define_unary_element_wise(:cos)

    define_unary_element_wise(:fill_null_backward)
    alias_method :fill_nil_backward, :fill_null_backward

    define_unary_element_wise(:fill_null_forward)
    alias_method :fill_nil_forward, :fill_null_forward

    define_unary_element_wise(:floor)

    define_unary_element_wise(:is_finite)

    define_unary_element_wise(:is_inf)

    def is_na # rubocop:disable Naming/PredicateName
      numeric? ? (is_nil | is_nan) : is_nil
    end

    define_unary_element_wise(:is_nan)

    define_unary_element_wise(:is_null)
    alias_method :is_nil, :is_null

    define_unary_element_wise(:is_valid)

    define_unary_element_wise(:ln)

    define_unary_element_wise(:log10)

    define_unary_element_wise(:log1p)

    define_unary_element_wise(:log2)

    define_unary_element_wise(:round)

    define_unary_element_wise(:round_to_multiple)

    define_unary_element_wise(:sign)

    define_unary_element_wise(:sin)

    define_unary_element_wise(:tan)

    define_unary_element_wise(:trunc)

    define_unary_element_wise(:unique)

    alias_method :uniq, :unique

    # [Unary element-wise with operator]: vector.func => vector, op vector

    define_unary_element_wise_operator(:invert, '!')
    alias_method :not, :invert

    define_unary_element_wise_operator(:negate, '-@')
  end
end
