# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module Helper
    private

    def pl(num)
      num > 1 ? 's' : ''
    end

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
          elem.floor
        else
          Array(elem)
        end
      end
    end

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
