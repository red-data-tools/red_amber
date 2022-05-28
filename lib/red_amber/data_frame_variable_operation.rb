# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameVariableOperation
    # pick up some variables to create sub DataFrame
    def pick(*args, &block)
      picker = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        picker = instance_eval(&block)
      end
      picker = [picker].flatten
      return DataFrame.new if picker.empty? || picker == [nil]

      picker = keys_by_booleans(picker) if booleans?(picker)

      # DataFrame#[] creates a Vector with single key is specified.
      # DataFrame#pick creates a DataFrame with single key.
      return DataFrame.new(@table[picker]) if sym_or_str?(picker)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    # drop some variables to create remainer sub DataFrame
    def drop(*args, &block)
      dropper = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and block.' unless args.empty?

        dropper = instance_eval(&block)
      end
      dropper = [dropper].flatten
      dropper = keys_by_booleans(dropper) if booleans?(dropper)

      picker = keys - dropper
      return DataFrame.new if picker.empty?

      # DataFrame#[] creates a Vector with single key is specified.
      # DataFrame#drop creates a DataFrame with single key.
      return DataFrame.new(@table[picker]) if sym_or_str?(picker)

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    # rename variables to create new DataFrame
    def rename(*args, &block)
      renamer = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and a block' unless args.empty?

        renamer = instance_eval(&block)
      end
      renamer = [renamer].flatten
      return self if renamer.empty?

      return rename_by_hash([renamer].to_h) if renamer.size == 2 && sym_or_str?(renamer) # rename(from, to)
      return rename_by_hash(renamer[0]) if renamer.one? && renamer[0].is_a?(Hash) # rename({from => to})

      raise DataFrameArgumentError, "Invalid argument #{args}"
    end

    # assign variables to create new DataFrame
    def assign(*args, &block)
      assigner = args
      if block
        raise DataFrameArgumentError, 'Must not specify both arguments and a block' unless args.empty?

        assigner = instance_eval(&block)
      end
      assigner = [assigner].flatten
      return self if assigner.empty? || assigner == [nil]

      raise DataFrameArgumentError, "Invalid argument #{args}" unless assigner.one? && assigner[0].is_a?(Hash)

      updater = {}
      appender = {}
      assigner[0].each do |key, value|
        if keys.include? key
          updater[key] = value
        else
          appender[key] = value
        end
      end
      fields, arrays = update_fields_and_arrays(updater)
      append_to_fields_and_arrays(appender, fields, arrays) unless appender.empty?

      DataFrame.new(Arrow::Table.new(Arrow::Schema.new(fields), arrays))
    end

    private

    def rename_by_hash(key_pairs)
      fields = keys.map do |key|
        new_key = key_pairs[key]
        if new_key
          Arrow::Field.new(new_key.to_sym, @table[key].data_type)
        else
          @table.schema[key]
        end
      end
      schema = Arrow::Schema.new(fields)
      DataFrame.new(Arrow::Table.new(schema, @table.columns))
    end

    def update_fields_and_arrays(updater)
      fields = @table.columns.map(&:field)
      arrays = @table.columns.map(&:data) # chunked_arrays
      keys.each_with_index do |key, i|
        data = updater[key]
        next unless data

        raise DataFrameArgumentError, "Data size mismatch (#{data.size} != #{size})" if data.size != size

        a = Arrow::Array.new(data.is_a?(Vector) ? data.to_a : data)
        fields[i] = Arrow::Field.new(key, a.value_data_type)
        arrays[i] = Arrow::ChunkedArray.new([a])
      end
      [fields, arrays]
    end

    def append_to_fields_and_arrays(appender, fields, arrays)
      appender.each do |key, data|
        raise DataFrameArgumentError, "Data size mismatch (#{data.size} != #{size})" if data.size != size

        a = Arrow::Array.new(data.is_a?(Vector) ? data.to_a : data)
        fields << Arrow::Field.new(key.to_sym, a.value_data_type)
        arrays << Arrow::ChunkedArray.new([a])
      end
    end
  end
end
