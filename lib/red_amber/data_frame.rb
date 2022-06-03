# frozen_string_literal: true

module RedAmber
  # data frame class
  #   @table   : holds Arrow::Table object
  class DataFrame
    # mix-in
    include DataFrameDisplayable
    include DataFrameHelper
    include DataFrameSelectable
    include DataFrameObservationOperation
    include DataFrameVariableOperation

    def initialize(*args)
      @variables = @keys = @vectors = @types = @data_types = nil
      # bug in gobject-introspection: ruby-gnome/ruby-gnome#1472
      #  [Arrow::Table] == [nil] shows ArgumentError
      #  temporary use yoda condition to workaround
      if args.empty? || args == [[]] || args == [{}] || [nil] == args
        # DataFrame.new, DataFrame.new([]), DataFrame.new({}), DataFrame.new(nil)
        #   returns empty DataFrame
        @table = Arrow::Table.new({}, [])
      elsif args.size > 1
        @table = Arrow::Table.new(*args)
      else
        arg = args[0]
        @table =
          case arg
          when Arrow::Table then arg
          when DataFrame then arg.table
          when Rover::DataFrame then Arrow::Table.new(arg.to_h)
          when Hash then Arrow::Table.new(arg)
          else
            raise DataFrameTypeError, "invalid argument: #{arg}"
          end
      end
    end

    def self.load(path, options = {})
      DataFrame.new(Arrow::Table.load(path, options))
    end

    attr_reader :table

    def save(output, options = {})
      @table.save(output, options)
    end

    # Properties ===
    def size
      @table.n_rows
    end
    alias_method :n_rows, :size
    alias_method :n_obs, :size

    def n_keys
      @table.n_columns
    end
    alias_method :n_cols, :n_keys
    alias_method :n_vars, :n_keys

    def shape
      [size, n_keys]
    end

    def variables
      @variables || @variables = init_instance_vars(:variables)
    end
    alias_method :vars, :variables

    def keys
      @keys || @keys = init_instance_vars(:keys)
    end
    alias_method :column_names, :keys
    alias_method :var_names, :keys

    def key?(key)
      keys.include?(key.to_sym)
    end
    alias_method :has_key?, :key?

    def key_index(key)
      keys.find_index(key.to_sym)
    end
    alias_method :find_index, :key_index
    alias_method :index, :key_index

    def types
      @types || @types = @table.columns.map { |column| column.data.value_type.nick.to_sym }
    end

    def data_types
      @data_types || @data_types = @table.columns.map { |column| column.data_type.class }
    end

    def vectors
      @vectors || @vectors = init_instance_vars(:vectors)
    end

    def indexes
      0...size
    end
    alias_method :indices, :indexes

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

    def to_rover
      Rover::DataFrame.new(to_h)
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
  end
end
