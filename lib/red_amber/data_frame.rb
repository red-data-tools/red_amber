# frozen_string_literal: true

module RedAmber
  # data frame class
  #   @table   : holds Arrow::Table object
  class DataFrame
    # mix-in
    include DataFrameDisplayable
    include DataFrameIndexable
    include DataFrameSelectable
    include DataFrameVariableOperation
    include Helper

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

    def to_arrow
      @table
    end

    def save(output, options = {})
      @table.save(output, options)
    end

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
      @keys.include?(key.to_sym)
    end
    alias_method :has_key?, :key?

    def key_index(key)
      @keys.find_index(key.to_sym)
    end
    alias_method :find_index, :key_index
    alias_method :index, :key_index

    def types
      @types || @types = @table.columns.map { |column| column.data.value_type.nick.to_sym }
    end

    def type_classes
      @data_types || @data_types = @table.columns.map { |column| column.data_type.class }
    end

    def vectors
      @vectors || @vectors = init_instance_vars(:vectors)
    end

    def indices
      (0...size).to_a
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

    def group(*group_keys)
      Group.new(self, group_keys)
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
  end
end
