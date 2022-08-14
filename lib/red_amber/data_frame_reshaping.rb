# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameReshaping
    # Transpose a wide DataFrame.
    #
    # @param key [Symbol, FalseClass] key of the index column
    #   to transepose into keys.
    #   If it is false, keys[0] is used.
    # @param new_key [Symbol, FalseClass] key name of transposed index column.
    #   If it is false, :name is used. If it already exists, :name1.succ is used.
    # @return [DataFrame] trnsposed DataFrame
    def transpose(key: keys.first, new_key: :name)
      raise DataFrameArgumentError, "Not include: #{key}" unless keys.include?(key)

      # Find unused name
      new_keys = self[key].to_a.map { |e| e.to_s.to_sym }
      new_key = (:name1..).find { |k| !new_keys.include?(k) } if new_keys.include?(new_key)

      hash = { new_key => (keys - [key]) }
      i = keys.index(key)
      each_row do |h|
        k = h.values[i]
        hash[k] = h.values - [k]
      end
      DataFrame.new(hash)
    end
  end
end
