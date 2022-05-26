# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameHelper
    private

    def expand_range(args)
      args.each_with_object([]) do |e, a|
        e.is_a?(Range) ? a.concat(normalized_array(e)) : a.append(e)
      end
    end

    def normalized_array(range)
      both_end = [range.begin, range.end]
      both_end[1] -= 1 if range.exclude_end? && range.end.is_a?(Integer)

      if both_end.any?(Integer) || both_end.all?(&:nil?)
        if both_end.any? { |e| e&.>=(size) || e&.<(-size) }
          raise DataFrameArgumentError, "Index out of range: #{range} for 0..#{size - 1}"
        end

        (0...size).to_a[range]
      else
        range.to_a
      end
    end

    def out_of_range?(indeces)
      indeces.max >= size || indeces.min < -size
    end

    def integers?(enum)
      enum.all?(Integer)
    end

    def sym_or_str?(enum)
      enum.all? { |e| e.is_a?(Symbol) || e.is_a?(String) }
    end

    def booleans?(enum)
      enum.all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
    end

    def create_dataframe_from_vector(key, vector)
      DataFrame.new(key => vector.data)
    end

    def select_obs_by_boolean(array)
      DataFrame.new(@table.filter(array))
    end

    def select_obs_by_indeces(indeces)
      out_of_range?(indeces) && raise(DataFrameArgumentError, "Invalid index: #{indeces} for 0..#{size - 1}")

      a = indeces.map { |i| @table.slice(i).to_a }
      DataFrame.new(@table.schema, a)
    end
  end
end
