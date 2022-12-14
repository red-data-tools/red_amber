# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

# Not implemented in Red Arrow 8.0.0
# divmod,  # '%',
# true_unless_null

module RedAmber
  # mix-ins for class Vector
  module VectorFunctions
    # [Unary aggregations]: vector.func => scalar
    unary_aggregations =
      %i[all any approximate_median count count_distinct max mean min min_max
         product stddev sum variance]
    unary_aggregations.each do |function|
      define_method(function) do |**options|
        datum = exec_func_unary(function, options)
        get_scalar(datum)
      end
    end
    alias_method :median, :approximate_median
    alias_method :count_uniq, :count_distinct
    alias_method :all?, :all
    alias_method :any?, :any

    def unbiased_variance
      variance(ddof: 1)
    end
    alias_method :var, :unbiased_variance

    def sd
      stddev(ddof: 1)
    end
    alias_method :std, :sd

    # Return quantile
    #   0.5 quantile (median) is returned by default.
    #   Or return quantile for specified probability (prob).
    #   If quantile lies between two data points, interpolated value is
    #   returned based on selected interpolation method.
    #   Nils and NaNs are ignored.
    #   Nil is returned if there are no valid data point.
    #
    # @param prob [Float] probability.
    # @param interpolation [Symbol] specifies interpolation method to use,
    #   when the quantile lies between the data i and j.
    #   - Default value is :linear, which returns i + (j - i) * fraction.
    #   - :lower returns i.
    #   - :higher returns j.
    #   - :nearest returns i or j, whichever is closer.
    #   - :midpoint returns (i + j) / 2.
    # @param skip_nils [Boolean] wheather to ignore nil.
    # @param min_count [Integer] min count.
    # @return [Float] quantile.
    def quantile(prob = 0.5, interpolation: :linear, skip_nils: true, min_count: 0)
      unless (0..1).cover? prob
        raise VectorArgumentError,
              "Invalid: probability #{prob} must be between 0 and 1"
      end

      datum = find(:quantile).execute([data],
                                      q: prob,
                                      interpolation: interpolation,
                                      skip_nulls: skip_nils,
                                      min_count: min_count)
      datum.value.to_a.first
    end

    # Return quantiles in a DataFrame
    #
    def quantiles(probs = [1.0, 0.75, 0.5, 0.25, 0.0],
                  interpolation: :linear, skip_nils: true, min_count: 0)
      if probs.empty? || !probs.all? { |q| (0..1).cover?(q) }
        raise VectorArgumentError, "Invarid probavilities #{probs}"
      end

      DataFrame.new(
        probs: probs,
        quantiles: probs.map do |q|
          quantile(q,
                   interpolation: interpolation, skip_nils: skip_nils,
                   min_count: min_count)
        end
      )
    end

    # [Unary element-wise]: vector.func => vector
    unary_element_wise =
      %i[abs acos asin array_sort_indices atan bit_wise_not ceil cos
         fill_null_backward fill_null_forward floor
         is_finite is_inf is_nan is_null is_valid ln log10 log1p log2
         round round_to_multiple sign sin tan trunc unique]
    unary_element_wise.each do |function|
      define_method(function) do |**options|
        datum = exec_func_unary(function, options)
        Vector.create(datum.value)
      end
    end
    alias_method :is_nil, :is_null

    def is_na
      numeric? ? (is_nil | is_nan) : is_nil
    end

    alias_method :fill_nil_backward, :fill_null_backward
    alias_method :fill_nil_forward, :fill_null_forward

    alias_method :sort_indexes, :array_sort_indices
    alias_method :sort_indices, :array_sort_indices
    alias_method :sort_index, :array_sort_indices

    alias_method :uniq, :unique

    # [Unary element-wise with operator]: vector.func => vector, op vector
    unary_element_wise_op = {
      invert: '!',
      negate: '-@',
    }
    unary_element_wise_op.each do |function, operator|
      define_method(function) do |**options|
        datum = exec_func_unary(function, options)
        Vector.create(datum.value)
      end

      define_method(operator) do |**options|
        datum = exec_func_unary(function, options)
        Vector.create(datum.value)
      end
    end
    alias_method :not, :invert

    # [Binary element-wise]: vector.func(other) => vector
    binary_element_wise =
      %i[atan2 and_not and_not_kleene bit_wise_and bit_wise_or bit_wise_xor logb]
    binary_element_wise.each do |function|
      define_method(function) do |other, **options|
        datum = exec_func_binary(function, other, options)
        Vector.create(datum.value)
      end
    end

    # [Logical binary element-wise]: vector.func(other) => vector
    logical_binary_element_wise = {
      '&': :and_kleene,
      and_kleene: :and_kleene,
      and_org: :and,
      '|': :or_kleene,
      or_kleene: :or_kleene,
      or_org: :or,
    }
    logical_binary_element_wise.each do |method, function|
      define_method(method) do |other, **options|
        datum = exec_func_binary(function, other, options)
        Vector.create(datum.value)
      end
    end

    # [Binary element-wise with operator]: vector.func(other) => vector
    binary_element_wise_op = {
      add: '+',
      divide: '/',
      multiply: '*',
      power: '**',
      subtract: '-',

      xor: '^',
      shift_left: '<<',
      shift_right: '>>',

      equal: '==',
      greater: '>',
      greater_equal: '>=',
      less: '<',
      less_equal: '<=',
      not_equal: '!=',
    }
    binary_element_wise_op.each do |function, operator|
      define_method(function) do |other, **options|
        datum = exec_func_binary(function, other, options)
        Vector.create(datum.value)
      end

      define_method(operator) do |other, **options|
        datum = exec_func_binary(function, other, options)
        Vector.create(datum.value)
      end
    end
    alias_method :eq, :equal
    alias_method :ge, :greater_equal
    alias_method :gt, :greater
    alias_method :le, :less_equal
    alias_method :lt, :less
    alias_method :ne, :not_equal

    def coerce(other)
      [Vector.new(Array(other) * size), self]
    end

    private # =======

    def exec_func_unary(function, options)
      options = nil if options.empty?
      find(function).execute([data], options)
    end

    def exec_func_binary(function, other, options)
      options = nil if options.empty?
      case other
      when Vector
        find(function).execute([data, other.data], options)
      when Arrow::Array, Arrow::ChunkedArray, Arrow::Scalar,
           Array, Numeric, String, TrueClass, FalseClass
        find(function).execute([data, other], options)
      end
    end

    def get_scalar(datum)
      output = datum.value
      case output
      when Arrow::StringScalar then output.to_s
      when Arrow::StructScalar
        output.value.map { |s| s.is_a?(Arrow::StringScalar) ? s.to_s : s.value }
      else
        output.value
      end
    end

    module_function # ======

    def find(function_name)
      Arrow::Function.find(function_name)
    end

    # temporary API until RedAmber document prepared.
    def arrow_doc(function_name)
      f = find(function_name)
      "#{f}\n#{'-' * function_name.size}\n#{f.doc.description}"
    end
  end
end
