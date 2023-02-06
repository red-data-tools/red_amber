# frozen_string_literal: true

module RedAmber
  # Mix-ins for the class DataFrame
  module DataFrameIndexable
    # Common method
    def map_indices(*indices)
      return self if indices.empty?

      indices = indices[0].data if indices[0].is_a?(Vector)

      new_dataframe_by(indices)
    end

    # @param sort_keys [Arrow::SortKey]
    #   :key, "key" or "+key" denotes ascending,
    #   "-key" denotes descending order
    # @return [RedAmber::Vector] Sorted indices in Vector
    def sort_indices(*sort_keys)
      indices = @table.sort_indices(sort_keys.flatten)
      Vector.create(indices)
    end

    # @return [RedAmber::DataFrame] Sorted DataFrame
    def sort(*sort_keys)
      indices = @table.sort_indices(sort_keys.flatten)

      new_dataframe_by(indices)
    end

    private

    def new_dataframe_by(index_array)
      t = Arrow::Function.find(:take).execute([@table, index_array]).value
      DataFrame.create(t)
    end
  end
end
