# frozen_string_literal: true

module RedAmber
  # Mix-in for the class DataFrame
  module DataFrameCombinable
    # Refinements for Arrow::Table
    using RefineArrowTable

    # Concatenate other dataframes or tables onto the bottom of self.
    #
    # @note the `#types` must be same as `other#types`.
    # @param other [DataFrame, Arrow::Table, Array<DataFrame, Arrow::Table>]
    #   DataFrames or Tables to concatenate.
    # @return [DataFrame]
    #   concatenated dataframe.
    # @example
    #   df    = DataFrame.new(x: [1, 2], y: ['A', 'B'])
    #   other = DataFrame.new(x: [3, 4], y: ['C', 'D'])
    #   [df.types, other.types]
    #
    #   # =>
    #   [[:uint8, :string], [:uint8, :string]]
    #
    #   df.concatenate(other)
    #
    #   # =>
    #           x y
    #     <uint8> <string>
    #   0       1 A
    #   1       2 B
    #   2       3 C
    #   3       4 D
    #
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

    # Merge other DataFrames or Tables.
    #
    # @note the `#size` must be same as `other#size`.
    # @note self and other must not share the same key.
    # @param other [DataFrame, Arrow::Table, Array<DataFrame, Arrow::Table>]
    #   DataFrames or Tables to merge.
    # @raise [DataFrameArgumentError]
    #   if size is not same or self and other shares the same key.
    # @return [DataFrame]
    #   merged dataframe.
    # @example
    #   df    = DataFrame.new(x: [1, 2], y: [3, 4])
    #   other = DataFrame.new(a: ['A', 'B'], b: ['C', 'D'])
    #   df.merge(other)
    #
    #   # =>
    #           x       y a        b
    #     <uint8> <uint8> <string> <string>
    #   0       1       3 A        C
    #   1       2       4 B        D
    #
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

    # @!macro join_before
    #   @param other [DataFrame, Arrow::Table]
    #     A DataFrame or a Table to be joined with self.
    #
    # @!macro join_dorce_order
    #   @param force_order [Boolean]
    #     wheather force order of the output always same.
    #     - This option is used in `:full_outer` and `:right_outer`.
    #     - If this option is true (by default) it will append index to the source
    #       and sort after joining. It will cause some degradation in performance.
    #
    # @!macro join_after
    #   @param suffix [#succ]
    #     a suffix to rename keys when key names conflict as a result of join.
    #     `suffix` must be responsible to `#succ`.
    #   @return [DataFrame]
    #     joined dataframe.
    #
    # @!macro join_key_in_array
    #   @param join_keys [String, Symbol, Array<String, Symbol>]
    #     a key or keys to match.
    #
    # @!macro join_key_in_hash
    #   @param join_key_pairs [Hash]
    #     pairs of a key name or key names to match in left and right.
    #   @option join_key_pairs [String, Symbol, Array<String, Symbol>] :left
    #     join keys in `self`.
    #   @option join_key_pairs [String, Symbol, Array<String, Symbol>] :right
    #     join keys in `other`.
    #
    # @!macro join_common_example_1
    #   @example
    #     df = DataFrame.new(KEY: %w[A B C], X1: [1, 2, 3])
    #
    #     # =>
    #       KEY           X1
    #       <string> <uint8>
    #     0 A              1
    #     1 B              2
    #     2 C              3
    #
    #     other = DataFrame.new(KEY: %w[A B D], X2: [true, false, nil])
    #
    #     # =>
    #       KEY      X2
    #       <string> <boolean>
    #     0 A        true
    #     1 B        false
    #     2 D        (nil)
    #
    # @!macro join_common_example_2
    #   @example
    #     df2 = DataFrame.new(KEY1: %w[A B C], X1: [1, 2, 3])
    #
    #     # =>
    #       KEY1          X1
    #       <string> <uint8>
    #     0 A              1
    #     1 B              2
    #     2 C              3
    #
    #     other2 = DataFrame.new(KEY2: %w[A B D], X2: [true, false, nil])
    #
    #     # =>
    #       KEY2     X2
    #       <string> <boolean>
    #     0 A        true
    #     1 B        false
    #     2 D        (nil)
    #
    # @!macro join_common_example_3
    #   @example
    #     df3 = DataFrame.new(
    #       KEY1: %w[A B C],
    #       KEY2: [1, 2, 3]
    #     )
    #
    #     # =>
    #       KEY1        KEY2
    #       <string> <uint8>
    #     0 A              1
    #     1 B              2
    #     2 C              3
    #
    #     other3 = DataFrame.new(
    #       KEY1: %w[A B D],
    #       KEY2: [1, 4, 5]
    #     )
    #
    #     # =>
    #       KEY1        KEY2
    #       <string> <uint8>
    #     0 A              1
    #     1 B              4
    #     2 D              5

    # Join another DataFrame or Table, leaving only the matching records.
    # - Same as `#join` with `type: :inner`
    # - A kind of mutating join.
    #
    # @overload inner_join(other, suffix: '.1')
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example without key (use implicit common key)
    #     df.inner_join(other)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #
    # @overload inner_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example with a key
    #     df.inner_join(other, :KEY)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #
    # @overload inner_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #   @macro join_common_example_2
    #   @example with key pairs
    #     df2.inner_join(other2, { left: :KEY1, right: :KEY2 })
    #
    #     # =>
    #       KEY1          X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #
    def inner_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :inner, suffix: suffix)
    end

    # Join another DataFrame or Table, leaving all records.
    # - Same as `#join` with `type: :full_outer`
    # - A kind of mutating join.
    #
    # @overload full_join(other, suffix: '.1', force_order: true)
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example without key (use implicit common key)
    #     df.full_join(other)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 C              3 (nil)
    #     3 D          (nil) (nil)
    #
    # @overload full_join(other, join_keys, suffix: '.1', force_order: true)
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example with a key
    #     df.full_join(other, :KEY)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 C              3 (nil)
    #     3 D          (nil) (nil)
    #
    # @overload full_join(other, join_key_pairs, suffix: '.1', force_order: true)
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_2
    #   @example with key pairs
    #     df2.full_join(other2, { left: :KEY1, right: :KEY2 })
    #
    #     # =>
    #       KEY1          X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 C              3 (nil)
    #     3 D          (nil) (nil)
    #
    def full_join(other, join_keys = nil, suffix: '.1', force_order: true)
      join(other, join_keys,
           type: :full_outer, suffix: suffix, force_order: force_order)
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
    #   @macro join_common_example_1
    #   @example without key (use implicit common key)
    #     df.left_join(other)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 C              3 (nil)
    #
    # @overload left_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example with a key
    #     df.left_join(other, :KEY)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 C              3 (nil)
    #
    # @overload left_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #   @macro join_common_example_2
    #   @example with key pairs
    #     df2.left_join(other2, { left: :KEY1, right: :KEY2 })
    #
    #     # =>
    #       KEY1          X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 C              3 (nil)
    #
    def left_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_outer, suffix: suffix)
    end

    # Join matching values from self to other.
    # - Same as `#join` with `type: :right_outer`
    # - A kind of mutating join.
    #
    # @overload right_join(other, suffix: '.1', force_order: true)
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example without key (use implicit common key)
    #     df.right_join(other)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 D          (nil) (nil)
    #
    # @overload right_join(other, join_keys, suffix: '.1', force_order: true)
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example with a key
    #     df.right_join(other, :KEY)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 D          (nil) (nil)
    #
    # @overload right_join(other, join_key_pairs, suffix: '.1', force_order: true)
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_2
    #   @example with key pairs
    #     df2.right_join(other2, { left: :KEY1, right: :KEY2 })
    #
    #     # =>
    #       KEY1          X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 D          (nil) (nil)
    #
    def right_join(other, join_keys = nil, suffix: '.1', force_order: true)
      join(other, join_keys,
           type: :right_outer, suffix: suffix, force_order: force_order)
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
    #   @macro join_common_example_1
    #   @example without key (use implicit common key)
    #     df.semi_join(other)
    #
    #     # =>
    #       KEY           X1
    #       <string> <uint8>
    #     0 A              1
    #     1 B              2
    #
    # @overload semi_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example with a key
    #     df.semi_join(other, :KEY)
    #
    #     # =>
    #       KEY           X1
    #       <string> <uint8>
    #     0 A              1
    #     1 B              2
    #
    # @overload semi_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #   @macro join_common_example_2
    #   @example with key pairs
    #     df2.semi_join(other2, { left: :KEY1, right: :KEY2 })
    #
    #     # =>
    #       KEY1          X1
    #       <string> <uint8>
    #     0 A              1
    #     1 B              2
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
    #   @macro join_common_example_1
    #   @example without key (use implicit common key)
    #     df.anti_join(other)
    #
    #     # =>
    #       KEY           X1
    #       <string> <uint8>
    #     0 C              3
    #
    # @overload anti_join(other, join_keys, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example with a key
    #     df.anti_join(other, :KEY)
    #
    #     # =>
    #       KEY           X1
    #       <string> <uint8>
    #     0 C              3
    #
    # @overload anti_join(other, join_key_pairs, suffix: '.1')
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_after
    #   @macro join_common_example_2
    #   @example with key pairs
    #     df2.anti_join(other2, { left: :KEY1, right: :KEY2 })
    #
    #     # =>
    #       KEY1          X1
    #       <string> <uint8>
    #     0 C              3
    #
    def anti_join(other, join_keys = nil, suffix: '.1')
      join(other, join_keys, type: :left_anti, suffix: suffix)
    end

    # Set operations (#intersect, #union, #difference, #set_operable?)

    # Check if set operation with self and other is possible.
    #
    # @macro join_before
    # @return [Boolean]
    #   true if set operation is possible.
    # @macro join_common_example_3
    # @example
    #   df3.set_operable?(other3) # => true
    #
    def set_operable?(other) # rubocop:disable Naming/AccessorMethodName
      keys == other.keys.map(&:to_sym)
    end

    # Select records appearing in both self and other.
    # - Same as `#join` with `type: :inner` when keys in self are same with other.
    # - A kind of set operations.
    #
    # @macro join_before
    # @return [DataFrame]
    #   joined dataframe.
    # @macro join_common_example_3
    # @example
    #   df3.intersect(other3)
    #
    #   # =>
    #     KEY1        KEY2
    #     <string> <uint8>
    #   0 A              1
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
    # @return [DataFrame]
    #   joined dataframe.
    # @macro join_common_example_3
    # @example
    #   df3.intersect(other3)
    #
    #   # =>
    #     KEY1        KEY2
    #     <string> <uint8>
    #   0 A              1
    #   1 B              2
    #   2 C              3
    #   3 B              4
    #   4 D              5
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
    # @return [DataFrame]
    #   joined dataframe.
    # @macro join_common_example_3
    # @example
    #   df3.intersect(other3)
    #
    #   # =>
    #     KEY1        KEY2
    #     <string> <uint8>
    #   0 B              2
    #   1 C              3
    #
    #   other.intersect(df)
    #
    #   # =>
    #     KEY1        KEY2
    #     <string> <uint8>
    #   0 B              4
    #   1 D              5
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
    # @!macro join_common_type
    #   @param type [:left_semi, :right_semi, :left_anti, :right_anti, :inner,
    #                left_outer, :right_outer, :full_outer] type of join.
    #
    # @!macro join_common_example_4
    #   @example
    #     df4 = DataFrame.new(
    #       X1: %w[A B C],
    #       Y: %w[D E F]
    #     )
    #
    #     # =>
    #       X1       Y1
    #       <string> <string>
    #     0 A        D
    #     1 B        E
    #     2 C        F
    #
    #     other4 = DataFrame.new(
    #       X2: %w[A B D],
    #       Y:  %w[e E E]
    #     )
    #
    #     # =>
    #       X1       Y1
    #       <string> <string>
    #     0 A        D
    #     1 B        E
    #     2 C        F

    # @note the order of joined results will be preserved by default.
    #   This is enabled by appending index column to sort after joining but
    #   it will cause some performance degradation. If you don't matter
    #   the order of the result, set `force_order` option to `false`.
    #
    # @overload join(other, type: :inner, suffix: '.1', force_order: true)
    #
    #   If `join_key` is not specified, common keys in self and other are used
    #   (natural keys). Returns joined dataframe.
    #
    #   @macro join_before
    #   @macro join_common_type
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_1
    #   @example
    #     df.join(other)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #
    #     df.join(other, type: :full_outer)
    #
    #     # =>
    #       KEY           X1 X2
    #       <string> <uint8> <boolean>
    #     0 A              1 true
    #     1 B              2 false
    #     2 C              3 (nil)
    #     3 D          (nil) (nil)
    #
    # @overload join(other, join_keys, type: :inner, suffix: '.1', force_order: true)
    #
    #   @macro join_before
    #   @macro join_key_in_array
    #   @macro join_common_type
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_3
    #   @example join keys in an Array
    #     df3.join(other3, [:KEY1, :KEY2])
    #
    #     # =>
    #       KEY1        KEY2
    #       <string> <uint8>
    #     0 A              1
    #
    #   @example partial join key and suffix
    #     df3.join(other3, :KEY1, suffix: '.a')
    #
    #     # =>
    #       KEY1        KEY2  KEY2.a
    #       <string> <uint8> <uint8>
    #     0 A              1       1
    #     1 B              2       4
    #
    # @overload join(other, join_key_pairs, type: :inner, suffix: '.1', force_order: true)
    #
    #   @macro join_before
    #   @macro join_key_in_hash
    #   @macro join_common_type
    #   @macro join_dorce_order
    #   @macro join_after
    #   @macro join_common_example_4
    #   @example without options
    #     df4.join(other4)
    #
    #     # =>
    #       X1       Y        X2
    #       <string> <string> <string>
    #     0 B        E        D
    #     1 B        E        B
    #
    #   @example join by key pairs
    #     df4.join(other4, { left: [:X1, :Y], right: [:X2, :Y] })
    #
    #     # =>
    #       X1       Y
    #       <string> <string>
    #     0 B        E
    #
    #   @example join by key pairs, using renaming by suffix
    #     df4.join(other4, { left: :X1, right: :X2 })
    #
    #     # =>
    #       X1       Y        Y.1
    #       <string> <string> <string>
    #     0 A        D        e
    #     1 B        E        E
    #
    def join(other, join_keys = nil, type: :inner, suffix: '.1', force_order: true)
      right_table =
        case other
        when DataFrame
          other.table
        when Arrow::Table
          other
        else
          raise DataFrameArgumentError, 'other must be a DataFrame or an Arrow::Table'
        end

      type = type.to_sym
      left_index = :__LEFT_INDEX__
      right_index = :__RIGHT_INDEX__
      if force_order && %i[full_outer right_outer].include?(type)
        left_table = assign(left_index) { indices }.table
        other = DataFrame.create(other) if other.is_a?(Arrow::Table)
        right_table = other.assign(right_index) { indices }.table
      else
        left_table = table
      end

      table_keys = left_table.keys
      other_keys = right_table.keys

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
        left_table.join(right_table, join_keys,
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
        dataframe = DataFrame.create(renamed_table).assign do |df|
          left_keys.map do |left_key|
            i_left_key = renamed_keys.index(left_key)
            right_key = renamed_keys[i_left_key + table_keys.size]
            dropper << right_key
            [left_key.to_sym, merge_array(df[left_key].data, df[right_key].data)]
          end
        end
        dataframe = dataframe.sort(left_index, right_index) if force_order

        dataframe.drop(dropper, left_index, right_index)
      when :right_outer
        dataframe =
          if joined_table.keys.uniq!
            DataFrame.create(rename_table(joined_table, left_outputs.size, suffix))
          else
            DataFrame.create(joined_table)
          end
        if force_order
          dataframe = dataframe.sort(left_index, right_index)
                               .drop(left_index, right_index)
        end
        dataframe.pick do
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
