# frozen_string_literal: true

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameCombinable
    # Concatenate other dataframe at the bottom.
    #
    # @param other [DataFrame, Arrow::Table, Array<DataFrame, Arrow::Table>]
    #   dataframe/table to concatenate onto the bottom of self.
    # @return [DataFrame]
    #   concatenated dataframe.
    def concatenate(*other)
      case other
      in [] | [nil] | [[]]
        return self
      in [Array => array]
        # Nop
      else
        array = other
      end

      table_array = array.map do |e|
        case e
        when Arrow::Table
          e
        when DataFrame
          e.table
        else
          raise DataFrameArgumentError, "#{e} is not a Table or a DataFrame"
        end
      end

      DataFrame.new(table.concatenate(table_array))
    end

    alias_method :concat, :concatenate
  end
end
