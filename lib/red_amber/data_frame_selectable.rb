# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameSelectable
    # select columns: [symbol] or [string]
    # select rows: [array of index], [range]
    def [](*args)
      raise DataFrameArgumentError, 'Empty dataframe' if empty?
      raise DataFrameArgumentError, 'Empty argument' if args.empty?

      if args.one?
        case args[0]
        when Vector
          return select_obs_by_boolean(Arrow::BooleanArray.new(args[0].data))
        when Arrow::BooleanArray
          return select_obs_by_boolean(args[0])
        when Array
          return select_obs_by_boolean(Arrow::BooleanArray.new(args[0]))

          # when Hash
          # specify conditions to select by a Hash
        end
      end

      return select_obs_by_boolean(args) if booleans?(args)

      # expand Range like [1..3, 4] to [1, 2, 3, 4]
      expanded = expand_range(args)
      return map_indices(*expanded) if integers?(expanded)
      return select_vars_by_keys(expanded.map(&:to_sym)) if sym_or_str?(expanded)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    # Select a variable by a key in String or Symbol
    def v(key)
      unless key.is_a?(Symbol) || key.is_a?(String)
        raise DataFrameArgumentError, "Key is not a Symbol or String [#{key}]"
      end
      raise DataFrameArgumentError, "Key not exist [#{key}]" unless key?(key)

      variables[key.to_sym]
    end

    def head(n_rows = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_rows}" if n_rows.negative?

      self[0...[n_rows, size].min]
    end

    def tail(n_rows = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_rows}" if n_rows.negative?

      self[-[n_rows, size].min..]
    end

    def first(n_rows = 1)
      head(n_rows)
    end

    def last(n_rows = 1)
      tail(n_rows)
    end

    private

    def select_vars_by_keys(keys)
      if keys.one?
        key = keys[0].to_sym
        raise DataFrameArgumentError, "Key does not exist #{keys}" unless key? key

        variables[key]
      else
        DataFrame.new(@table[keys])
      end
    end
  end
end
