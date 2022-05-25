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
      return select_obs_by_indeces(expanded) if integers?(expanded)
      return select_vars_by_keys(expanded.map(&:to_sym)) if sym_or_str?(expanded)

      raise DataFrameArgumentError, "Invalid argument #{args}"
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
  end
end
