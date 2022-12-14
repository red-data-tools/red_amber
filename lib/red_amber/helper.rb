# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module Helper
    private

    # If num is larger than 1 return 's' to be plural.
    #
    # @param num [Numeric] some number.
    # @return ['s', ''] return 's' if num is larger than 1.
    #   Otherwise return ''.
    def pl(num)
      num > 1 ? 's' : ''
    end

    # Parse the argments in an Array
    #   and returns a parsed Array.
    #
    # @param args
    #   [<Integer, Symbol, true, false, nil, Array, Range, Enumerator, String, Float>]
    #   arguments.
    # @param array_size [Integer] size of target Array to use in a endless Range.
    # @return [<Integer, Symbol, true, false, nil>] parsed flat Array.
    # @note This method is recursively called to parse.
    def parse_args(args, array_size)
      args.flat_map do |elem|
        case elem
        when Integer, Symbol, NilClass, TrueClass, FalseClass
          elem
        when Array
          parse_args(elem, array_size)
        when Range
          parse_range(elem, array_size)
        when Enumerator
          parse_args(Array(elem), array_size)
        when String
          elem.to_sym
        when Float
          elem.floor.to_i
        else
          Array(elem)
        end
      end
    end

    # Parse a Range to an Array
    #
    # @param range [Range] Range to parse.
    # @param array_size [Integer] size of target Array to use in a endless Range.
    # @return [Array<Integer, Symbol, String>] parsed Array.
    def parse_range(range, array_size)
      bg = range.begin
      en = range.end
      if [bg, en].any?(Integer)
        bg += array_size if bg&.negative?
        en += array_size if en&.negative?
        en -= 1 if en.is_a?(Integer) && range.exclude_end?
        if bg&.negative? || (en && en >= array_size)
          raise IndexError, "Index out of range: #{range} for 0..#{array_size - 1}"
        end

        Array(0...array_size)[range]
      elsif bg.nil?
        raise DataFrameArgumentError, "Cannot use beginless Range: #{range}"
      elsif en.nil?
        raise DataFrameArgumentError, "Cannot use endless Range: #{range}"
      else
        Array(range)
      end
    end
  end
end
