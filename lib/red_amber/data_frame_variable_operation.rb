# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameVariableOperation
    # Array is refined
    using RefineArray

    # Select variables (columns) to create a new DataFrame.
    #
    # @note if a single key is specified, DataFrame#pick generates a DataFrame.
    #   On the other hand, DataFrame#[] generates a Vector.
    #
    # @overload pick(keys)
    #   Pick up variables by Symbol(s) or String(s).
    #
    #   @param keys [Symbol, String, <Symbol, String>]
    #     key name(s) of variables to pick.
    #   @return [DataFrame]
    #     Picked DataFrame.
    #   @example Pick up by a key
    #     languages
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 3 Vectors, 0x00000000000cfd8c>
    #       Language Creator                         Released
    #       <string> <string>                        <uint16>
    #     0 Ruby     Yukihiro Matsumoto                  1995
    #     1 Python   Guido van Rossum                    1991
    #     2 R        Ross Ihaka and Robert Gentleman     1993
    #     3 Rust     Graydon Hoare                       2001
    #
    #     languages.pick(:Language)
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 1 Vector, 0x0000000000113d20>
    #       Language
    #       <string>
    #     0 Ruby
    #     1 Python
    #     2 R
    #     3 Rust
    #
    #     languages[:Language]
    #     # =>
    #     #<RedAmber::Vector(:string, size=4):0x000000000010359c>
    #     ["Ruby", "Python", "R", "Rust"]
    #
    # @overload pick(booleans)
    #   Pick up variables by booleans.
    #
    #   @param booleans [<Booleans, nil>, Vector]
    #     boolean array or vecctor to pick up variables at true.
    #   @return [DataFrame]
    #     Picked DataFrame.
    #   @example Pick up by booleans
    #     languages.pick(true, true, false)
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 2 Vectors, 0x0000000000066a1c>
    #     Language Creator
    #     <string> <string>
    #     0 Ruby     Yukihiro Matsumoto
    #     1 Python   Guido van Rossum
    #     2 R        Ross Ihaka and Robert Gentleman
    #     3 Rust     Graydon Hoare
    #
    #     is_string = languages.vectors.map(&:string?) # [true, true, false]
    #     languages.pick(is_string)
    #     # =>
    #     (same as above)
    #
    # @overload pick(indices)
    #   Pick up variables by column indices.
    #
    #   @param indices [Integer, Float, Range<Integer>, Vector, Arrow::Array]
    #     numeric array to pick up variables by column index.
    #   @return [DataFrame]
    #     Picked DataFrame.
    #   @example Pick up by indices
    #     languages.pick(0, 2, 1)
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 3 Vectors, 0x000000000011cfb0>
    #       Language Released Creator
    #       <string> <uint16> <string>
    #     0 Ruby         1995 Yukihiro Matsumoto
    #     1 Python       1991 Guido van Rossum
    #     2 R            1993 Ross Ihaka and Robert Gentleman
    #     3 Rust         2001 Graydon Hoare
    #
    # @overload pick
    #   Pick up variables by the yielded value from the block.
    #   @note Arguments and a block cannot be used simultaneously.
    #
    #   @yield [self] the block is called within the context of self.
    #     (Block is called by instance_eval(&block). )
    #   @yieldreturn [keys, booleans, indices]
    #     returns keys, booleans or indices just same as arguments.
    #   @return [DataFrame]
    #     Picked DataFrame.
    #   @example Pick up by a block.
    #     # same as languages.pick { |df| df.languages.vectors.map(&:string?) }
    #     languages.pick { languages.vectors.map(&:string?) }
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 2 Vectors, 0x0000000000154104>
    #       Language Creator
    #       <string> <string>
    #     0 Ruby     Yukihiro Matsumoto
    #     1 Python   Guido van Rossum
    #     2 R        Ross Ihaka and Robert Gentleman
    #     3 Rust     Graydon Hoare
    #
    def pick(*args, &block)
      if block
        unless args.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and block.'
        end

        args = [instance_eval(&block)]
      end

      case args
      in [] | [nil]
        return DataFrame.new
      in [*] if args.symbols?
        return DataFrame.create(@table.select_columns(*args))
      in [*] if args.booleans?
        picker = keys.select_by_booleans(args)
        return DataFrame.create(@table.select_columns(*picker))
      in [(Vector | Arrow::Array | Arrow::ChunkedArray) => a]
        picker = a.to_a
      else
        picker = parse_args(args, n_keys)
      end

      return DataFrame.new if picker.compact.empty?

      if picker.booleans?
        picker = keys.select_by_booleans(picker)
        return DataFrame.create(@table.select_columns(*picker))
      end
      picker.compact!
      raise DataFrameArgumentError, "some keys are duplicated: #{args}" if picker.uniq!

      DataFrame.create(@table.select_columns(*picker))
    end

    # Drop off some variables (columns) to create a remainer DataFrame.
    #
    # @note DataFrame#drop creates a DataFrame even if it is a single column
    #   (not a Vector).
    #
    # @overload drop(keys)
    #   Drop off variables by Symbol(s) or String(s).
    #
    #   @param keys [Symbol, String, <Symbol, String>]
    #     key name(s) of variables to drop.
    #   @return [DataFrame]
    #     Remainer DataFrame.
    #   @example Drop off by a key
    #     languages
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 3 Vectors, 0x00000000000cfd8c>
    #       Language Creator                         Released
    #       <string> <string>                        <uint16>
    #     0 Ruby     Yukihiro Matsumoto                  1995
    #     1 Python   Guido van Rossum                    1991
    #     2 R        Ross Ihaka and Robert Gentleman     1993
    #     3 Rust     Graydon Hoare                       2001
    #
    #     languages.drop(:Language)
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 2 Vectors, 0x000000000005805c>
    #       Creator                         Released
    #       <string>                        <uint16>
    #     0 Yukihiro Matsumoto                  1995
    #     1 Guido van Rossum                    1991
    #     2 Ross Ihaka and Robert Gentleman     1993
    #     3 Graydon Hoare                       2001
    #
    # @overload drop(booleans)
    #   Drop off variables by booleans.
    #
    #   @param booleans [<Booleans, nil>, Vector]
    #     boolean array or vector of variables to drop at true.
    #   @return [DataFrame]
    #     Remainer DataFrame.
    #   @example Drop off by booleans
    #     is_numeric = languages.vectors.map(&:numeric?) # [nil, nil, true]
    #     languages.drop(is_numeric)
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 2 Vectors, 0x0000000000066a1c>
    #     Language Creator
    #     <string> <string>
    #     0 Ruby     Yukihiro Matsumoto
    #     1 Python   Guido van Rossum
    #     2 R        Ross Ihaka and Robert Gentleman
    #     3 Rust     Graydon Hoare
    #
    # @overload drop(indices)
    #   Drop off variables by column indices.
    #
    #   @param indices [Integer, Float, Range<Integer>, Vector, Arrow::Array]
    #     numeric array of variables to drop by column index.
    #   @return [DataFrame]
    #     Remainer DataFrame.
    #   @example Drop off by indices
    #     languages.drop(2)
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 2 Vectors, 0x0000000000066a1c>
    #     Language Creator
    #     <string> <string>
    #     0 Ruby     Yukihiro Matsumoto
    #     1 Python   Guido van Rossum
    #     2 R        Ross Ihaka and Robert Gentleman
    #     3 Rust     Graydon Hoare
    #
    # @overload drop
    #   Drop off variables by the yielded value from the block.
    #   @note Arguments and a block cannot be used simultaneously.
    #
    #   @yield [self] the block is called within the context of self.
    #     (Block is called by instance_eval(&block). )
    #   @yieldreturn [keys, booleans, indices]
    #     returns keys, booleans or indices just same as arguments.
    #   @return [DataFrame]
    #     Remainer DataFrame.
    #   @example Drop off by a block.
    #     # same as languages.drop { |df| df.vectors.map(&:numeric?) }
    #     languages.drop { vectors.map(&:numeric?) }
    #     # =>
    #     #<RedAmber::DataFrame : 4 x 2 Vectors, 0x0000000000154104>
    #       Language Creator
    #       <string> <string>
    #     0 Ruby     Yukihiro Matsumoto
    #     1 Python   Guido van Rossum
    #     2 R        Ross Ihaka and Robert Gentleman
    #     3 Rust     Graydon Hoare
    #
    def drop(*args, &block)
      if block
        unless args.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and block.'
        end

        args = [instance_eval(&block)]
      end
      return self if args.empty? || empty?

      picker =
        if args.symbols?
          keys - args
        elsif args.booleans?
          keys.reject_by_booleans(args)
        elsif args.integers?
          keys.reject_by_indices(args)
        else
          dropper = parse_args(args, n_keys)
          if dropper.booleans?
            keys.reject_by_booleans(dropper)
          elsif dropper.symbols?
            keys - dropper
          else
            dropper.compact!
            unless dropper.integers?
              raise DataFrameArgumentError, "Invalid argument #{args}"
            end

            keys.reject_by_indices(dropper)
          end
        end

      return DataFrame.new if picker.empty?

      DataFrame.create(@table.select_columns(*picker))
    end

    # rename variables to create a new DataFrame
    def rename(*renamer, &block)
      if block
        unless renamer.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and a block'
        end

        renamer = [instance_eval(&block)]
      end
      case renamer
      in [] | [nil] | [{}] | [[]]
        return self
      in [Hash => key_pairs]
      # noop
      in [ (Symbol | String) => from, (Symbol | String) => to]
        key_pairs = { from => to }
      in [Array => array_in_array]
        key_pairs = try_convert_to_hash(array_in_array)
      in [Array, *] => array_in_array1
        key_pairs = try_convert_to_hash(array_in_array1)
      else
        raise DataFrameArgumentError, "Invalid argument #{renamer}"
      end
      rename_by_hash(key_pairs)
    end

    # assign variables to create a new DataFrame
    def assign(*assigner, &block)
      assign_update(*assigner, append_to_left: false, &block)
    end

    def assign_left(*assigner, &block)
      assign_update(*assigner, append_to_left: true, &block)
    end

    private

    def assign_update(*assigner, append_to_left: false, &block)
      if block
        assigner_from_block = instance_eval(&block)
        assigner =
          case assigner_from_block
          in _ if assigner.empty? # block only
            [assigner_from_block]
          in [Vector, *] | [Array, *] | [Arrow::Array, *]
            assigner.zip(assigner_from_block)
          else
            assigner.zip([assigner_from_block])
          end
      end

      case assigner
      in [] | [nil] | [{}] | [[]]
        return self
      in [(Symbol | String) => key, (Vector | Array | Arrow::Array) => array]
        key_array_pairs = { key => array }
      in [Hash => key_array_pairs]
      # noop
      in [Array => array_in_array]
        key_array_pairs = try_convert_to_hash(array_in_array)
      in [Array, *] => array_in_array1
        key_array_pairs = try_convert_to_hash(array_in_array1)
      else
        raise DataFrameArgumentError, "Invalid argument #{assigner}"
      end

      updater = {}
      appender = {}
      key_array_pairs.each do |key, array|
        raise DataFrameArgumentError, "Empty column data: #{key} => nil" if array.nil?

        if keys.include? key
          updater[key] = array
        else
          appender[key] = array
        end
      end
      fields, arrays = *update_fields_and_arrays(updater)
      return self if appender.is_a?(DataFrame)

      unless appender.empty?
        append_to_fields_and_arrays(appender, fields, arrays, append_to_left)
      end

      DataFrame.create(Arrow::Table.new(Arrow::Schema.new(fields), arrays))
    end

    def try_convert_to_hash(array)
      array.to_h
    rescue TypeError
      [array].to_h
    end

    def rename_by_hash(key_pairs)
      not_existing_keys = key_pairs.keys - keys
      unless not_existing_keys.empty?
        raise DataFrameArgumentError, "Not existing: #{not_existing_keys}"
      end

      fields =
        keys.map do |key|
          new_key = key_pairs[key]
          if new_key
            Arrow::Field.new(new_key.to_sym, @table[key].data_type)
          else
            @table.schema[key]
          end
        end
      DataFrame.create(Arrow::Table.new(Arrow::Schema.new(fields), @table.columns))
    end

    def update_fields_and_arrays(updater)
      fields = @table.columns.map(&:field)
      arrays = @table.columns.map(&:data) # chunked_arrays
      keys.each_with_index do |key, i|
        data = updater[key]
        next unless data

        if data.size != size
          raise DataFrameArgumentError, "Data size mismatch (#{data.size} != #{size})"
        end

        a = Arrow::Array.new(data.is_a?(Vector) ? data.to_a : data)
        fields[i] = Arrow::Field.new(key, a.value_data_type)
        arrays[i] = Arrow::ChunkedArray.new([a])
      end
      [fields, arrays]
    end

    def append_to_fields_and_arrays(appender, fields, arrays, append_to_left)
      enum = append_to_left ? appender.reverse_each : appender.each
      enum.each do |key, data|
        if data.size != size
          raise DataFrameArgumentError, "Data size mismatch (#{data.size} != #{size})"
        end

        a = Arrow::Array.new(data.is_a?(Vector) ? data.to_a : data)

        if append_to_left
          fields.unshift(Arrow::Field.new(key.to_sym, a.value_data_type))
          arrays.unshift(Arrow::ChunkedArray.new([a]))
        else
          fields << Arrow::Field.new(key.to_sym, a.value_data_type)
          arrays << Arrow::ChunkedArray.new([a])
        end
      end
    end
  end
end
