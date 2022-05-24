# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameVariableOperation
    def pick(*args, &block)
      picker = args
      if block
        raise ArgumentError 'Must not specify both arguments and block.' unless args.empty?

        picker = yield(self)
      end
      picker = [picker].flatten

      return DataFrame.new if picker.empty? || picker == [nil]

      if picker.one?
        key = picker[0]
        return create_dataframe_from_vector(key, self[key])
      end

      self[*picker]
    end
  end
end
