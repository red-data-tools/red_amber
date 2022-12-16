# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameCombinable
    # Refinements for Arrow::Table
    using RefineArrowTable

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

        if size != df.size
          raise DataFrameArgumentError, "#{e} do not have same size as self"
        end

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
      unless keys == other.keys
        raise DataFrameArgumentError, 'keys are not same with self and other'
      end

      join(other, keys, type: :inner)
    end

    # Select records appearing in self or other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @return [DataFrame] Joined dataframe.
    #
    def union(other)
      other = DataFrame.create(other) if other.is_a?(Arrow::Table)
      unless keys == other.keys
        raise DataFrameArgumentError, 'keys are not same with self and other'
      end

      join(other, keys, type: :full_outer)
    end

    # Select records appearing in self but not in other.
    #
    # @param other [DataFrame, Arrow::Table] DataFrame/Table to be joined with self.
    # @return [DataFrame] Joined dataframe.
    #
    def difference(other)
      other = DataFrame.create(other) if other.is_a?(Arrow::Table)
      unless keys == other.keys
        raise DataFrameArgumentError, 'keys are not same with self and other'
      end

      join(other, keys, type: :left_anti)
    end

    alias_method :setdiff, :difference

    # Undocumented. It is preferable to call specific methods.
    #
    # Join another DataFrame or Table.
    #
    # @overload join(other, key, type: :inner, suffix: '.1',
    #                left_outputs: nil, right_outputs: nil)
    #
    #   @!macro join_other
    #   @param other [DataFrame, Arrow::Table] DataFrame or Table to be joined with self.
    # @param join_keys [String, Symbol, ::Array<String, Symbol>] keys to match.
    # @return [DataFrame] Joined dataframe.
    #
    #   :type is one of
    #     :left_semi, :right_semi, :left_anti, :right_anti, :inner,
    #     :left_outer, :right_outer, :full_outer.
    #
    # @overload join(other, join_keys, )
    #
    #   @param join_keys [Hash] key assignments to join.
    #   @option join_keys [Symbol, String]
    #
    def join(other, join_keys = nil, type: :inner, suffix: '.1')
      case other
      when DataFrame
        other = other.table
      when Arrow::Table
        # Nop
      else
        raise DataFrameArgumentError, 'other must be a DataFrame or an Arrow::Table'
      end

      table_keys = table.keys
      other_keys = other.keys
      type = type.to_sym

      # natural keys (implicit common keys)
      join_keys ||= table_keys.intersection(other_keys)

      left_keys = Array(join_keys).map(&:to_s)
      right_keys = Array(join_keys).map(&:to_s)

      case type
      when :full_outer, :left_semi, :left_anti, :right_semi, :right_anti
        left_outputs = nil
        right_outputs = nil
      when :inner, :left_outer
        left_outputs = table_keys
        right_outputs = other_keys - right_keys
      when :right_outer
        left_outputs = table_keys - left_keys
        right_outputs = other_keys
      end

      # Should we rescue errors in Arrow::Table#join for usability ?
      joined_table =
        table.join(other, join_keys,
                   type: type,
                   left_outputs: left_outputs,
                   right_outputs: right_outputs)

      case type
      when :inner, :left_outer, :left_semi, :left_anti, :right_semi, :right_anti
        if joined_table.keys.uniq!
          DataFrame.create(rename_table(joined_table, n_keys, suffix))
        else
          DataFrame.create(joined_table)
        end
      when :full_outer
        renamed_table = rename_table(joined_table, n_keys, suffix)
        renamed_keys = renamed_table.keys
        dropper = []
        DataFrame.create(renamed_table).assign do |df|
          left_keys.map do |left_key|
            i_left_key = renamed_keys.index(left_key)
            right_key = renamed_keys[i_left_key + table_keys.size]
            dropper << right_key
            [left_key.to_sym, merge_array(df[left_key].data, df[right_key].data)]
          end
        end.drop(dropper)
      when :right_outer
        if joined_table.keys.uniq!
          DataFrame.create(rename_table(joined_table, left_outputs.size, suffix))
        else
          DataFrame.create(joined_table)
        end.pick do |df|
          [table_keys, df.keys[-right_outputs.size..].map(&:to_s) - right_keys]
        end
      end
    end

    private

    # Rename duplicate keys by suffix
    def rename_table(joined_table, n_keys, suffix)
      joined_keys = joined_table.keys
      other_keys = joined_keys[n_keys..]

      dup_keys = joined_keys.tally.select { |_, v| v > 1 }.keys
      renamed_right_keys =
        other_keys.map do |key|
          if dup_keys.include?(key)
            new_key = nil
            loop do
              new_key = "#{key}#{suffix}"
              break unless joined_keys.include?(new_key)

              s = suffix.succ
              raise DataFrameArgumentError, "suffix #{suffix} is invalid" if s == suffix

              suffix = s
            end
            new_key
          else
            key
          end
        end
      joined_keys[n_keys..] = renamed_right_keys

      fields =
        joined_keys.map.with_index do |k, i|
          Arrow::Field.new(k, joined_table[i].data_type)
        end
      Arrow::Table.new(Arrow::Schema.new(fields), joined_table.columns)
    end

    def merge_array(array1, array2)
      t = Arrow::Function.find(:is_null).execute([array1])
      Arrow::Function.find(:if_else).execute([t, array2, array1]).value
    end
  end
end
