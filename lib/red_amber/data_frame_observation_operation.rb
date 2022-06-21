# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameObservationOperation
    def group(aggregating_keys, func, target_keys)
      t = table.group(*aggregating_keys)
      RedAmber::DataFrame.new(t.send(func, *target_keys))
    end
  end
end
