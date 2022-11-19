# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameCombinable
    # Concatenate other dataframe onto the bottom.
    #
    # @param other [DataFrame, Arrow::Table, Array<DataFrame, Arrow::Table>]
    #   DataFrame/Table to concatenate onto the bottom of self.
    # @return [DataFrame]
    #   Concatenated dataframe.
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

      DataFrame.create(table.concatenate(table_array))
    end

    alias_method :concat, :concatenate
    alias_method :bind_rows, :concatenate

    # Merge other DataFrame or Table from other.
    # - Self and other must have same size.
    # - Self and other do not share the same key.
    #   - If they share any keys, raise Error.
    # @param other [DataFrame, Arrow::Table, Array<DataFrame, Arrow::Table>]
    #   DataFrame/Table to concatenate.
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
            DataFrame.create(e)
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

    # Join data, leaving only the matching records.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def inner_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :inner, suffix: suffix)
    end

    # Join data, leaving all records.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def full_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :full_outer, suffix: suffix)
    end

    alias_method :outer_join, :full_join

    # Join matching values to self from other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def left_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_outer, suffix: suffix)
    end

    # Join matching values from self to other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def right_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :right_outer, suffix: suffix)
    end

    # Filtering joins

    # Return records of self that have a match in other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def semi_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_semi, suffix: suffix)
    end

    # Return records of self that do not have a match in other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    def anti_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_anti, suffix: suffix)
    end

    # Set operations

    # Check if set operation with self and other is possible.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be checked with self.
    # @return [Boolean] true if set operation is possible.
    #
    def set_operable?(other) # rubocop:disable Naming/AccessorMethodName
      other = DataFrame.create(other) if other.is_a?(Arrow::Table)
      keys == other.keys
    end

    # Select records appearing in both self and other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @return [DataFrame] Joined dataframe.
    #
    def intersect(other)
      other = DataFrame.create(other) if other.is_a?(Arrow::Table)
      raise DataFrameArgumentError, 'keys are not same with self and other' unless keys == other.keys

      join(other, keys, type: :inner)
    end

    # Select records appearing in self or other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @return [DataFrame] Joined dataframe.
    #
    def union(other)
      other = DataFrame.create(other) if other.is_a?(Arrow::Table)
      raise DataFrameArgumentError, 'keys are not same with self and other' unless keys == other.keys

      join(other, keys, type: :full_outer)
    end

    # Select records appearing in self but not in other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @return [DataFrame] Joined dataframe.
    #
    def difference(other)
      other = DataFrame.create(other) if other.is_a?(Arrow::Table)
      raise DataFrameArgumentError, 'keys are not same with self and other' unless keys == other.keys

      join(other, keys, type: :left_anti)
    end

    alias_method :setdiff, :difference

    # Undocumented. It is preferable to call specific methods.

    # Join other dataframe
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] Keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    #   :type is one of
    #     :left_semi, :right_semi, :left_anti, :right_anti inner, :left_outer, :right_outer, :full_outer.
    def join(other, join_keys = nil, type: :inner, suffix: '.1', left_outputs: nil, right_outputs: nil)
      case other
      when DataFrame
        # Nop
      when Arrow::Table
        other = DataFrame.create(other)
      else
        raise DataFrameArgumentError, 'other must be a DataFrame or an Arrow::Table'
      end

      # Support natural keys (implicit common keys)
      natural_keys = keys.intersection(other.keys)
      raise DataFrameArgumentError, "#{join_keys} are not common keys" if natural_keys.empty?

      join_keys =
        if join_keys
          Array(join_keys).map(&:to_sym)
        else
          natural_keys
        end
      return self if join_keys.empty?

      # Support partial join_keys (common key other than join_key will be renamed with suffix)
      remainer_keys = natural_keys - join_keys
      unless remainer_keys.empty?
        renamer = remainer_keys.each_with_object({}) do |key, hash|
          new_key = nil
          loop do
            new_key = "#{key}#{suffix}".to_sym
            break unless keys.include?(new_key)

            s = suffix.succ
            raise DataFrameArgumentError, "suffix #{suffix} is invalid" if s == suffix

            suffix = s
          end
          hash[key] = new_key
        end
        other = other.rename(renamer)
      end

      # Red Arrow's #join returns duplicated join_keys from self and other as of v9.0.0 .
      # Temporally merge key vectors here to workaround.
      table_output =
        table.join(other.table, join_keys, type: type, left_outputs: left_outputs, right_outputs: right_outputs)
      left_indexes = [*0...n_keys]
      right_indexes = [*((other.keys - join_keys).map { |key| other.keys.index(key) + n_keys })]

      case type
      when :left_semi, :left_anti, :right_semi, :right_anti
        return DataFrame.create(table_output)
      else
        selected_indexes = left_indexes.concat(right_indexes)
      end
      merged_columns = join_keys.map do |key|
        i = keys.index(key)
        merge_column(table_output[i], table_output[n_keys + i], type)
      end
      DataFrame.create(table_output[selected_indexes])
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
