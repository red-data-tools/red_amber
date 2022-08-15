# frozen_string_literal: true

module RedAmber
  # Class to represent a data frame.
  # Variable @table holds an Arrow::Table object.
  class DataFrame
    # mix-in
    include DataFrameDisplayable
    include DataFrameIndexable
    include DataFrameReshaping
    include DataFrameSelectable
    include DataFrameVariableOperation
    include Helper

    # Creates a new RedAmber::DataFrame.
    #
    # @overload initialize(hash)
    #
    #   @params hash [Hash]
    #
    # @overload initialize(table)
    #
    #   @params table [Arrow::Table]
    #
    # @overload initialize(dataframe)
    #
    #   @params dataframe [RedAmber::DataFrame, Rover::DataFrame]
    #
    # @overload initialize(null)
    #
    #   @params null [NilClass] No arguments.
    #
    def initialize(*args)
      @variables = @keys = @vectors = @types = @data_types = nil
      case args
      in nil | [nil] | [] | {} | [[]] | [{}]
        # DataFrame.new, DataFrame.new([]), DataFrame.new({}), DataFrame.new(nil)
        #   returns empty DataFrame
        @table = Arrow::Table.new({}, [])
      in [Arrow::Table => table]
        @table = table
      in [DataFrame => dataframe]
        @table = dataframe.table
      in [rover_or_hash]
        begin
          # Accepts Rover::DataFrame or Hash
          @table = Arrow::Table.new(rover_or_hash.to_h)
        rescue StandardError
          raise DataFrameTypeError, "invalid argument: #{rover_or_hash}"
        end
      else
        @table = Arrow::Table.new(*args)
      end
      name_unnamed_keys
    end

    def self.load(path, options = {})
      DataFrame.new(Arrow::Table.load(path, options))
    end

    attr_reader :table

    def to_arrow
      @table
    end

    def save(output, options = {})
      @table.save(output, options)
    end

    # Returns the number of rows.
    #
    # @return [Integer] Number of rows.
    def size
      @table.n_rows
    end
    alias_method :n_rows, :size
    alias_method :n_obs, :size

    # Returns the number of columns.
    #
    # @return [Integer] Number of columns.
    def n_keys
      @table.n_columns
    end
    alias_method :n_cols, :n_keys
    alias_method :n_vars, :n_keys

    # Returns the numbers of rows and columns.
    #
    # @return [Array]
    #   Number of rows and number of columns in an array.
    #   Same as [size, n_keys].
    def shape
      [size, n_keys]
    end

    # Returns a Hash of key and Vector pairs in the columns.
    #
    # @return [Hash]
    #   key => Vector pairs for each columns.
    def variables
      @variables || @variables = init_instance_vars(:variables)
    end
    alias_method :vars, :variables

    # Returns an Array of keys.
    #
    # @return [Array]
    #   Keys in an Array.
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
    def key?(key)
      keys.include?(key.to_sym)
    end
    alias_method :has_key?, :key?

    # Returns index of specified key in the Array keys.
    #
    # @param key [Symbol, String] key to know.
    # @return [Integer]
    #   Index of key in the Array keys.
    def key_index(key)
      keys.find_index(key.to_sym)
    end
    alias_method :find_index, :key_index
    alias_method :index, :key_index

    # Returns abbreviated type names in an Array.
    #
    # @return [Array]
    #   Abbreviated Red Arrow data type names.
    def types
      @types || @types = @table.columns.map { |column| column.data.value_type.nick.to_sym }
    end

    # Returns an Array of Classes of data type.
    #
    # @return [Array]
    #   An Array of Red Arrow data type Classes.
    def type_classes
      @data_types || @data_types = @table.columns.map { |column| column.data_type.class }
    end

    # Returns Vectors in an Array.
    #
    # @return [Array]
    #   An Array of RedAmber::Vector s.
    def vectors
      @vectors || @vectors = init_instance_vars(:vectors)
    end

    # Returns row indices (start...(size+start)) in an Array.
    #
    # @param start [Object]
    #   Object which have #succ method.
    # @return [Array]
    #   An Array of indices of the row.
    # @example
    #   (when self.size == 5)
    #   - indices #=> [0, 1, 2, 3, 4]
    #   - indices(1) #=> [1, 2, 3, 4, 5]
    #   - indices('a') #=> ['a', 'b', 'c', 'd', 'e']
    def indices(start = 0)
      (start..).take(size)
    end
    alias_method :indexes, :indices

    def to_h
      variables.transform_values(&:to_a)
    end

    def to_a
      # output an array of row-oriented data without header
      # if you need column-oriented array, use `.to_h.to_a`
      @table.raw_records
    end
    alias_method :raw_records, :to_a

    def schema
      keys.zip(types).to_h
    end

    def ==(other)
      other.is_a?(DataFrame) && @table == other.table
    end

    def empty?
      variables.empty?
    end

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

    def to_rover
      require 'rover'
      Rover::DataFrame.new(to_h)
    end

    def to_iruby
      require 'iruby'
      return ['text/plain', '(empty DataFrame)'] if empty?

      if ENV.fetch('RED_AMBER_OUTPUT_MODE', 'Table') == 'TDR'
        size <= 5 ? ['text/plain', tdr_str(tally: 0)] : ['text/plain', tdr_str]
      else
        ['text/html', html_table]
      end
    end

    def group(*group_keys, &block)
      g = Group.new(self, group_keys)
      g = g.summarize(&block) if block
      g
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

    def html_table
      reduced = size > 8 ? self[0..4, -4..-1] : self

      converted = reduced.assign do
        vectors.select.with_object({}) do |vector, assigner|
          if vector.has_nil?
            assigner[vector.key] = vector.to_a.map do |e|
              e = e.nil? ? '<i>(nil)</i>' : e.to_s # nil
              e = '""' if e.empty? # empty string
              e.sub(/(\s+)/, '"\1"') # blank spaces
            end
          end
        end
      end

      html = IRuby::HTML.table(converted.to_h, maxrows: 8, maxcols: 15)
      "#{self.class} <#{size} x #{n_keys} vector#{pl(n_keys)}> #{html}"
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
