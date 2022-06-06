# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameObservationOperation
    # slice and select some observations to create sub DataFrame
    def slice(*args, &block)
      slicer = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        slicer = instance_eval(&block)
      end
      slicer = [slicer].flatten
      return remove_all_values if slicer.empty? || slicer[0].nil?

      # filter with same length
      booleans = nil
      if slicer[0].is_a?(Vector) || slicer[0].is_a?(Arrow::BooleanArray)
        booleans = slicer[0].to_a
      elsif slicer.size == size && booleans?(slicer)
        booleans = slicer
      end
      return select_obs_by_boolean(booleans) if booleans

      # filter with indexes
      slicer = expand_range(slicer)
      return select_obs_by_indeces(slicer) if integers?(slicer)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    # remove selected observations to create sub DataFrame
    def remove(*args, &block)
      remover = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        remover = instance_eval(&block)
      end
      remover = [remover].flatten

      return self if remover.empty?

      # filter with same length
      booleans = nil
      if remover[0].is_a?(Vector) || remover[0].is_a?(Arrow::BooleanArray)
        booleans = remover[0].to_a
      elsif remover.size == size && booleans?(remover)
        booleans = remover
      end
      if booleans
        inverted = booleans.map(&:!)
        return select_obs_by_boolean(inverted)
      end

      # filter with indexes
      slicer = indexes.to_a - expand_range(remover)
      return remove_all_values if slicer.empty?
      return select_obs_by_indeces(slicer) if integers?(slicer)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    def remove_nil
      func = Arrow::Function.find(:drop_null)
      DataFrame.new(func.execute([table]).value)
    end
    alias_method :drop_nil, :remove_nil

    private

    # return a DataFrame with same keys as self without values
    def remove_all_values
      DataFrame.new(keys.each_with_object({}) { |key, h| h[key] = [] })
    end
  end
end
