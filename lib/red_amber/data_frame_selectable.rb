# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameSelectable
    # Array is refined
    #
    using RefineArray

    # select variables (columns): [symbols] or [strings]
    # select records (rows): [indices], [range]
    def [](*args)
      raise DataFrameArgumentError, 'self is an empty dataframe' if empty?

      case args
      in [] | [nil]
        remove_all_values
      in [*integers] if integers.all?(Integer)
        take(normalize_index(Vector.new(args)))
      in [*symbols] if symbols.all?(Symbol)
        select_vars_by_keys(args)
      else
        array = parse_args(args, size)
        if array.symbols?
          select_vars_by_keys(array)
        else
          vector = Vector.new(array)
          select_records_by_vector(vector, args)
        end
      end
    end

    # slice and select records to create a sub DataFrame
    def slice(*args, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?

      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        args = [instance_eval(&block)]
      end

      case args
      in [] | [[]] | [nil]
        remove_all_values
      in [Vector => v]
        select_records_by_vector(v, args)
      else
        vector = Vector.new(parse_args(args, size))
        select_records_by_vector(vector, args)
      end
    end

    def slice_by(key, keep_key: false, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?
      raise DataFrameArgumentError, 'No block given' unless block
      raise DataFrameArgumentError, "#{key} is not a key of self" unless key?(key)
      return self if key.nil?

      slicer = instance_eval(&block)
      return DataFrame.new unless slicer

      if slicer.is_a?(Range)
        from = slicer.begin
        from =
          if from.is_a?(String)
            self[key].index(from)
          elsif from.nil?
            0
          elsif from < 0
            size + from
          else
            from
          end
        to = slicer.end
        to =
          if to.is_a?(String)
            self[key].index(to)
          elsif to.nil?
            size - 1
          elsif to < 0
            size + to
          else
            to
          end
        slicer = (from..to).to_a
      else
        slicer = slicer.map { |x| x.is_a?(String) ? self[key].index(x) : x }
      end

      taken = take(normalize_index(Vector.new(slicer)))
      keep_key ? taken : taken.drop(key)
    end

    # remove selected records to create a remainer DataFrame
    def remove(*args, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?

      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        args = [instance_eval(&block)]
      end

      vector =
        case args
        in [] | [[]] | [nil]
          return self
        in [Vector => v]
          v
        else
          Vector.new(parse_args(args, size))
        end

      if vector.boolean?
        raise DataFrameArgumentError, "Size is not match in booleans: #{args}" unless vector.size == size

        filter_by_array(vector.primitive_invert.data)
      elsif vector.numeric?
        remover = normalize_index(vector).to_a
        return self if remover.empty?

        slicer = indices.to_a - remover
        return remove_all_values if slicer.empty?

        take(slicer)
      else
        raise DataFrameArgumentError, "Invalid argument #{args}"
      end
    end

    def remove_nil
      func = Arrow::Function.find(:drop_null)
      DataFrame.create(func.execute([table]).value)
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
    #  TODO: support for option `boundscheck: true`
    #  Supports indices in an Arrow::UInt{8, 16, 32, 64} or an Array
    #  Negative index is not supported.
    def take(index_array)
      datum = Arrow::Function.find(:take).execute([table, index_array])
      DataFrame.create(datum.value)
    end

    # Undocumented
    #   TODO: support for option `null_selection_behavior: :drop``
    def filter(*booleans)
      booleans.flatten!
      return remove_all_values if booleans.empty?

      b = booleans[0]
      case b
      when Vector
        raise DataFrameArgumentError, 'Argument is not a boolean.' unless b.boolean?

        filter_by_array(b.data)
      when Arrow::BooleanArray
        filter_by_array(b)
      else
        raise DataFrameArgumentError, 'Argument is not a boolean.' unless booleans.booleans?

        filter_by_array(Arrow::BooleanArray.new(booleans))
      end
    end

    private

    def select_vars_by_keys(keys)
      if keys.one?
        key = keys[0].to_sym
        raise DataFrameArgumentError, "Key does not exist: #{key}" unless key? key

        variables[key]
        # Vector.new(@table.find_column(*key).data)
      else
        check_duplicate_keys(keys)
        DataFrame.create(@table.select_columns(*keys))
      end
    end

    def select_records_by_vector(vector, org_args)
      if vector.boolean?
        raise DataFrameArgumentError, "Size is not match in booleans: #{org_args}" unless vector.size == size

        filter_by_array(vector.data)
      elsif vector.numeric?
        take(normalize_index(vector))
      elsif vector.to_a.compact.empty?
        remove_all_values
      else
        raise DataFrameArgumentError, "Invalid argument #{org_args}"
      end
    end

    # Accepts indices by numeric Vector and returns normalized indices.
    def normalize_index(vector)
      vector = (vector < 0).if_else(vector + size, vector) if (vector < 0).any?

      min, max = vector.min_max
      raise DataFrameArgumentError, "Index out of range: #{min}" if min < 0
      raise DataFrameArgumentError, "Index out of range: #{max}" if max >= size

      if vector.float?
        Arrow::UInt64ArrayBuilder.build(vector.data)
      else
        vector.data
      end
    end

    # Accepts booleans by a Arrow::BooleanArray or an Array
    def filter_by_array(boolean_array)
      raise DataFrameArgumentError, 'Booleans must be same size as self.' unless boolean_array.length == size

      datum = Arrow::Function.find(:filter).execute([table, boolean_array])
      DataFrame.create(datum.value)
    end

    # return a DataFrame with same keys as self without values
    def remove_all_values
      filter_by_array(Arrow::BooleanArray.new([false] * size))
    end
  end
end
