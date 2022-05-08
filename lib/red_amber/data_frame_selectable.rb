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
      expanded =
        args.each_with_object([]) do |e, a|
          e.is_a?(Range) ? a.concat(normalized_array(e)) : a.append(e)
        end

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
        Vector.new(@table[*keys].data)
      else
        DataFrame.new(@table[keys])
      end
    end

    def select_rows(indeces)
      out_of_range?(indeces) && raise(DataFrameArgumentError, "Invalid index: #{indeces} for 0..#{size - 1}")

      a = indeces.map { |i| @table.slice(i).to_a }
      DataFrame.new(@table.schema, a)
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
  end
end
