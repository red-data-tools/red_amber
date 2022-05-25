# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameVariableOperation
    def pick(*args, &block)
      picker = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        picker = yield(self)
      end
      picker = [picker].flatten

      return DataFrame.new if picker.empty? || picker == [nil]

      if picker.one?
        key = picker[0]
        return create_dataframe_from_vector(key, self[key])
      end

      return select_vars_by_keys(picker) if sym_or_str?(picker)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    def drop(*args, &block)
      dropper = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        dropper = yield(self)
      end
      dropper = [dropper].flatten
      picker = keys - dropper

      return DataFrame.new if picker.empty?

      if picker.one?
        key = picker[0]
        return create_dataframe_from_vector(key, self[key])
      end

      return select_vars_by_keys(picker) if sym_or_str?(picker)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    def slice(*args, &block)
      slicer = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        slicer = yield(self)
      end
      slicer = [slicer].flatten

      if slicer.empty?
        # return a DataFrame with same keys as self without values
        return DataFrame.new(keys.each_with_object({}) { |key, h| h[key] = [] })
      end

      if slicer.one?
        case slicer[0]
        when Vector
          return select_obs_by_boolean(Arrow::BooleanArray.new(slicer[0].data))
        when Arrow::BooleanArray
          return select_obs_by_boolean(slicer[0])
        when Array
          return select_obs_by_boolean(Arrow::BooleanArray.new(slicer[0]))
        end
      end

      return select_obs_by_boolean(slicer) if booleans?(slicer)

      # expand Range like [1..3, 4] to [1, 2, 3, 4]
      expanded = expand_range(slicer)
      return select_obs_by_indeces(expanded) if integers?(expanded)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end
  end
end
