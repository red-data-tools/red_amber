# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      private

      # @!macro [attach] define_unary_element_wise
      #   @!method $1
      #   [Unary element-wise function] Returns a Vector.
      #
      def define_unary_element_wise(function)
        define_method(function) do |**options|
          datum = exec_func_unary(function, options)
          Vector.create(datum.value)
        end
      end

      # @!macro [attach] define_unary_element_wise_operator
      #   @!method $1
      #   [Unary element-wise function] Returns a Vector.
      #
      #   @!method $2
      #
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

    # @return [Vector] abs of each element of self.
    define_unary_element_wise(:abs)

    # @return [Vector] acos of each element of self.
    define_unary_element_wise(:acos)

    # @return [Vector] asin of each element of self.
    define_unary_element_wise(:asin)

    # @return [Vector] sort indices of self.
    define_unary_element_wise(:array_sort_indices)
    alias_method :sort_indexes, :array_sort_indices
    alias_method :sort_indices, :array_sort_indices
    alias_method :sort_index, :array_sort_indices

    # @return [Vector] atan of each element of self.
    define_unary_element_wise(:atan)

    # @return [Vector] bit wise not of each element of self.
    define_unary_element_wise(:bit_wise_not)

    # @return [Vector] ceil of each element of self.
    define_unary_element_wise(:ceil)

    # @return [Vector] cos of each element of self.
    define_unary_element_wise(:cos)

    # @return [Vector] a Vector which filled nil foward..
    define_unary_element_wise(:fill_null_backward)
    alias_method :fill_nil_backward, :fill_null_backward

    # @return [Vector] a Vector which filled nil foward.
    define_unary_element_wise(:fill_null_forward)
    alias_method :fill_nil_forward, :fill_null_forward

    # @return [Vector] floor of each element of self.
    define_unary_element_wise(:floor)

    # @return [Vector] boolean Vector wheather each element is finite.
    define_unary_element_wise(:is_finite)

    # @return [Vector] boolean Vector wheather each element is inf.
    define_unary_element_wise(:is_inf)

    # @return [Vector] boolean Vector wheather each element is na.
    def is_na # rubocop:disable Naming/PredicateName
      numeric? ? (is_nil | is_nan) : is_nil
    end

    # @return [Vector] boolean Vector wheather each element is nan.
    define_unary_element_wise(:is_nan)

    # @return [Vector] boolean Vector wheather each element is null.
    define_unary_element_wise(:is_null)
    alias_method :is_nil, :is_null

    # @return [Vector] boolean Vector wheather each element is valid.
    define_unary_element_wise(:is_valid)

    # @return [Vector] ln of each element of self.
    define_unary_element_wise(:ln)

    # @return [Vector] log10 of each element of self.
    define_unary_element_wise(:log10)

    # @return [Vector] log1p of each element of self.
    define_unary_element_wise(:log1p)

    # @return [Vector] log2 of each element of self.
    define_unary_element_wise(:log2)

    # @return [Vector] round of each element of self.
    define_unary_element_wise(:round)

    # @return [Vector] round to multiple of each element of self.
    define_unary_element_wise(:round_to_multiple)

    # @return [Vector] sign of each element of self.
    define_unary_element_wise(:sign)

    # @return [Vector] sin of each element of self.
    define_unary_element_wise(:sin)

    # @return [Vector] tan of each element of self.
    define_unary_element_wise(:tan)

    # @return [Vector] trunc of each element of self.
    define_unary_element_wise(:trunc)

    # @return [Vector] uniq element of self.
    define_unary_element_wise(:unique)
    alias_method :uniq, :unique

    # @return [Vector] not of each element of self.
    define_unary_element_wise_operator(:invert, '!')
    alias_method :not, :invert

    # @return [Vector] negate of each element of self.
    define_unary_element_wise_operator(:negate, '-@')
  end
end
