# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameHelper
    private

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

    def keys_by_booleans(booleans)
      keys.select.with_index { |_, i| booleans[i] }
    end
  end
end
