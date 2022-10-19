# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameCombinable
    # Concatenate other dataframe at the bottom.
    #
    # @param other [DataFrame, Arrow::Table, Array<DataFrame, Arrow::Table>]
    #   dataframe/table to concatenate onto the bottom of self.
    # @return [DataFrame]
    #   concatenated dataframe.
    def concatenate(*other)
      case other
      in [] | [nil] | [[]]
        return self
      in [Array => array]
        # Nop
      else
        array = other
      end

      table_array = array.map do |e|
        case e
        when Arrow::Table
          e
        when DataFrame
          e.table
        else
          raise DataFrameArgumentError, "#{e} is not a Table or a DataFrame"
        end
      end

      DataFrame.new(table.concatenate(table_array))
    end

    alias_method :concat, :concatenate
    alias_method :bind_rows, :concatenate

    # Merge other DataFrame or Table from right.
    # - Self and other must have same size.
    # - Self and other do not share the same key.
    #   - If they share any keys, raise Error.
    # @param other [DataFrame, Arrow::Table, Array<DataFrame, Arrow::Table>]
    #   DataFrame/Table to concatenate from the right of self.
    # @return [DataFrame]
    #   Merged dataframe.
    def merge(*other)
      case other
      in [] | [nil] | [[]]
        return self
      in [Array => array]
        # Nop
      else
        array = other
      end

      hash = array.each_with_object({}) do |e, h|
        df =
          case e
          when Arrow::Table
            DataFrame.new(e)
          when DataFrame
            e
          else
            raise DataFrameArgumentError, "#{e} is not a Table or a DataFrame"
          end

        raise DataFrameArgumentError, "#{e} do not have same size as self" if size != df.size

        k = keys.intersection(df.keys).any?
        raise DataFrameArgumentError, "There are some shared keys: #{k}" if k

        h.merge!(df.to_h)
      end

      assign(hash)
    end

    alias_method :bind_cols, :merge

    # Mutating joins

    # Join data, leaving only the matching rows.
    #
    # @param right [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def inner_join(right, join_keys)
      join(right, join_keys, type: :inner)
    end

    # Join data, leaving all rows.
    #
    # @param right [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def full_join(right, join_keys)
      join(right, join_keys, type: :full_outer)
    end

    alias_method :outer_join, :full_join

    # Join matching values from right to self.
    #
    # @param right [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def left_join(right, join_keys)
      join(right, join_keys, type: :left_outer)
    end

    # Join matching values from self to right.
    #
    # @param right [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def right_join(right, join_keys)
      join(right, join_keys, type: :right_outer)
    end

    # Filtering joins

    # Return rows of self that have a match in right.
    #
    # @param right [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def semi_join(right, join_keys)
      join(right, join_keys, type: :left_semi)
    end

    # Undocumented

    # Join other dataframe
    #
    # @param right [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    #   :type is one of %i[left_semi right_semi left_anti right_anti inner left_outer right_outer full_outer]
    def join(right, join_keys, type: :inner, left_outputs: nil, right_outputs: nil)
      right = right.table if right.is_a?(DataFrame)

      join_keys = Array(join_keys).map(&:to_sym)

      # Red Arrow's #join returns duplicated join_keys from self and right as of v9.0.0 .
      # Temprally merge key vectors here to workaround.
      table_output =
        table.join(right, join_keys, type: type, left_outputs: left_outputs, right_outputs: right_outputs)
      selected_indexes =
        [*0...n_keys, *((n_keys + join_keys.size)...table_output.n_columns)]
      merged_columns = join_keys.map.with_index do |_key, i|
        merge_column(table_output[i], table_output[n_keys + i], type)
      end

      DataFrame.new(table_output[selected_indexes])
               .assign(*join_keys) { merged_columns }
    end

    private

    def merge_column(column1, column2, type)
      a1 = column1.to_a
      a2 = column2.to_a
      if type == :full_outer
        a1.zip(a2).map { |x, y| x || y }
      elsif type.start_with?('right')
        a2
      else # :inner or :left-*
        a1
      end
    end
  end
end
