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
      %i[all any approximate_median count count_distinct max mean min min_max product stddev sum variance]
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

    # option(s) required
    # - index

    # Returns other than value
    # - mode
    # - tdigest

    # Return quantiles in a Vector
    #   0.5 quantiles (median) are returned by default.
    #   Or return quantiles for specified probability (q).
    #   If quantile lies between two data points, interpolated value is
    #   returned based on selected interpolation method.
    #   Nils and NaNs are ignored.
    #   An array of nils are returned if there are no valid data point.
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
    # @return [Float, Array<Float>] quantile(s).
    def quantile(prob = 0.5, interpolation: :linear, skip_nils: true, min_count: 0)
      raise VectorArgumentError, "Invalid: probability #{prob} must be between 0 and 1" unless (0..1).cover? prob

      datum = find(:quantile).execute([data],
                                      q: prob,
                                      interpolation: interpolation,
                                      skip_nulls: skip_nils,
                                      min_count: min_count)
      datum.value.to_a.first
    end

    # [Unary element-wise]: vector.func => vector
    unary_element_wise =
      %i[abs array_sort_indices atan bit_wise_not ceil cos fill_null_backward fill_null_forward floor is_finite
         is_inf is_nan is_null is_valid round round_to_multiple sign sin tan trunc unique]
    unary_element_wise.each do |function|
      define_method(function) do |**options|
        datum = exec_func_unary(function, options)
        Vector.new(datum.value)
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

    alias_method :uniq, :unique

    # [Unary element-wise with operator]: vector.func => vector, op vector
    unary_element_wise_op = {
      invert: '!',
      negate: '-@',
    }
    unary_element_wise_op.each do |function, operator|
      define_method(function) do |**options|
        datum = exec_func_unary(function, options)
        Vector.new(datum.value)
      end

      define_method(operator) do |**options|
        datum = exec_func_unary(function, options)
        Vector.new(datum.value)
      end
    end
    alias_method :not, :invert

    # NaN support needed
    # - acos asin ln log10 log1p log2

    # Functions with numerical range check
    # - abs_checked acos_checked asin_checked cos_checked ln_checked
    #   log10_checked log1p_checked log2_checked sin_checked tan_checked

    # [Binary element-wise]: vector.func(other) => vector
    binary_element_wise =
      %i[atan2 and_not and_not_kleene bit_wise_and bit_wise_or bit_wise_xor]
    binary_element_wise.each do |function|
      define_method(function) do |other, **options|
        datum = exec_func_binary(function, other, options)
        Vector.new(datum.value)
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
        Vector.new(datum.value)
      end
    end

    # NaN support needed
    # - logb

    # Functions with numerical range check
    # - add_checked divide_checked logb_checked multiply_checked power_checked subtract_checked
    #   shift_left_checked shift_right_checked

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
        Vector.new(datum.value)
      end

      define_method(operator) do |other, **options|
        datum = exec_func_binary(function, other, options)
        Vector.new(datum.value)
      end
    end
    alias_method :eq, :equal
    alias_method :ge, :greater_equal
    alias_method :gt, :greater
    alias_method :le, :less_equal
    alias_method :lt, :less
    alias_method :ne, :not_equal

    def coerce(other)
      case other
      when Vector, Array, Arrow::Array
        raise VectorArgumentError, "Size unmatch: #{size} != #{other.length}" unless size == other.length

        [Vector.new(Array(other)), self]
      end
      [Vector.new(Array(other) * size), self]
    end

    # (array functions)
    # dictionary_encode,
    # partition_nth_indices,
    # quarter, quarters_between,

    # (strings)
    # ascii_capitalize, ascii_center, ascii_is_alnum, ascii_is_alpha, ascii_is_decimal,
    # ascii_is_lower, ascii_is_printable, ascii_is_space, ascii_is_title, ascii_is_upper,
    # ascii_lower, ascii_lpad, ascii_ltrim, ascii_ltrim_whitespace, ascii_reverse,
    # ascii_rpad, ascii_rtrim, ascii_rtrim_whitespace, ascii_split_whitespace,
    # ascii_swapcase, ascii_title, ascii_trim, ascii_trim_whitespace, ascii_upper,
    # binary_join, binary_join_element_wise, binary_length, binary_repeat,
    # binary_replace_slice, binary_reverse, count_substring, count_substring_regex,
    # ends_with, extract_regex, find_substring, find_substring_regex,
    # match_like, match_substring, match_substring_regex, replace_substring,
    # replace_substring_regex, split_pattern, split_pattern_regex, starts_with,
    # string_is_ascii, utf8_capitalize, utf8_center, utf8_is_alnum, utf8_is_alpha,
    # utf8_is_decimal, utf8_is_digit, utf8_is_lower, utf8_is_numeric, utf8_is_printable,
    # utf8_is_space, utf8_is_title, utf8_is_upper, utf8_length, utf8_lower, utf8_lpad,
    # utf8_ltrim, utf8_ltrim_whitespace, utf8_normalize, utf8_replace_slice, utf8_reverse,
    # utf8_rpad, utf8_rtrim, utf8_rtrim_whitespace, utf8_slice_codeunits, utf8_split_whitespace,
    # utf8_swapcase, utf8_title, utf8_trim, utf8_trim_whitespace, utf8_upper

    # (temporal)
    # assume_timezone, ceil_temporal, day, day_of_week, day_of_year, day_time_interval_between,
    # days_between, floor_temporal, hour, hours_between, iso_calendar, iso_week, iso_year,
    # microsecond, microseconds_between, millisecond, milliseconds_between, minute,
    # minutes_between, month, month_day_nano_interval_between, month_interval_between,
    # nanosecond, nanoseconds_between, round_temporal, second, seconds_between, strftime,
    # strptime, subsecond, us_week, week, weeks_between, year, year_month_day, years_between

    # (onditional)
    # case_when, cast,

    # (indices)
    # choose, index_in, index_in_meta_binary, indices_nonzero

    # (others)
    # coalesce,
    # is_in_meta_binary,
    # list_element, list_flatten, list_parent_indices, list_value_length, make_struct,
    # max_element_wise, min_element_wise, random, select_k_unstable,
    # struct_field,

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
      when Arrow::Array, Arrow::ChunkedArray, Arrow::Scalar, Array, Numeric, String, TrueClass, FalseClass
        find(function).execute([data, other], options)
      else
        raise VectorArgumentError, "Operand is not supported: #{other.class}"
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
