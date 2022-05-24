# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameSelectable
    # select columns: [symbol] or [string]
    # select rows: [array of index], [range]
    def [](*args)
      raise DataFrameArgumentError, 'Empty dataframe' if empty?
      raise DataFrameArgumentError, 'Empty argument' if args.empty?

      # expand Range like [1..3, 4] to [1, 2, 3, 4]
      expanded = expand_range(args)
      return select_rows(expanded) if integers?(expanded)
      return select_columns(expanded.map(&:to_sym)) if sym_or_str?(expanded)

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

    private # =====

    def select_columns(keys)
      if keys.one?
        t = @table[*keys]
        raise DataFrameArgumentError, "Key is not exists #{keys}" unless t

        Vector.new(t.data)
      else
        DataFrame.new(@table[keys])
      end
    end

    def select_rows(indeces)
      out_of_range?(indeces) && raise(DataFrameArgumentError, "Invalid index: #{indeces} for 0..#{size - 1}")

      a = indeces.map { |i| @table.slice(i).to_a }
      DataFrame.new(@table.schema, a)
    end
  end
end
