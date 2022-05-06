# frozen_string_literal: true

require 'stringio'

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameOutput
    def to_s
      @table.to_s
    end

    # def describe() end

    # def summary() end

    def inspect_raw
      format "#<#{self.class}:0x%016x>\n#{self}", object_id
    end

    # - tally_level: max level to use tally mode
    # - max_element: max element to show values in each row
    # TODO: Is it better to change name other than `inspect` ?
    # TODO: Add na count capability
    # TODO: Fall back to inspect_raw when treating large dataset
    # TODO: Refactor code to smaller methods
    def inspect(tally_level: 5, max_element: 5)
      return '#<RedAmber::DataFrame (empty)>' if empty?

      stringio = StringIO.new # output string buffer

      # 1st row: show shape of the dataframe
      r = pl(nrow)
      c = pl(ncol)
      stringio.puts \
        "#{self.class} : #{nrow} observation#{r}(row#{r}) of #{ncol} variable#{c}(column#{c})"

      # 2nd row: show var counts by type
      type_groups = data_types.map { |t| type_group(t) }

      stringio.puts "Variable#{pl(ncol)} : #{var_type_count(type_groups).join(', ')}"

      # 3rd row: print header of rows
      levels = vectors.map { |v| v.to_a.uniq.size }
      row_headers = { idx: '#', key: 'key', type: 'type', levels: 'level', data: 'data_preview' }
      # find longest word to adjust column width
      w_idx = ncol.to_s.size
      w_key = (keys.map { |key| key.size + 1 } << row_headers[:key].size).max
      w_type = (types.map(&:size) << row_headers[:type].size).max
      w_row = (levels.map { |l| l.to_s.size } << row_headers[:levels].size).max
      stringio.printf("%-#{w_idx}s %-#{w_key}s %-#{w_type}s %-#{w_row}s %s\n", *row_headers.values)

      # (4) show details for each column (vector)
      vectors.each.with_index(1) do |vector, i|
        key = keys[i - 1]
        type = types[i - 1]
        type_group = type_groups[i - 1]
        data_tally = vector.tally

        str = format("%#{w_row}d ", data_tally.size)
        str <<
          case type_group
          when :numeric, :string, :boolean
            if data_tally.size <= tally_level && data_tally.size != nrow
              data_tally.to_s
            else
              reduced_vector_presentation(vector, nrow, max_element)
            end
            #  c = vector.is_na.tally[1]   # release when `#is_na` impremented
            #  str << " #{c} NaN#{pl(c)}" if c&.>(0)  # safely call c>0
          else
            reduced_vector_presentation(vector, nrow, max_element)
          end

        stringio.printf("%#{w_idx}d %-#{w_key}s %-#{w_type}s %s\n", i, ":#{key}", type, str)
      end

      stringio.string
    end

    private # =====

    def pl(num)
      num > 1 ? 's' : ''
    end

    def type_group(type)
      if Arrow::NumericDataType >= type
        :numeric
      elsif Arrow::StringDataType >= type
        :string
      elsif Arrow::BooleanDataType >= type
        :boolean
      elsif Arrow::TemporalDataType >= type
        :temporal
      else
        :other
      end
    end

    def var_type_count(type_groups)
      tg = type_groups.tally
      a = []
      a << "#{tg[:numeric]} numeric" if tg[:numeric]
      a << "#{tg[:string]} string#{pl(tg[:string])}" if tg[:string]
      a << "#{tg[:boolean]} boolean" if tg[:boolean]
      a << "#{tg[:temporal]} temporal" if tg[:temporal]
      a
    end

    def reduced_vector_presentation(vector, nrow, max_element)
      a = vector.to_a.take(max_element)
      a << '...' if nrow > max_element
      "[#{a.join(', ')}]"
    end
  end
end
