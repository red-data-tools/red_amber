# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module Helper
    private

    def pl(num)
      num > 1 ? 's' : ''
    end

    def parse_to_array(args, array_size)
      args.reduce([]) do |accum, elem|
        accum.concat(_parse_element(elem, array_size))
      end
    end

    def _parse_element(elem, array_size)
      case elem
      when Integer
        Array(_normalize_index(elem, array_size))
      when Symbol # to process Symbol quickly
        Array(elem)
      # when String
      #   Array(elem.to_sym)
      when Range
        bg = elem.begin
        en = elem.end
        if [bg, en].any?(Integer)
          bg += array_size if bg&.negative?
          en += array_size if en&.negative?
          en -= 1 if en.is_a?(Integer) && elem.exclude_end?
          if bg&.negative? || (en && en >= array_size)
            raise IndexError, "Index out of range: #{elem} for 0..#{array_size - 1}"
          end

          Array(0...array_size)[elem]
        elsif bg.nil?
          raise DataFrameArgumentError, "Cannot use beginless Range: #{elem}"
        elsif en.nil?
          raise DataFrameArgumentError, "Cannot use endless Range: #{elem}"
        else
          Array(elem)
        end
      when Enumerator
        parse_to_array(Array(elem), array_size)
      when Float
        Array(_normalize_index(elem.to_i, array_size))
      when NilClass
        [nil]
      else # rubocop:disable Lint/DuplicateBranch
        # ignore cop above to process Symbol quickly
        Array(elem)
      end
    end

    def _normalize_index(index, array_size)
      idx = index.negative? ? index + array_size : index
      raise IndexError, "Index out of range: #{index} for 0..#{array_size - 1}" if idx.negative? || idx >= array_size

      idx
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
