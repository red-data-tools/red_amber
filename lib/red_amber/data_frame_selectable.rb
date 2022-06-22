# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameSelectable
    # select variables: [symbol] or [string]
    # select observations: [array of index], [range]
    def [](*args)
      args.flatten!
      raise DataFrameArgumentError, 'Empty dataframe' if empty?
      return remove_all_values if args.empty? || args[0].nil?

      vector = parse_to_vector(args)
      if vector.boolean?
        return filter_by_vector(vector.data) if vector.size == size

        raise DataFrameArgumentError, "Size is not match in booleans: #{args}"
      end
      return take_by_array(vector) if vector.numeric?
      return select_vars_by_keys(vector.to_a.map(&:to_sym)) if vector.string? || vector.type == :dictionary

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

      raise DataFrameArgumentError, 'Empty dataframe' if empty?
      return remove_all_values if slicer.empty? || slicer[0].nil?

      vector = parse_to_vector(slicer)
      if vector.boolean?
        return filter_by_vector(vector.data) if vector.size == size

        raise DataFrameArgumentError, "Size is not match in booleans: #{slicer}"
      end
      return take_by_array(vector) if vector.numeric?

      raise DataFrameArgumentError, "Invalid argument #{slicer}"
    end

    # remove selected observations to create sub DataFrame
    def remove(*args, &block)
      remover = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        remover = instance_eval(&block)
      end
      remover = [remover].flatten

      raise DataFrameArgumentError, 'Empty dataframe' if empty?
      return self if remover.empty? || remover[0].nil?

      vector = parse_to_vector(remover)
      if vector.boolean?
        return filter_by_vector(vector.primitive_invert.data) if vector.size == size

        raise DataFrameArgumentError, "Size is not match in booleans: #{remover}"
      end
      if vector.numeric?
        raise DataFrameArgumentError, "Index out of range: #{vector.min}" if vector.min <= -size - 1

        normalized_indices = (vector < 0).if_else(vector + size, vector) # normalize index from tail
        if normalized_indices.max >= size
          raise DataFrameArgumentError, "Index out of range: #{normalized_indices.max}"
        end

        normalized_indices = normalized_indices.floor.to_a.map(&:to_i) # round to integer array
        return remove_all_values if normalized_indices == indices
        return self if normalized_indices.empty?

        index_array = indices - normalized_indices

        datum = Arrow::Function.find(:take).execute([table, index_array])
        return DataFrame.new(datum.value)
      end

      raise DataFrameArgumentError, "Invalid argument #{remover}"
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

    def head(n_obs = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_obs}" if n_obs.negative?

      self[0...[n_obs, size].min]
    end

    def tail(n_obs = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_obs}" if n_obs.negative?

      self[-[n_obs, size].min..]
    end

    def first(n_obs = 1)
      head(n_obs)
    end

    def last(n_obs = 1)
      tail(n_obs)
    end

    # Undocumented
    # TODO: support for option {boundscheck: true}
    def take(*indices)
      indices.flatten!
      return remove_all_values if indices.empty?

      indices = indices[0] if indices.one? && !indices[0].is_a?(Numeric)
      indices = Vector.new(indices) unless indices.is_a?(Vector)

      take_by_array(indices)
    end

    # Undocumented
    # TODO: support for option {null_selection_behavior: :drop}
    def filter(*booleans)
      booleans.flatten!
      return remove_all_values if booleans.empty?

      b = booleans[0]
      case b
      when Vector
        raise DataFrameArgumentError, 'Argument is not a boolean.' unless b.boolean?

        filter_by_vector(b.data)
      when Arrow::BooleanArray
        filter_by_vector(b)
      else
        raise DataFrameArgumentError, 'Argument is not a boolean.' unless booleans?(booleans)

        filter_by_vector(Arrow::BooleanArray.new(booleans))
      end
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
    def take_by_array(indices)
      raise DataFrameArgumentError, "Indices must be a numeric Vector: #{indices}" unless indices.numeric?
      raise DataFrameArgumentError, "Index out of range: #{indices.min}" if indices.min <= -size - 1

      normalized_indices = (indices < 0).if_else(indices + size, indices) # normalize index from tail
      raise DataFrameArgumentError, "Index out of range: #{normalized_indices.max}" if normalized_indices.max >= size

      index_array = Arrow::UInt64ArrayBuilder.build(normalized_indices.data) # round to integer array

      datum = Arrow::Function.find(:take).execute([table, index_array])
      DataFrame.new(datum.value)
    end

    # Accepts booleans by Arrow::BooleanArray
    def filter_by_vector(boolean_array)
      raise DataFrameArgumentError, 'Booleans must be same size as self.' unless boolean_array.length == size

      datum = Arrow::Function.find(:filter).execute([table, boolean_array])
      DataFrame.new(datum.value)
    end

    # return a DataFrame with same keys as self without values
    def remove_all_values
      filter_by_vector(Arrow::BooleanArray.new([false] * size))
    end
  end
end
