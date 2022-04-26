# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameOutput
    def to_h
      @table.columns.each_with_object({}) do |column, result|
        result[column.name.to_sym] = column.entries
      end
    end

    def to_a
      to_h.to_a
    end

    def raw_records
      # output an array of rows without header
      @table.raw_records
    end

    def to_rover
      require 'rover-df'
      Rover::DataFrame.new(to_h)
    end

    # def to_parquet() end

    # def describe() end

    # def summary() end

    def to_s
      @table.to_s
    end

    def inspect
      format "#<#{self.class}:0x%016x>\n#{self}", object_id
    end
  end
end
