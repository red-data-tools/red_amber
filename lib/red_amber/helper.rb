# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module Helper
    private

    def pl(num)
      num > 1 ? 's' : ''
    end

    def out_of_range?(indeces)
      indeces.max >= size || indeces.min < -size
    end

    def integers?(enum)
      enum.all?(Integer)
    end

    def booleans?(enum)
      enum.all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
    end

    def create_dataframe_from_vector(key, vector)
      DataFrame.new(key => vector.data)
    end

    def parse_to_vector(args)
      a = args.reduce([]) do |accum, elem|
        accum.concat(normalize_element(elem))
      end
      Vector.new(a)
    end

    def normalize_element(elem)
      case elem
      when NilClass
        [nil]
      when Range
        both_end = [elem.begin, elem.end]
        both_end[1] -= 1 if elem.exclude_end? && elem.end.is_a?(Integer)

        if both_end.any?(Integer) || both_end.all?(&:nil?)
          if both_end.any? { |e| e&.>=(size) || e&.<(-size) }
            raise DataFrameArgumentError, "Index out of range: #{elem} for 0..#{size - 1}"
          end

          (0...size).to_a[elem]
        else
          Array[elem]
        end
      else
        Array(elem)
      end
    end
  end
end
