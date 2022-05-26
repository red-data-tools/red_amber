# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameVariableOperation
    # pick up some variables to create sub DataFrame
    def pick(*args, &block)
      picker = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        picker = yield(self)
      end
      picker = [picker].flatten
      return DataFrame.new if picker.empty? || picker == [nil]

      picker = keys_by_booleans(picker) if booleans?(picker)

      # DataFrame#[] creates a Vector with single key is specified.
      # DataFrame#pick creates a DataFrame with single key.
      return DataFrame.new(@table[picker]) if sym_or_str?(picker)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    # drop some variables to create remainer sub DataFrame
    def drop(*args, &block)
      dropper = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        dropper = yield(self)
      end
      dropper = [dropper].flatten

      dropper = keys_by_booleans(dropper) if booleans?(dropper)

      picker = keys - dropper
      return DataFrame.new if picker.empty?

      # DataFrame#[] creates a Vector with single key is specified.
      # DataFrame#drop creates a DataFrame with single key.
      return DataFrame.new(@table[picker]) if sym_or_str?(picker)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end
  end
end
