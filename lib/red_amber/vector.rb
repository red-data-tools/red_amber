# frozen_string_literal: true

module RedAmber
  # Columnar data object
  #   @data : holds Arrow::ChunkedArray
  class Vector
    # chunked_array may come from column.data
    # Arrow::ChunkedArray, Arrow::Array, Array or ::Vector
    def initialize(array)
      case array
      when Vector
        @data = array.data
      when Arrow::Array, Arrow::ChunkedArray
        @data = array
      when Array
        @data = Arrow::Array.new(array)
      else
        raise ArgumentError, 'Unknown array in argument'
      end
    end

    attr_reader :data

    def to_s
      @data.to_a.inspect
    end

    def inspect
      format "#<#{self.class}:0x%016x>\n#{self}", object_id
    end

    def values
      @data.values
    end
    alias_method :to_a, :values
    alias_method :entries, :values

    def size
      @data.size
    end
    alias_method :length, :size
    alias_method :n_rows, :size
    alias_method :nrow, :size

    # def each(); end

    # Functions
    # Available functions are shown by `Arrow::Function.all.map(&:name)``
    # vector.func() => Scalar

    # vector.func(other) => Scarar

    # vector.func() => Vector

    # vector.func() => Vector, with operator defined
    unary_methods_op = {
      '-@' => :negate_checked,
      'abs' => :abs_checked,
      'acos' => :acos_checked,
      'asin' => :asin_checked,
      'atan' => :atan,
      'cos' => :cos_checked,
      'ln' => :ln_checked,
      'log10' => :log10_checked,
      'log2' => :log2_checked,
      'sign' => :sign,
      'sin' => :sin_checked,
      'tan' => :tan_checked,
      # bit_wise_not, ceil, floor, invert, log1p(checked), round, round_to_multiple, trunc
    }
    unary_methods_op.each do |operator, function|
      define_method(operator) do
        exec_func_binary(function)
      end
    end

    # vector.func(other) => Vector, with operator defined
    binary_methods_op = {
      '+' => :add_checked,
      '-' => :subtract_checked,
      '*' => :multiply_checked,
      '/' => :divide,
      # '%' => :mod,
      '**' => :power,
      '&' => :bit_wise_and,
      '|' => :bit_wise_or,
      '^' => :bit_wise_xor,
      '==' => :equal,
      '>' => :greater,
      '>=' => :greater_equal,
      '<' => :less,
      '<=' => :less_equal,
      # 'xor' => :xor,
      # atan2, logb(checked),
      # shift_left(checked), shift_right(checked)
    }
    binary_methods_op.each do |operator, function|
      define_method(operator) do |other|
        exec_func_binary(function, other)
      end
    end

    # array functions
    # all, any, approximate_median, array_filter, array_sort_indices, array_take
    # count, count_distinct, dictionary_encode, hash_all, hash_any, hash_approximate_median,
    # hash_count, hash_count_distinct, hash_distinct, hash_max, hash_mean, hash_min,
    # hash_min_max, hash_product, hash_stddev, hash_sum, hash_tdigest, hash_variance,
    # index, max, mean, min, min_max, mode, partition_nth_indices,
    # product, quantile, quarter, quarters_between, stddev, sum, tdigest, unique,
    # value_counts, variance

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

    def n_nulls
      @data.n_nulls
    end

    private # =======

    def exec_func_binary(function, other = nil)
      func = Arrow::Function.find(function)
      array =
        case other
        when nil
          func.execute([data]).value
        when RedAmber::Vector
          func.execute([data, other.data]).value
        when Arrow::ChunkedArray, Arrow::Int8Scalar
          func.execute([data, other]).value
        else
          raise ArgumentError
        end
      RedAmber::Vector.new(array)
    end
  end
end
