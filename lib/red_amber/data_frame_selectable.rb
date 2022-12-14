# frozen_string_literal: true

module RedAmber
  # mix-in for the class DataFrame
  module DataFrameSelectable
    # Array, Arrow::Array and Arrow::ChunkedArray are refined
    using RefineArray
    using RefineArrayLike

    # Select variables or records.
    #
    # @overload [](key)
    #   select single variable and return as a Vetor.
    #
    #   @param key [Symbol, String] key name to select.
    #   @return [Vector] selected variable as a Vector.
    #   @note DataFrame.v(key) is faster to create Vector from a variable.
    #
    # @overload [](keys)
    #   select variables and return a DataFrame.
    #
    #   @param keys [<Symbol, String>] key names to select.
    #   @return [DataFrame] selected variables as a DataFrame.
    #
    # @overload [](index)
    #   select records and return a DataFrame.
    #
    #   @param index [Indeger, Float, Range<Integer>, Vector, Arrow::Array]
    #     index of a row to select.
    #   @return [DataFrame] selected variables as a DataFrame.
    #
    # @overload [](indices)
    #   select records and return a DataFrame.
    #
    #   @param indices [<Indeger, Float, Range<Integer>, Vector, Arrow::Array>]
    #     indices of rows to select.
    #   @return [DataFrame] selected variables as a DataFrame.
    #
    def [](*args)
      raise DataFrameArgumentError, 'self is an empty dataframe' if empty?

      case args
      in [] | [nil]
        return remove_all_values
      in [(Symbol | String) => k] if key? k
        return variables[k.to_sym]
      in [Integer => i]
        return take([i.negative? ? i + size : i])
      in [Vector => v]
        arrow_array = v.data
      in [(Arrow::Array | Arrow::ChunkedArray) => aa]
        arrow_array = aa
      else
        a = parse_args(args, size)
        return select_variables_by_keys(a) if a.symbols?
        return take(normalize_indices(Arrow::Array.new(a))) if a.integers?
        return remove_all_values if a.compact.empty?
        return filter_by_array(Arrow::BooleanArray.new(a)) if a.booleans?

        raise DataFrameArgumentError, "invalid arguments: #{args}"
      end

      return take(normalize_indices(arrow_array)) if arrow_array.numeric?
      return filter_by_array(arrow_array) if arrow_array.boolean?

      a = arrow_array.to_a
      return select_variables_by_keys(a) if a.symbols_or_strings?

      raise DataFrameArgumentError, "invalid arguments: #{args}"
    end

    # Select a variable by a key in String or Symbol
    def v(key)
      unless key.is_a?(Symbol) || key.is_a?(String)
        raise DataFrameArgumentError, "Key is not a Symbol or a String: [#{key}]"
      end
      raise DataFrameArgumentError, "Key does not exist: [#{key}]" unless key? key

      variables[key.to_sym]
    end

    # Select records to create a DataFrame.
    #
    # @overload slice(row)
    #   select a record and return a DataFrame.
    #
    #   @param row [Indeger, Float, Range<Integer>, Vector, Arrow::Array]
    #     a row index to select.
    #   @yield [self] gives self to the block.
    #     @note The block is evaluated within the context of self.
    #       It is accessable to self's instance variables and private methods.
    #   @yieldreturn [Indeger, Float, Range<Integer>, Vector, Arrow::Array]
    #     a row index to select.
    #   @return [DataFrame] selected variables as a DataFrame.
    #
    # @overload slice(rows)
    #   select records and return a DataFrame.
    #   - Duplicated selection is acceptable. The same record will be returned.
    #   - The order of records will be the same as specified indices.
    #
    #   @param rows [Integer, Float, Range<Integer>, Vector, Arrow::Array]
    #     row indeces to select.
    #   @yield [self] gives self to the block.
    #     @note The block is evaluated within the context of self.
    #       It is accessable to self's instance variables and private methods.
    #   @yieldreturn [<Integer, Float, Range<Integer>, Vector, Arrow::Array>]
    #     row indeces to select.
    #   @return [DataFrame] selected variables as a DataFrame.
    #
    def slice(*args, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?

      if block
        unless args.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and block.'
        end

        args = [instance_eval(&block)]
      end

      arrow_array =
        case args
        in [] | [[]]
          return remove_all_values
        in [Vector => v]
          v.data
        in [(Arrow::Array | Arrow::ChunkedArray) => aa]
          aa
        else
          Arrow::Array.new(parse_args(args, size))
        end

      if arrow_array.numeric?
        take(normalize_indices(arrow_array))
      elsif arrow_array.boolean?
        filter_by_array(arrow_array)
      elsif arrow_array.to_a.compact.empty?
        # Ruby 3.0.4 does not accept Arrow::Array#compact here. 2.7.6 and 3.1.2 is OK.
        remove_all_values
      else
        raise DataFrameArgumentError, "invalid arguments: #{args}"
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

      taken = take(normalize_indices(Arrow::Array.new(slicer)))
      keep_key ? taken : taken.drop(key)
    end

    # Select records and remove them to create a remainer DataFrame.
    #
    # @overload remove(row)
    #   select a record and remove it to create a remainer DataFrame.
    #   - The order of records in self will be preserved.
    #
    #   @param row [Indeger, Float, Range<Integer>, Vector, Arrow::Array]
    #     a row index to remove.
    #   @yield [self] gives self to the block.
    #     @note The block is evaluated within the context of self.
    #       It is accessable to self's instance variables and private methods.
    #   @yieldreturn [Indeger, Float, Range<Integer>, Vector, Arrow::Array]
    #     a row index to remove.
    #   @return [DataFrame] remainer variables as a DataFrame.
    #
    # @overload remove(rows)
    #   select records and remove them to create a remainer DataFrame.
    #   - The order of records in self will be preserved.
    #
    #   @param rows [Indeger, Float, Range<Integer>, Vector, Arrow::Array]
    #     row indeces to remove.
    #   @yield [self] gives self to the block.
    #     @note The block is evaluated within the context of self.
    #       It is accessable to self's instance variables and private methods.
    #   @yieldreturn [<Indeger, Float, Range<Integer>, Vector, Arrow::Array>]
    #     row indeces to remove.
    #   @return [DataFrame] remainer variables as a DataFrame.
    #
    def remove(*args, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?

      if block
        unless args.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and block.'
        end

        args = [instance_eval(&block)]
      end

      arrow_array =
        case args
        in [] | [[]] | [nil]
          return self
        in [Vector => v]
          v.data
        in [(Arrow::Array | Arrow::ChunkedArray) => aa]
          aa
        else
          Arrow::Array.new(parse_args(args, size))
        end

      if arrow_array.boolean?
        filter_by_array(arrow_array.primitive_invert)
      elsif arrow_array.numeric?
        remover = normalize_indices(arrow_array).to_a
        return self if remover.empty?

        slicer = indices.to_a - remover.map(&:to_i)
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

    # @api private
    #  TODO: support for option `boundscheck: true`
    #  Supports indices in an Arrow::UInt{8, 16, 32, 64} or an Array
    #  Negative index is not supported.
    def take(index_array)
      DataFrame.create(@table.take(index_array))
    end

    # @api private
    #   TODO: support for option `null_selection_behavior: :drop``
    def filter(*booleans)
      booleans.flatten!
      case booleans
      in []
        return remove_all_values
      in [Arrow::BooleanArray => b]
        filter_by_array(b)
      else
        unless booleans.booleans?
          raise DataFrameArgumentError, 'Argument is not a boolean.'
        end

        filter_by_array(Arrow::BooleanArray.new(booleans))
      end
    end

    private

    def select_variables_by_keys(keys)
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

    # Accepts indices by numeric arrow array and returns positive indices.
    def normalize_indices(arrow_array)
      b = Arrow::Function.find(:less).execute([arrow_array, 0])
      a = Arrow::Function.find(:add).execute([arrow_array, size])
      r = Arrow::Function.find(:if_else).execute([b, a, arrow_array]).value
      if r.float?
        r = Arrow::Function.find(:floor).execute([r]).value
        Arrow::UInt64ArrayBuilder.build(r)
      else
        r
      end
    end

    # Accepts booleans by a Arrow::BooleanArray or an Array
    def filter_by_array(boolean_array)
      unless boolean_array.length == size
        raise DataFrameArgumentError, 'Booleans must be same size as self.'
      end

      datum = Arrow::Function.find(:filter).execute([table, boolean_array])
      DataFrame.create(datum.value)
    end

    # return a DataFrame with same keys as self without values
    def remove_all_values
      filter_by_array(Arrow::BooleanArray.new([false] * size))
    end
  end
end
