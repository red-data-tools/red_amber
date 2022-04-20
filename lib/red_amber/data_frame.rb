# frozen_string_literal: true

module RedAmber
  # data frame class
  #   @vectors : an Array of columnar data (Vector)
  #   @table   : holds Arrow::Table object
  class DataFrame
    def initialize(*args)
      @table = Arrow::Table.new(*args)
      @vectors = collect_vectors
    end

    def self.load(path, options: {})
      @table = Arrow::Table.load(path, options)
      @vectors = collect_vectors
    end
    attr_reader :table, :vectors

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

    def shape
      [n_rows, n_columns]
    end

    def column_names
      @table.columns.map { |column| column.name.to_sym }
    end
    alias_method :keys, :column_names
    alias_method :header, :column_names

    def types
      @table.columns.map { |column| column.data_type.to_s.to_sym }
    end

    def to_s
      @table.to_s
    end

    def inspect
      format "#<#{self.class}:0x%016x>\n#{self}", object_id
    end

    # def describe() end

    # def summary() end

    # Output ===
    def to_h
      @table.columns.each_with_object({}) do |column, result|
        result[column.name.to_sym] = column.entries
      end
    end

    def to_a
      to_h.to_a
    end

    def raw_records
      # output an array of raws without header
      @table.raw_records
    end

    def to_rover
      require 'rover-df'
      Rover::DataFrame.new(to_h)
    end

    # def to_parquet

    private # =====

    def collect_vectors
      @table.columns.map do |column|
        RedAmber::Vector.new(column.data)
      end
    end
  end
end
