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

    private

    def rename_by_hash(key_pairs)
      schema_array = keys.map do |key|
        new_key = key_pairs[key]
        if new_key
          Arrow::Field.new(new_key.to_sym, @table[key].data_type)
        else
          @table.schema[key]
        end
      end
      schema = Arrow::Schema.new(schema_array)
      DataFrame.new(Arrow::Table.new(schema, @table.columns))
    end
  end
end
