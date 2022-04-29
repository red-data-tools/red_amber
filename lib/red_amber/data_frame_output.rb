# frozen_string_literal: true

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
    def inspect(tally_level: 5, max_element: 5)
      return '#<RedAmber::DataFrame (empty)>' if empty?

      require 'stringio'
      stringio = StringIO.new # output string buffer

      pl = ->(x) { x > 1 ? 's' : '' } # treat plural better

      # (1) show shape of the dataframe
      r = pl.call(nrow)
      c = pl.call(ncol)
      stringio.puts \
        "#{self.class} : #{nrow} observation#{r}(row#{r}) of #{ncol} variable#{c}(column#{c})"

      # (2) show var counts by type
      type_groups = types(class_name: true).map do |d|
        if Arrow::NumericDataType >= d
          :numeric
        elsif Arrow::StringDataType >= d
          :string
        elsif Arrow::BooleanDataType >= d
          :boolean
        elsif Arrow::TemporalDataType >= d
          :temporal
        else
          :other
        end
      end
      tg = type_groups.tally

      a = []
      a << "#{tg[:numeric]} numeric" if tg[:numeric]
      a << "#{tg[:string]} string#{pl.call(tg[:string])}" if tg[:string]
      a << "#{tg[:boolean]} boolean" if tg[:boolean]
      a << "#{tg[:temporal]} temporal" if tg[:temporal]
      stringio.puts "Variable#{pl.call(ncol)} : #{a.join(', ')}"

      # (3) print header of rows
      # calc levels (num of unique elemnets) for each Vector
      levels = vectors.map { |v| v.to_a.uniq.size }

      # calc column width to show
      row_headers = { idx: '#', key: 'key', type: 'type', levels: 'level', data: 'data_preview' }

      # find longest word to adjust column width
      w_idx = ncol.to_s.size
      w_key = (keys.map { |key| key.size + 1 } << row_headers[:key].size).max
      w_type = (types.map(&:size) << row_headers[:type].size).max
      w_row = (levels.map { |l| l.to_s.size } << row_headers[:levels].size).max
      stringio.printf("%-#{w_idx}s %-#{w_key}s %-#{w_type}s %-#{w_row}s %s\n", *row_headers.values)

      # (4) show details for each column (vector)
      vectors.each.with_index(1) do |vec, i|
        key = keys[i - 1]
        type = types[i - 1]
        type_group = type_groups[i - 1]
        data_tally = vec.tally

        str = format("%#{w_row}d ", data_tally.size)
        case type_group
        when :numeric, :string, :boolean
          if data_tally.size <= tally_level && data_tally.size != nrow
            str << data_tally.to_s
          else
            a = vec.to_a.take(max_element)
            a << '...' if nrow > max_element
            str << "[#{a.join(', ')}]"
          end
          #  c = vector.is_nan.tally[1]   # release when impremented
          #  str << " #{c} NaN#{pl.(c)}" if c&.>(0)  # safely call c>0
        else
          a = vec.to_a.take(max_element)
          a << '...' if nrow > max_element
          str << "[#{a.join(', ')}]"
        end

        stringio.printf("%#{w_idx}d %-#{w_key}s %-#{w_type}s %s\n", i, ":#{key}", type, str)
      end

      stringio.string
    end
  end
end
