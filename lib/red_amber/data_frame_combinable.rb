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

    # Mutating joins (#inner_join, #full_join, #left_join, #right_join)

    # Join another DataFrame or Table, leaving only the matching records.
    # - Same as `#join` with `type: :inner`
    # - A kind of mutating join.
    #
    # @!macro join_before
    #   @param other [DataFrame, Arrow::Table]
    #     A DataFrame or a Table to be joined with self.
    #
    # @!macro join_after
    #   @param suffix [#succ]
    #     a suffix to rename keys when key names conflict as a result of join.
    #     `suffix` must be responsible to `#succ`.
    #   @return [DataFrame]
    #     Joined dataframe.
    #
    # @!macro join_key_in_array
    #   @param join_keys [String, Symbol, Array<String, Symbol>]
    #     A key or keys to match.
    #
    # @!macro join_key_in_hash
    #   @param join_key_pairs [Hash]
    #     Pairs of a key name or key names to match in left and right.
    #   @option join_key_pairs [String, Symbol, Array<String, Symbol>] :left
    #     Join keys in `self`.
    #   @option join_key_pairs [String, Symbol, Array<String, Symbol>] :right
    #     Join keys in `other`.
    #
    # @overload inner_join(other, suffix: '.1')
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_after
    #
    # @overload inner_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #
    # @overload inner_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #
    def inner_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :inner, suffix: suffix)
    end

    # Join another DataFrame or Table, leaving all records.
    # - Same as `#join` with `type: :full_outer`
    # - A kind of mutating join.
    #
    # @overload full_join(other, suffix: '.1')
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_after
    #
    # @overload full_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #
    # @overload full_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #
    def full_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :full_outer, suffix: suffix)
    end

    alias_method :outer_join, :full_join

    # Join matching values to self from other.
    # - Same as `#join` with `type: :left_outer`
    # - A kind of mutating join.
    #
    # @overload left_join(other, suffix: '.1')
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_after
    #
    # @overload left_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #
    # @overload left_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #
    def left_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_outer, suffix: suffix)
    end

    # Join matching values from self to other.
    # - Same as `#join` with `type: :right_outer`
    # - A kind of mutating join.
    #
    # @overload right_join(other, suffix: '.1')
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_after
    #
    # @overload right_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #
    # @overload right_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #
    def right_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :right_outer, suffix: suffix)
    end

    # Filtering joins (#semi_join, #anti_join)

    # Return records of self that have a match in other.
    # - Same as `#join` with `type: :left_semi`
    # - A kind of filtering join.
    #
    # @overload semi_join(other, suffix: '.1')
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_after
    #
    # @overload semi_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #
    # @overload semi_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #
    def semi_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_semi, suffix: suffix)
    end

    # Return records of self that do not have a match in other.
    # - Same as `#join` with `type: :left_anti`
    # - A kind of filtering join.
    #
    # @overload anti_join(other, suffix: '.1')
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_after
    #
    # @overload anti_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #
    # @overload anti_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #
    def anti_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_anti, suffix: suffix)
    end

    # Set operations (#intersect, #union, #difference, #set_operable?)

    # Check if set operation with self and other is possible.
    #
    # @macro join_before
    #
    # @return [Boolean] true if set operation is possible.
    #
    def set_operable?(other) # rubocop:disable Naming/AccessorMethodName
      keys == other.keys.map(&:to_sym)
    end

    # Select records appearing in both self and other.
    # - Same as `#join` with `type: :inner` when keys in self are same with other.
    # - A kind of set operations.
    #
    # @macro join_before
    #
    # @return [DataFrame] Joined dataframe.
    #
    def intersect(other)
      unless keys == other.keys.map(&:to_sym)
        raise DataFrameArgumentError, 'keys are not same with self and other'
      end

      join(other, keys, type: :inner)
    end

    # Select records appearing in self or other.
    # - Same as `#join` with `type: :full_outer` when keys in self are same with other.
    # - A kind of set operations.
    #
    # @macro join_before
    #
    # @return [DataFrame] Joined dataframe.
    #
    def union(other)
      unless keys == other.keys.map(&:to_sym)
        raise DataFrameArgumentError, 'keys are not same with self and other'
      end

      join(other, keys, type: :full_outer)
    end

    # Select records appearing in self but not in other.
    # - Same as `#join` with `type: :left_anti` when keys in self are same with other.
    # - A kind of set operations.
    #
    # @macro join_before
    #
    # @return [DataFrame] Joined dataframe.
    #
    def difference(other)
      unless keys == other.keys.map(&:to_sym)
        raise DataFrameArgumentError, 'keys are not same with self and other'
      end

      join(other, keys, type: :left_anti)
    end

    alias_method :setdiff, :difference

    # Join another DataFrame or Table to self.
    #
    # @overload join(other, type: :inner, suffix: '.1')
    #
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @!macro join_common_type
    #     @param type [:left_semi, :right_semi, :left_anti, :right_anti, :inner,
    #                  left_outer, :right_outer, :full_outer] type of join.
    #
    #   @macro join_before
    #   @macro join_common_type
    #   @macro join_after
    #
    # @overload join(other, join_keys, type: :inner, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_common_type
    #   @macro join_after
    #
    # @overload join(other, join_key_pairs, type: :inner, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_common_type
    #   @macro join_after
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

      # This is not necessary if additional procedure is contributed to Red Arrow.
      if join_keys.is_a?(Hash)
        left_keys = join_keys[:left]
        right_keys = join_keys[:right]
      else
        left_keys = join_keys
        right_keys = join_keys
      end
      left_keys = Array(left_keys).map(&:to_s)
      right_keys = Array(right_keys).map(&:to_s)

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
        end.pick do
          [right_keys, keys.map(&:to_s) - right_keys]
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

    # Merge two Arrow::Arrays
    def merge_array(array1, array2)
      t = Arrow::Function.find(:is_null).execute([array1])
      Arrow::Function.find(:if_else).execute([t, array2, array1]).value
    end
  end
end
