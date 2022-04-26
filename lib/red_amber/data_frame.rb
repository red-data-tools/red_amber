# frozen_string_literal: true

module RedAmber
  # data frame class
  #   @table   : holds Arrow::Table object
  class DataFrame
    # mix-in
    include DataFrameSelectable
    include DataFrameOutput

    def initialize(*args)
      # accepts: DataFrame.new, DataFrame.new([]), DataFrame.new(nil)
      #   returns empty DataFrame
      #
      # TODO: is there a better way to create empty Table ?
      @table = Arrow::Table.new(x: []).remove_column(:x)
      # bug in gobject-introspection: ruby-gnome/ruby-gnome#1472
      #  [Arrow::Table] == [nil] shows ArgumentError
      #  temporary use yoda condition to workaround
      return if args.empty? || args == [[]] || [nil] == args

      if args.size > 1
        @table = Arrow::Table.new(*args)
      else
        arg = args[0]
        @table =
          case arg
          when Arrow::Table then arg
          when DataFrame    then arg.table
          when Hash         then Arrow::Table.new(*args)
          else
            raise DataFrameTypeError, "invalid argument: #{args}"
          end
      end
    end

    def self.load(path, options: {})
      @table = Arrow::Table.load(path, options)
    end

    attr_reader :table

    # Properties ===
    def n_rows
      @table.n_rows
    end
    alias_method :nrow, :n_rows
    alias_method :size, :n_rows
    alias_method :length, :n_rows

    def n_columns
      @table.n_columns
    end
    alias_method :ncol, :n_columns
    alias_method :width, :n_columns

    def empty?
      @table.columns.empty?
    end

    def shape
      [n_rows, n_columns]
    end

    def column_names
      @table.columns.map { |column| column.name.to_sym }
    end
    alias_method :keys, :column_names
    alias_method :header, :column_names

    def types(class_name: false)
      @table.columns.map do |column|
        r = column.data_type
        class_name ? r.class : r.to_s.to_sym
      end
    end

    def vectors
      @table.columns.map do |column|
        Vector.new(column.data)
      end
    end
  end
end
