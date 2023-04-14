# frozen_string_literal: true

module RedAmber
  # Class to represent a data frame.
  # Variable @table holds an Arrow::Table object.
  class DataFrame
    # Mix-in
    include DataFrameCombinable
    include DataFrameDisplayable
    include DataFrameIndexable
    include DataFrameLoadSave
    include DataFrameReshaping
    include DataFrameSelectable
    include DataFrameVariableOperation
    include Helper

    using RefineArrowTable
    using RefineHash

    class << self
      # Quicker DataFrame constructor from a `Arrow::Table`.
      #
      # @param table [Arrow::Table]
      #   A table to have in the DataFrame.
      # @return [DataFrame]
      #   Initialized DataFrame.
      #
      # @note This method will allocate table directly and may be used in the method.
      # @note `table` must have unique keys.
      #
      def create(table)
        instance = allocate
        instance.instance_variable_set(:@table, table)
        instance
      end

      # Return new DataFrame for specified schema and value.
      #
      # @param dataframe_for_schema [Dataframe]
      #   schema of this dataframe will be used.
      # @param dataframe_for_value [DataFrame]
      #   column values of thes dataframe will be used.
      # @return [DataFrame]
      #   created DataFrame.
      # @since 0.4.1
      #
      def new_dataframe_with_schema(dataframe_for_schema, dataframe_for_value)
        DataFrame.create(
          Arrow::Table.new(dataframe_for_schema.table.schema,
                           dataframe_for_value.table.columns)
        )
      end
    end

    # Creates a new DataFrame.
    #
    # @overload initialize(hash)
    #   Initialize a DataFrame by a Hash.
    #
    #   @param hash [Hash<key => <Array, Arrow::Array, #to_arrow_array>>]
    #     a Hash of `key` with array-like for column values.
    #     `key`s are Symbol or String.
    #   @example Initialize by a Hash
    #     hash = { x: [1, 2, 3], y: %w[A B C] }
    #     DataFrame.new(hash)
    #   @example Initialize by a Hash like arguments.
    #     DataFrame.new(x: [1, 2, 3], y: %w[A B C])
    #   @example Initialize from #to_arrow_array responsibles.
    #     # #to_arrow_array responsible `array-like` is also available.
    #     require 'arrow-numo-narray'
    #     DataFrame.new(numo: Numo::DFloat.new(3).rand)
    #
    # @overload initialize(table)
    #   Initialize a DataFrame by an `Arrow::Table`.
    #
    #   @param table [Arrow::Table]
    #     a table to have in the DataFrame.
    #   @example Initialize by a Table
    #     table = Arrow::Table.new(x: [1, 2, 3], y: %w[A B C])
    #     DataFrame.new(table)
    #
    # @overload initialize(schama, row_oriented_array)
    #   Initialize a DataFrame by schema and row_oriented_array.
    #
    #   @param schema [Hash<key => type>]
    #     a schema of key and data type.
    #   @param row_oriented_array [Array]
    #     an Array of rows.
    #   @example Initialize by a schema and a row_oriented_array.
    #     schema = { x: :uint8, y: :string }
    #     row_oriented_array = [[1, 'A'], [2, 'B'], [3, 'C']]
    #     DataFrame.new(schema, row_oriented_array)
    #
    # @overload initialize(arrowable)
    #   Initialize DataFrame by a `#to_arrow` responsible object.
    #
    #   @param arrowable [#to_arrow]
    #     Any object which responds to `#to_arrow`.
    #     `#to_arrow` must return `Arrow::Table`.
    #
    #   @note `RedAmber::DataFrame` itself is readable by this.
    #   @note Hash is refined to respond to `#to_arrow` in this class.
    #   @example Initialize by Red Dataset object.
    #     require 'datasets-arrow'
    #     dataset = Datasets::Penguins.new
    #     penguins = DataFrame.new(dataset)
    #   @since 0.2.2
    #
    # @overload initialize(rover_like)
    #   Initialize DataFrame by a `Rover::DataFrame`-like `#to_h` responsible object.
    #
    #   @param rover_like [#to_h]
    #     Any object which responds to `#to_h`.
    #     `#to_h` must return a Hash which is convertable by `Arrow::Table.new`.
    #
    #   @note `Rover::DataFrame` is readable by this.
    #
    # @overload initialize()
    #   Create empty DataFrame
    #
    #   @example
    #     DataFrame.new
    #
    # @overload initialize(empty)
    #   Create empty DataFrame
    #
    #   @param empty [nil, [], {}]
    #
    #   @example Return empty DataFrame.
    #     DataFrame.new([])
    #     DataFrame.new({})
    #     DataFrame.new(nil)
    #
    def initialize(*args)
      case args
      in nil | [nil] | [] | {} | [[]] | [{}]
        @table = Arrow::Table.new({}, [])
      in [Arrow::Table => table]
        @table = table
      in [arrowable] if arrowable.respond_to?(:to_arrow)
        table = arrowable.to_arrow
        unless table.is_a?(Arrow::Table)
          raise DataFrameTypeError,
                "to_arrow must return an Arrow::Table but #{table.class}: #{arrowable}"
        end
        @table = table
      in [rover_like] if rover_like.respond_to?(:to_h)
        begin
          # Accepts Rover::DataFrame
          @table = Arrow::Table.new(rover_like.to_h)
        rescue StandardError
          raise DataFrameTypeError, "to_h must return Arrowable object: #{rover_like}"
        end
      else
        begin
          @table = Arrow::Table.new(*args)
        rescue StandardError
          raise DataFrameTypeError, "invalid argument to create Arrow::Table: #{args}"
        end
      end

      name_unnamed_keys
      check_duplicate_keys(keys)
    end

    # Returns the table having within.
    #
    # @return [Arrow::Table]
    #   the table within.
    #
    attr_reader :table
    alias_method :to_arrow, :table

    # Returns the number of records (rows).
    #
    # @return [Integer]
    #   number of records (rows).
    #
    def size
      @table.n_rows
    end
    alias_method :n_records, :size
    alias_method :n_obs, :size
    alias_method :n_rows, :size

    # Returns the number of variables (columns).
    #
    # @return [Integer]
    #   number of variables (columns).
    #
    def n_keys
      @table.n_columns
    end
    alias_method :n_variables, :n_keys
    alias_method :n_vars, :n_keys
    alias_method :n_cols, :n_keys

    # Returns the numbers of rows and columns.
    #
    # @return [Array]
    #   number of rows and number of columns in an array.
    #   Same as [size, n_keys].
    #
    def shape
      [size, n_keys]
    end

    # Returns a Hash of key and Vector pairs in the columns.
    #
    # @return [Hash]
    #   `key => Vector` pairs for each columns.
    #
    def variables
      @variables ||= init_instance_vars(:variables)
    end
    alias_method :vars, :variables

    # Returns an Array of keys.
    #
    # @return [Array]
    #   keys in an Array.
    #
    def keys
      @keys ||= init_instance_vars(:keys)
    end
    alias_method :column_names, :keys
    alias_method :var_names, :keys

    # Returns true if self has a specified key in the argument.
    #
    # @param key [Symbol, String]
    #   key to test.
    # @return [Boolean]
    #   returns true if self has key in Symbol.
    #
    def key?(key)
      keys.include?(key.to_sym)
    end
    alias_method :has_key?, :key?

    # Returns index of specified key in the Array keys.
    #
    # @param key [Symbol, String]
    #   key to know.
    # @return [Integer]
    #   index of key in the Array keys.
    #
    def key_index(key)
      keys.find_index(key.to_sym)
    end
    alias_method :find_index, :key_index
    alias_method :index, :key_index

    # Returns abbreviated type names in an Array.
    #
    # @return [Array]
    #   abbreviated Red Arrow data type names.
    #
    def types
      @types ||= @table.columns.map do |column|
        column.data.value_type.nick.to_sym
      end
    end

    # Returns an Array of Classes of data type.
    #
    # @return [Array]
    #   an Array of Red Arrow data type Classes.
    #
    def type_classes
      @type_classes ||= @table.columns.map { |column| column.data_type.class }
    end

    # Returns Vectors in an Array.
    #
    # @return [Array]
    #   an Array of Vector.
    #
    def vectors
      @vectors ||= init_instance_vars(:vectors)
    end

    # Returns column-oriented data in a Hash.
    #
    # @return [Hash]
    #   a Hash of 'key => column_in_an_array'.
    #
    def to_h
      variables.transform_values(&:to_a)
    end

    # Returns a row-oriented array without header.
    #
    # @return [Array]
    #   row-oriented data without header.
    #
    # @note If you need column-oriented array, use `.to_h.to_a`.
    #
    def to_a
      @table.raw_records
    end
    alias_method :raw_records, :to_a

    # Returns column name and data type in a Hash.
    #
    # @return [Hash]
    #   column name and data type.
    #
    # @example
    #   RedAmber::DataFrame.new(x: [1, 2, 3], y: %w[A B C]).schema
    #   # => {:x=>:uint8, :y=>:string}
    #
    def schema
      keys.zip(types).to_h
    end

    # Compare DataFrames.
    #
    # @return [true, false]
    #   true if other is a DataFrame and table is same.
    #   Otherwise return false.
    #
    def ==(other)
      other.is_a?(DataFrame) && @table == other.table
    end

    # Check if it is a empty DataFrame.
    #
    # @return [true, false
    #  ] true if it has no columns.
    #
    def empty?
      variables.empty?
    end

    # Enumerate for each row.
    #
    # @overload each_row
    #   Returns Enumerator when no block given.
    #
    #   @return [Enumerator]
    #     enumerator of each rows.
    #
    # @overload each_row(&block)
    #   Yields with key and row pairs.
    #
    #   @yieldparam key_row_pairs [Hash]
    #     key and row pairs.
    #   @yieldreturn [Integer]
    #     size of the DataFrame.
    #   @return [Integer]
    #     returns size.
    #
    def each_row
      return enum_for(:each_row) unless block_given?

      size.times do |i|
        key_row_pairs =
          vectors.each_with_object({}) do |v, h|
            h[v.key] = v.data[i]
          end
        yield key_row_pairs
      end
    end

    # Returns self in a `Rover::DataFrame`.
    #
    # @return [Rover::DataFrame]
    #   a `Rover::DataFrame`.
    #
    def to_rover
      require 'rover'
      Rover::DataFrame.new(to_h)
    end

    # Create a Group object. Or create a Group and summarize it.
    #
    # @overload group(*group_keys)
    #   Create a Group object.
    #
    #   @param group_keys [Array<Symbol, String>]
    #     keys for grouping.
    #   @return [Group]
    #     Group object.
    #   @example Create a Group
    #     penguins.group(:species)
    #
    #     # =>
    #     #<RedAmber::Group : 0x000000000000c3c8>
    #       species   group_count
    #       <string>      <uint8>
    #     0 Adelie            152
    #     1 Chinstrap          68
    #     2 Gentoo            124
    #
    # @overload group(*group_keys)
    #   Create a Group and summarize it by aggregation functions from the block.
    #
    #   @yieldparam group [Group]
    #     passes Group object.
    #   @yieldreturn [DataFrame, Array<DataFrame>]
    #     an aggregated DataFrame or an array of aggregated DataFrames.
    #   @return [DataFrame]
    #     summarized DataFrame.
    #   @example Create a group and summarize it.
    #     penguins.group(:species)  { mean(:bill_length_mm) }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000000f3fc>
    #       species   mean(bill_length_mm)
    #       <string>              <double>
    #     0 Adelie                   38.79
    #     1 Chinstrap                48.83
    #     2 Gentoo                    47.5
    #
    def group(*group_keys, &block)
      g = Group.new(self, group_keys)
      g = g.summarize(&block) if block
      g
    end

    # Create SubFrames by value grouping.
    #
    # [Experimental feature] this method may be removed or be changed in the future.
    # @param keys [List<Symbol, String>, Array<Symbol, String>]
    #   grouping keys.
    # @return [SubFrames]
    #   a created SubFrames grouped by column values on `keys`.
    # @example
    #   df.sub_by_value(:y)
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000000fc08>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
    #   3 SubFrames: [2, 3, 1] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000000fc1c>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fc30>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   ---
    #   #<RedAmber::DataFrame : 1 x 3 Vectors, 0x000000000000fc44>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       6 C        false
    #
    # @since 0.4.0
    #
    def sub_by_value(*keys)
      SubFrames.new(self, group(keys.flatten).filters)
    end
    alias_method :subframes_by_value, :sub_by_value
    alias_method :sub_group, :sub_by_value

    # Create SubFrames by Windowing with `from`, `size` and `step`.
    #
    # [Experimental feature] this method may be removed or be changed in the future.
    # @param from [Integer]
    #   start position of window.
    # @param size [Integer]
    #   window size.
    # @param step [Integer]
    #   moving step of window.
    # @return [SubFrames]
    #   a created SubFrames.
    # @example
    #   df.sub_by_window(size: 4, step: 2)
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000000fc58>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
    #   2 SubFrames: [4, 4] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 4 x 3 Vectors, 0x000000000000fc6c>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   2       3 B        false
    #   3       4 B        (nil)
    #   ---
    #   #<RedAmber::DataFrame : 4 x 3 Vectors, 0x000000000000fc80>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   3       6 C        false
    #
    # @since 0.4.0
    #
    def sub_by_window(from: 0, size: nil, step: 1)
      SubFrames.new(self) do
        from.step(by: step, to: (size() - size)).map do |i| # rubocop:disable Style/MethodCallWithoutArgsParentheses
          [*i...(i + size)]
        end
      end
    end
    alias_method :subframes_by_window, :sub_by_window

    # Create SubFrames by Grouping/Windowing by posion from a enumrator method.
    #
    # This method will process the indices of self by enumerator.
    # [Experimental feature] this method may be removed or be changed in the future.
    # @param enumerator_method [Symbol]
    #   Enumerator name.
    # @param args [<Object>]
    #   arguments for the enumerator method.
    # @return [SubFrames]
    #   a created SubFrames.
    # @example Create a SubFrames object sliced by 3 rows.
    #   df.sub_by_enum(:each_slice, 3)
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000000fd20>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
    #   2 SubFrames: [3, 3] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fd34>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   2       3 B        false
    #   ---
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fd48>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       4 B        (nil)
    #   1       5 B        true
    #   2       6 C        false
    #
    # @example Create a SubFrames object for each consecutive 3 rows.
    #   df.sub_by_enum(:each_cons, 4)
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000000fd98>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
    #   3 SubFrames: [4, 4, 4] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 4 x 3 Vectors, 0x000000000000fdac>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       2 A        true
    #   2       3 B        false
    #   3       4 B        (nil)
    #   ---
    #   #<RedAmber::DataFrame : 4 x 3 Vectors, 0x000000000000fdc0>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       2 A        true
    #   1       3 B        false
    #   2       4 B        (nil)
    #   3       5 B        true
    #   ---
    #   #<RedAmber::DataFrame : 4 x 3 Vectors, 0x000000000000fdd4>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       4 B        (nil)
    #   2       5 B        true
    #   3       6 C        false
    #
    # @since 0.4.0
    #
    def sub_by_enum(enumerator_method, *args)
      SubFrames.new(self, indices.send(enumerator_method, *args).to_a)
    end
    alias_method :subframes_by_enum, :sub_by_enum

    # Create SubFrames by windowing with a kernel (i.e. masked window) and step.
    #
    # [Experimental feature] this method may be removed or be changed in the future.
    # @param kernel [Array<true, false>, Vector]
    #   boolean array-like to pick records in the window.
    #   Kernel is a boolean Array and it behaves like a masked window.
    # @param step [Integer]
    #   moving step of window.
    # @return [SubFrames]
    #   a created SubFrames.
    # @example
    #   kernel = [true, false, false, true]
    #   df.sub_by_kernel(kernel, step: 2)
    #
    #   # =>
    #   #<RedAmber::SubFrames : 0x000000000000fde8>
    #   @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
    #   2 SubFrames: [2, 2] in sizes.
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000000fdfc>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       1 A        false
    #   1       4 B        (nil)
    #   ---
    #   #<RedAmber::DataFrame : 2 x 3 Vectors, 0x000000000000fe10>
    #           x y        z
    #     <uint8> <string> <boolean>
    #   0       3 B        false
    #   1       6 C        false
    #
    # @since 0.4.0
    #
    def sub_by_kernel(kernel, step: 1)
      limit_size = size - kernel.size
      kernel_vector = Vector.new(kernel.concat([nil] * limit_size))
      SubFrames.new(self) do
        0.step(by: step, to: limit_size).map do |i|
          kernel_vector.shift(i)
        end
      end
    end
    alias_method :subframes_by_kernel, :sub_by_kernel

    # Generic builder of sub-dataframes from self.
    #
    # [Experimental feature] this method may be removed or be changed in the future.
    # @overload build_subframes(subset_specifier)
    #   Create a new SubFrames object.
    #
    #   @param subset_specifier [Array<Vector>, Array<array-like>]
    #     an Array of numeric indices or boolean filters
    #     to create subsets of DataFrame.
    #   @return [SubFrames]
    #     new SubFrames.
    #   @example
    #     df.build_subframes([[0, 2, 4], [1, 3, 5]])
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x000000000000fe9c>
    #     @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
    #     2 SubFrames: [3, 3] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000feb0>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       3 B        false
    #     2       5 B        true
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fec4>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       2 A        true
    #     1       4 B        (nil)
    #     2       6 C        false
    #
    # @overload build_subframes
    #   Create a new SubFrames object by block.
    #
    #   @yield [self]
    #     the block is called within the context of self.
    #     (Block is called by instance_eval(&block). )
    #   @yieldreturn [Array<numeric_array_like>, Array<boolean_array_like>]
    #     an Array of index or boolean array-likes to create subsets of DataFrame.
    #     All array-likes are responsible to #numeric? or #boolean?.
    #   @example
    #     dataframe.build_subframes do
    #       even = indices.map(&:even?)
    #       [even, !even]
    #     end
    #
    #     # =>
    #     #<RedAmber::SubFrames : 0x000000000000fe60>
    #     @baseframe=#<RedAmber::DataFrame : 6 x 3 Vectors, 0x000000000000fba4>
    #     2 SubFrames: [3, 3] in sizes.
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fe74>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       3 B        false
    #     2       5 B        true
    #     ---
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000fe88>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       2 A        true
    #     1       4 B        (nil)
    #     2       6 C        false
    #
    # @since 0.4.0
    #
    def build_subframes(subset_specifier = nil, &block)
      if block
        SubFrames.new(self, instance_eval(&block))
      else
        SubFrames.new(self, subset_specifier)
      end
    end

    # Returns a Vector such that all elements have value `scalar`
    #   and have same size as self.
    #
    # @overload propagate(scalar)
    #   Specifies scalar as an agrument.
    #
    #   @param scalar [scalar]
    #     a value to propagate in Vector.
    #   @return [Vector]
    #     created Vector.
    #   @example propagate a value
    #     df
    #     # =>
    #     #<RedAmber::DataFrame : 6 x 3 Vectors, 0x00000000000849a4>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       2 A        true
    #     2       3 B        false
    #     3       4 B        (nil)
    #     4       5 B        true
    #     5       6 C        false
    #
    #     df.assign(:sum_x) { propagate(x.sum) }
    #     # =>
    #     #<RedAmber::DataFrame : 6 x 4 Vectors, 0x000000000007bd04>
    #             x y        z           sum_x
    #       <uint8> <string> <boolean> <uint8>
    #     0       1 A        false          21
    #     1       2 A        true           21
    #     2       3 B        false          21
    #     3       4 B        (nil)          21
    #     4       5 B        true           21
    #     5       6 C        false          21
    #
    #     # Using `Vector#propagate` like below has same result as above.
    #     df.assign(:sum_x) { x.propagate(:sum) }
    #
    #     # Also it is same as creating column from an Array.
    #     df.assign(:sum_x) { [x.sum] * size }
    #
    # @overload propagate
    #
    #   @yieldparam self [DataFrame]
    #     gives self to the block.
    #   @yieldreturn [scalar]
    #     a value to propagate in Vector
    #   @return [Vector]
    #     created Vector.
    #   @example propagate the value from the block
    #     df.assign(:range) { propagate { x.max - x.min } }
    #     # =>
    #     #<RedAmber::DataFrame : 6 x 4 Vectors, 0x00000000000e603c>
    #             x y        z           range
    #       <uint8> <string> <boolean> <uint8>
    #     0       1 A        false           5
    #     1       2 A        true            5
    #     2       3 B        false           5
    #     3       4 B        (nil)           5
    #     4       5 B        true            5
    #     5       6 C        false           5
    #
    # @since 0.5.0
    #
    def propagate(scalar = nil, &block)
      if block
        raise VectorArgumentError, "can't specify both function and block" if scalar

        scalar = instance_eval(&block)
      end
      Vector.new([scalar] * size)
    end

    # Catch variable (column) key as method name.
    def method_missing(name, *args, &block)
      return variables[name] if args.empty? && key?(name)

      super
    end

    # Catch variable (column) key as method name.
    def respond_to_missing?(name, include_private)
      return true if key?(name)

      super
    end

    private

    # initialize @variable, @keys, @vectors and return one of them
    def init_instance_vars(var)
      ary =
        @table
          .columns
          .each_with_object([{}, [], []]) do |column, (variables, keys, vectors)|
            v = Vector.create(column.data)
            k = column.name.to_sym
            v.key = k
            variables[k] = v
            keys << k
            vectors << v
          end

      @variables, @keys, @vectors = ary
      ary[%i[variables keys vectors].index(var)]
    end

    def check_duplicate_keys(array)
      org = array.dup
      return unless array.uniq!

      raise DataFrameArgumentError,
            "duplicate keys: #{org.tally.select { |_k, v| v > 1 }.keys}"
    end

    def name_unnamed_keys
      return unless @table.key?(:'')

      unnamed = (:unnamed1..).find { |name| !@table.key?(name) }
      fields =
        @table.schema.fields.map do |field|
          if field.name.empty?
            Arrow::Field.new(unnamed, field.data_type)
          else
            field
          end
        end
      schema = Arrow::Schema.new(fields)
      @table = Arrow::Table.new(schema, @table.columns)
    end
  end
end
