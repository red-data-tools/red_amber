# frozen_string_literal: true

module RedAmber
  # mix-ins for class Vector
  module VectorFunctions
    # Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
    # reference: https://arrow.apache.org/docs/cpp/compute.html

    # Unary aggregations: vector.func => Scalar
    unary_aggregations =
      %i[all any approximate_median count count_distinct max mean min \
         product stddev sum variance]
    unary_aggregations.each do |function|
      define_method(function) do
        exec_func(function, other: nil, options: { aggregate: true })
      end
    end

    alias_method :count_uniq, :count_distinct

    # option(s) required
    # index

    # Returns other than value
    # min_max
    # mode
    # quantile
    # tdigest

    # unary element-wise: vector.func => Vector
    unary_element_wise =
      %i[abs atan ceil cos floor sign sin tan]
    unary_element_wise.each do |function|
      define_method(function) do
        exec_func(function, other: nil, options: {})
      end
    end

    # unary element-wise: vector.func => Vector, with operator defined
    define_method(:-@) { exec_func(:negate) }
    define_method(:negate) { exec_func(:negate) }

    # %i[acos asin ln log10 log1p log2 ] # NaN support needed
    # %i[abs_checked acos_checked asin_checked cos_checked ln_checked \
    #    log10_checked log1p_checked log2_checked sin_checked tan_checked]
    # bit_wise_not, invert, round, round_to_multiple, trunc

    # vector.func(other) => Vector, with operator defined
    binary_methods_op = {
      add: '+', # :add_checked,
      subtract: '-', # subtract_checked
      multiply: '*', # multiply_checked
      divide: '/', # divide_checked
      power: '**',
      bit_wise_and: '&',
      bit_wise_or: '|',
      bit_wise_xor: '^',
      equal: '==',
      greater: '>',
      greater_equal: '>=',
      less: '<',
      less_equal: '<=',

      # mod: # '%',
      # 'xor' => :xor,
      # atan2, logb(checked),
      # shift_left(checked), shift_right(checked)
    }
    binary_methods_op.each do |function, operator|
      define_method(operator) do |other|
        exec_func(function, other: other)
      end
    end

    # array functions
    # array_filter, array_sort_indices, array_take
    # dictionary_encode, hash_all, hash_any, hash_approximate_median,
    # hash_count, hash_count_distinct, hash_distinct, hash_max, hash_mean, hash_min,
    # hash_min_max, hash_product, hash_stddev, hash_sum, hash_tdigest, hash_variance,
    # partition_nth_indices,
    # quarter, quarters_between, unique,
    # value_counts

    # strings
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

    # times
    # assume_timezone, ceil_temporal, day, day_of_week, day_of_year, day_time_interval_between,
    # days_between, floor_temporal, hour, hours_between, iso_calendar, iso_week, iso_year,
    # microsecond, microseconds_between, millisecond, milliseconds_between, minute,
    # minutes_between, month, month_day_nano_interval_between, month_interval_between,
    # nanosecond, nanoseconds_between, round_temporal, second, seconds_between, strftime,
    # strptime, subsecond, us_week, week, weeks_between, year, year_month_day, years_between

    # has kleene methods
    # and, not, or

    # Conditional
    # case_when, cast, if_else

    # Indices
    # choose, index_in, index_in_meta_binary, indices_nonzero

    # Others
    # coalesce, divide, divide_checked, drop_null, fill_null_backward, fill_null_forward,
    # filter, is_finite, is_in, is_in_meta_binary, is_inf, is_nan, is_null, is_valid,
    # list_element, list_flatten, list_parent_indices, list_value_length, make_struct,
    # max_element_wise, min_element_wise, random, replace_with_mask, select_k_unstable,
    # sort_indices, struct_field, take

    private # =======

    def exec_func(function, other: nil, options: {})
      func = Arrow::Function.find(function)
      output =
        case other
        when nil
          func.execute([data])
        when Vector
          func.execute([data, other.data])
        when Arrow::ChunkedArray, Arrow::Int8Scalar
          func.execute([data, other])
        else
          raise ArgumentError
        end
      options[:aggregate] ? output.value : Vector.new(output.value)
    end
  end
end
