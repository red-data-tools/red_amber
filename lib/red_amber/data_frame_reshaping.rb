# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameReshaping
    # Transpose a wide DataFrame.
    #
    # @param key [Symbol] key of the index column
    #   to transepose into keys.
    #   If it is not specified, keys[0] is used.
    # @param new_key [Symbol] key name of transposed index column.
    #   If it is not specified, :N is used. If it already exists, :N1 or :N1.succ is used.
    # @return [DataFrame] trnsposed DataFrame
    def transpose(key: keys.first, name: :N)
      raise DataFrameArgumentError, "Self does not include: #{key}" unless keys.include?(key)

      # Find unused name
      new_keys = self[key].to_a.map { |e| e.to_s.to_sym }
      name = (:N1..).find { |k| !new_keys.include?(k) } if new_keys.include?(name)

      hash = { name => (keys - [key]) }
      i = keys.index(key)
      each_row do |h|
        k = h.values[i]
        hash[k] = h.values - [k]
      end
      DataFrame.new(hash)
    end

    # Reshape wide DataFrame to a longer DataFrame.
    #
    # @param keep_keys [Array] keys to keep.
    # @param name [Symbol, String] key of the column which is come **from values**.
    # @param value [Symbol, String] key of the column which is come **from values**.
    # @return [DataFrame] long DataFrame.
    def to_long(*keep_keys, name: :N, value: :V)
      not_included = keep_keys - keys
      raise DataFrameArgumentError, "Not have keys #{not_included}" unless not_included.empty?

      name = name.to_sym
      raise DataFrameArgumentError, "Invalid key: #{name}" if keep_keys.include?(name)

      value = value.to_sym
      raise DataFrameArgumentError, "Invalid key: #{value}" if keep_keys.include?(value)

      hash = Hash.new { |h, k| h[k] = [] }
      l = keys.size - keep_keys.size
      each_row do |row|
        row.each do |k, v|
          if keep_keys.include?(k)
            hash[k].concat([v] * l)
          else
            hash[name] << k
            hash[value] << v
          end
        end
      end
      DataFrame.new(hash)
    end

    # Reshape long DataFrame to a wide DataFrame.
    #
    # @param name [Symbol, String] key of the column which will be expanded **to key names**.
    # @param value [Symbol, String] key of the column which will be expanded **to values**.
    # @return [DataFrame] wide DataFrame.
    def to_wide(name: :N, value: :V)
      name = name.to_sym
      raise DataFrameArgumentError, "Invalid key: #{name}" unless keys.include?(name)

      value = value.to_sym
      raise DataFrameArgumentError, "Invalid key: #{value}" unless keys.include?(value)

      hash = Hash.new { |h, k| h[k] = {} }
      keep_keys = keys - [name, value]
      each_row do |row|
        keeps, converts = row.partition { |k, _| keep_keys.include?(k) }
        h = converts.to_h
        hash[keeps.to_h][h[name].to_s.to_sym] = h[value]
      end
      ks = hash.first[0].keys + hash.first[1].keys
      vs = hash.map { |k, v| k.values + v.values }.transpose
      DataFrame.new(ks.zip(vs))
    end
  end
end
