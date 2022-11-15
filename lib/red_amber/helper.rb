# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module Helper
    private

    def pl(num)
      num > 1 ? 's' : ''
    end

    def booleans?(enum)
      enum.all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
    end

    def parse_to_vector(args, vsize: size)
      a = args.reduce([]) do |accum, elem|
        accum.concat(normalize_element(elem, vsize: vsize))
      end
      Vector.new(a)
    end

    def normalize_element(elem, vsize: size)
      case elem
      when NilClass
        [nil]
      when Range
        bg = elem.begin
        en = elem.end
        if [bg, en].any?(Integer)
          bg += vsize if bg&.negative?
          en += vsize if en&.negative?
          en -= 1 if en.is_a?(Integer) && elem.exclude_end?
          if bg&.negative? || (en && en >= vsize)
            raise DataFrameArgumentError, "Index out of range: #{elem} for 0..#{vsize - 1}"
          end

          Array(0...vsize)[elem]
        elsif bg.nil? && en.nil?
          Array(0...vsize)
        else
          Array(elem)
        end
      when Enumerator
        elem.to_a
      else
        Array[elem]
      end
    end
  end
end
