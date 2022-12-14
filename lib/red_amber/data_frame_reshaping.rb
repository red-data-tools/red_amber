# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameReshaping
    # Transpose a wide DataFrame.
    #
    # @param key [Symbol] key of the index column
    #   to transepose into keys.
    #   If it is not specified, keys[0] is used.
    # @param name [Symbol] key name of transposed index column.
    #   If it is not specified, :NAME is used.
    #   If it already exists, :NAME1 or :NAME1.succ is used.
    # @return [DataFrame] trnsposed DataFrame
    def transpose(key: keys.first, name: :NAME)
      unless keys.include?(key)
        raise DataFrameArgumentError, "Self does not include: #{key}"
      end

      # Find unused name
      new_keys = self[key].to_a.map { |e| e.to_s.to_sym }
      name = (:NAME1..).find { |k| !new_keys.include?(k) } if new_keys.include?(name)

      names = (keys - [key]).map { |x| x&.to_s }
      hash = { name => names }
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
    def to_long(*keep_keys, name: :NAME, value: :VALUE)
      warn('[Info] No key to keep is specified.') if keep_keys.empty?

      not_included = keep_keys - keys
      unless not_included.empty?
        raise DataFrameArgumentError, "Not have keys #{not_included}"
      end

      name = name.to_sym
      if keep_keys.include?(name)
        raise DataFrameArgumentError,
              "Can't specify the key: #{name} for the column from keys."
      end

      value = value.to_sym
      if keep_keys.include?(value)
        raise DataFrameArgumentError,
              "Can't specify the key: #{value} for the column from values."
      end

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
      hash[name] = hash[name].map { |x| x&.to_s }
      DataFrame.new(hash)
    end

    # Reshape long DataFrame to a wide DataFrame.
    #
    # @param name [Symbol, String]
    #   key of the column which will be expanded **to key names**.
    # @param value [Symbol, String]
    #   key of the column which will be expanded **to values**.
    # @return [DataFrame] wide DataFrame.
    def to_wide(name: :NAME, value: :VALUE)
      name = name.to_sym
      unless keys.include?(name)
        raise DataFrameArgumentError,
              "You are going to keep the key: #{name}. " \
              'You may need to specify the column name ' \
              'that gives the new keys by `:name` option.'
      end

      value = value.to_sym
      unless keys.include?(value)
        raise DataFrameArgumentError,
              "You are going to keep the key: #{value}. " \
              'You may need to specify the column name ' \
              'that gives the new values by `:value` option.'
      end

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
