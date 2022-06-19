# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameSelectable
    # select columns: [symbol] or [string]
    # select rows: [array of index], [range]
    def [](*args)
      args.flatten!
      raise DataFrameArgumentError, 'Empty dataframe' if empty?
      raise DataFrameArgumentError, 'Empty argument' if args.empty?

      arg = args[0]
      case arg
      when Vector
        return generic_take(arg) if arg.numeric?
        return generic_filter(arg.data) if arg.boolean?

        raise DataFrameArgumentError, "Argument by Vector must be numeric or boolean: #{arg}"
      when Arrow::BooleanArray
        return generic_filter(arg)
      end

      # expand Range like [1..3, 4] to [1, 2, 3, 4]
      expanded = expand_range(args)
      return select_vars_by_keys(expanded.map(&:to_sym)) if sym_or_str?(expanded)

      array = Arrow::Array.new(expanded)
      return generic_filter(array) if array.is_a?(Arrow::BooleanArray)

      vector = Vector.new(array)
      return generic_take(vector) if vector.numeric?

      raise DataFrameArgumentError, "Invalid argument: #{args}"
    end

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
      return map_indices(*slicer) if integers?(slicer)

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
      return map_indices(*slicer) if integers?(slicer)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    def remove_nil
      func = Arrow::Function.find(:drop_null)
      DataFrame.new(func.execute([table]).value)
    end
    alias_method :drop_nil, :remove_nil

    # Select a variable by a key in String or Symbol
    def v(key)
      unless key.is_a?(Symbol) || key.is_a?(String)
        raise DataFrameArgumentError, "Key is not a Symbol or String [#{key}]"
      end
      raise DataFrameArgumentError, "Key not exist [#{key}]" unless key?(key)

      variables[key.to_sym]
    end

    def head(n_rows = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_rows}" if n_rows.negative?

      self[0...[n_rows, size].min]
    end

    def tail(n_rows = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_rows}" if n_rows.negative?

      self[-[n_rows, size].min..]
    end

    def first(n_rows = 1)
      head(n_rows)
    end

    def last(n_rows = 1)
      tail(n_rows)
    end

    # TODO: support for option {boundscheck: true}
    def take(*indices)
      indices.flatten!
      return DataFrame.new({}, []) if indices.empty?

      indices = indices[0] if indices.one? && !indices[0].is_a?(Numeric)
      indices = Vector.new(indices) unless indices.is_a?(Vector)

      generic_take(indices) # returns sub DataFrame
    end

    # TODO: support for option {null_selection_behavior: :drop}
    def filter(*booleans)
      booleans.flatten!
      return remove(*0...size) if booleans.empty?

      b = booleans[0]
      boolean_array =
        case b
        when Vector
          raise DataFrameArgumentError, 'Argument is not a boolean.' unless b.boolean?

          b.data
        when Arrow::BooleanArray
          b
        else
          raise DataFrameArgumentError, 'Argument is not a boolean.' unless booleans?(booleans)

          Arrow::BooleanArray.new(booleans)
        end

      generic_filter(boolean_array) # returns sub DataFrame
    end

    private

    def select_vars_by_keys(keys)
      if keys.one?
        key = keys[0].to_sym
        raise DataFrameArgumentError, "Key does not exist #{keys}" unless key? key

        variables[key]
      else
        DataFrame.new(@table[keys])
      end
    end

    # Accepts indices by numeric Vector
    def generic_take(indices)
      raise DataFrameArgumentError, "Indices must be a numeric Vector: #{indices}" unless indices.numeric?
      raise DataFrameArgumentError, "Index out of range: #{indices.min}" if indices.min <= -size - 1

      normalized_indices = (indices < 0).if_else(indices + size, indices) # normalize index from tail
      raise DataFrameArgumentError, "Index out of range: #{normalized_indices.max}" if normalized_indices.max >= size

      index_array = Arrow::UInt64ArrayBuilder.build(normalized_indices.data) # round to integer array

      datum = Arrow::Function.find(:take).execute([table, index_array])
      DataFrame.new(datum.value)
    end

    # Accepts booleans by Arrow::BooleanArray
    def generic_filter(boolean_array)
      raise DataFrameArgumentError, 'Booleans must be same size as self.' unless boolean_array.length == size

      datum = Arrow::Function.find(:filter).execute([table, boolean_array])
      DataFrame.new(datum.value)
    end

    # return a DataFrame with same keys as self without values
    def remove_all_values
      DataFrame.new(keys.each_with_object({}) { |key, h| h[key] = [] })
    end
  end
end
