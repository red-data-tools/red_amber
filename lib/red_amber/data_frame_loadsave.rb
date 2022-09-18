# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameLoadSave
    # Enable `self.load` as class method of DataFrame
    def self.included(klass)
      klass.extend ClassMethods
    end

    # Enable `self.load` as class method of DataFrame
    module ClassMethods
      # Load DataFrame via Arrow::Table.load
      def load(path, options = {})
        DataFrame.new(Arrow::Table.load(path, options))
      end
    end

    # Save DataFrame
    def save(output, options = {})
      @table.save(output, options)
    end
  end
end
