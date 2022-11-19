# frozen_string_literal: true

module RedAmber
  # Class to represent a data frame.
  # Variable @table holds an Arrow::Table object.
  class DataFrame
    # mix-in
    include DataFrameCombinable
    include DataFrameDisplayable
    include DataFrameIndexable
    include DataFrameLoadSave
    include DataFrameReshaping
    include DataFrameSelectable
    include DataFrameVariableOperation
    include Helper

    using RefineHash

    # Quicker DataFrame construction from a `Arrow::Table`.
    #
    # @params table [Arrow::Table] A table to have in the DataFrame.
    # @return [DataFrame] Initialized DataFrame.
    #
    # @note This method will allocate table directly and may be used in the method.
    # @note `table` must have unique keys.
    def self.create(table)
      instance = allocate
      instance.instance_variable_set(:@table, table)
      instance.check_duplicate_keys(instance.keys)
      instance
    end

    # Creates a new DataFrame.
    #
    # @overload initialize(table)
    #   Initialize DataFrame by an `Arrow::Table`
    #
    #   @param table [Arrow::Table]
    #     A table to have in the DataFrame.
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
    #   @example DataFrame.new
    #
    # @overload initialize(empty)
    #   Create empty DataFrame
    #
    #   @param empty [nil, [], {}]
    #
    #   @example DataFrame.new([]), DataFrame.new({}), DataFrame.new(nil)
    #
    # @overload initialize(args)
    #
    #   @param args [values]
    #     Accepts any argments which is valid for `Arrow::Table.new(args)`.
    #     See {https://github.com/apache/arrow/blob/master/ruby/red-arrow/lib/arrow/table.rb table.rb in Red Arrow}.
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
    # @return [Arrow::Table] The table within.
    #
    attr_reader :table

    alias_method :to_arrow, :table

    # Returns the number of rows.
    #
    # @return [Integer] Number of rows.
    #
    def size
      @table.n_rows
    end
    alias_method :n_records, :size
    alias_method :n_obs, :size
    alias_method :n_rows, :size

    # Returns the number of columns.
    #
    # @return [Integer] Number of columns.
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
    #   Number of rows and number of columns in an array.
    #   Same as [size, n_keys].
    #
    def shape
      [size, n_keys]
    end

    # Returns a Hash of key and Vector pairs in the columns.
    #
    # @return [Hash]
    #   {key => Vector} pairs for each columns.
    #
    def variables
      @variables || @variables = init_instance_vars(:variables)
    end
    alias_method :vars, :variables

    # Returns an Array of keys.
    #
    # @return [Array]
    #   Keys in an Array.
    #
    def keys
      @keys || @keys = init_instance_vars(:keys)
    end
    alias_method :column_names, :keys
    alias_method :var_names, :keys

    # Returns true if self has a specified key in the argument.
    #
    # @param key [Symbol, String] Key to test.
    # @return [Boolean]
    #   Returns true if self has key in Symbol.
    #
    def key?(key)
      keys.include?(key.to_sym)
    end
    alias_method :has_key?, :key?

    # Returns index of specified key in the Array keys.
    #
    # @param key [Symbol, String] key to know.
    # @return [Integer]
    #   Index of key in the Array keys.
    #
    def key_index(key)
      keys.find_index(key.to_sym)
    end
    alias_method :find_index, :key_index
    alias_method :index, :key_index

    # Returns abbreviated type names in an Array.
    #
    # @return [Array]
    #   Abbreviated Red Arrow data type names.
    #
    def types
      @types || @types = @table.columns.map { |column| column.data.value_type.nick.to_sym }
    end

    # Returns an Array of Classes of data type.
    #
    # @return [Array]
    #   An Array of Red Arrow data type Classes.
    #
    def type_classes
      @data_types || @data_types = @table.columns.map { |column| column.data_type.class }
    end

    # Returns Vectors in an Array.
    #
    # @return [Array]
    #   An Array of `RedAmber::Vector`s.
    #
    def vectors
      @vectors || @vectors = init_instance_vars(:vectors)
    end

    # Returns row indices (start...(size+start)) in a Vector.
    #
    # @param start [Object]
    #   Object which have `#succ` method.
    #
    # @return [Array]
    #   A Vector of row indices.
    #
    # @example
    #   (when self.size == 5)
    #   - indices #=> Vector[0, 1, 2, 3, 4]
    #   - indices(1) #=> Vector[1, 2, 3, 4, 5]
    #   - indices('a') #=> Vector['a', 'b', 'c', 'd', 'e']
    #
    def indices(start = 0)
      Vector.new((start..).take(size))
    end
    alias_method :indexes, :indices

    # Returns column-oriented data in a Hash.
    #
    # @return [Hash] A Hash of {key => column_in_an_array}.
    #
    def to_h
      variables.transform_values(&:to_a)
    end

    # Returns a row-oriented array without header.
    #
    # @return [Array] Row-oriented data without header.
    #
    # @note If you need column-oriented array, use `.to_h.to_a`.
    #
    def to_a
      @table.raw_records
    end
    alias_method :raw_records, :to_a

    # Returns column name and data type in a Hash.
    #
    # @return [Hash] Column name and data type.
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
    #   True if other is a DataFrame and table is same.
    #   Otherwise return false.
    #
    def ==(other)
      other.is_a?(DataFrame) && @table == other.table
    end

    # Check if it is a empty DataFrame.
    #
    # @return [true, false] True if it has no columns.
    #
    def empty?
      variables.empty?
    end

    # Enumerate for each row.
    #
    # @overload each_row
    #   Returns Enumerator when no block given.
    #
    #   @return [Enumerator] Enumerator of each rows.
    #
    # @overload each_row(&block)
    #   Yields with key and row pairs.
    #
    #   @yield [key_row_pairs] Yields with key and row pairs.
    #   @yieldparam [Hash] Key and row pairs.
    #   @yieldreturn [Integer] Size of the DataFrame.
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
    # @return [Rover::DataFrame] A `Rover::DataFrame`.
    #
    def to_rover
      require 'rover'
      Rover::DataFrame.new(to_h)
    end

    def group(*group_keys, &block)
      g = Group.new(self, group_keys)
      g = g.summarize(&block) if block
      g
    end

    def method_missing(name, *args, &block)
      return v(name) if args.empty? && key?(name)

      super
    end

    def respond_to_missing?(name, include_private)
      return true if key?(name)

      super
    end

    # For internal use
    def check_duplicate_keys(keys)
      return if keys == keys.uniq

      raise DataFrameArgumentError, "duplicate keys: #{keys.tally.select { |_k, v| v > 1 }.keys}"
    end

    private

    # initialize @variable, @keys, @vectors and return one of them
    def init_instance_vars(var)
      ary = @table.columns.each_with_object([{}, [], []]) do |column, (variables, keys, vectors)|
        v = Vector.new(column.data)
        k = column.name.to_sym
        v.key = k
        variables[k] = v
        keys << k
        vectors << v
      end
      @variables, @keys, @vectors = ary
      ary[%i[variables keys vectors].index(var)]
    end

    def name_unnamed_keys
      return unless @table[:'']

      # We can't use #keys because it causes mismatch of @table and @keys
      keys = @table.schema.fields.map { |f| f.name.to_sym }
      unnamed = (:unnamed1..).find { |e| !keys.include?(e) }
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
