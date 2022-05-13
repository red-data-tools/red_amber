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
    # - TODO: Is it better to change name other than `inspect` ?
    # - TODO: Fall back to inspect_raw when treating large dataset
    # - TODO: Refactor code to smaller methods
    def inspect(tally_level: 5, max_element: 5)
      return '#<RedAmber::DataFrame (empty)>' if empty?

      stringio = StringIO.new # output string buffer

      tallys = vectors.map(&:tally)
      levels = tallys.map(&:size)
      type_groups = @table.columns.map { |column| type_group(column.data_type) }
      quoted_keys = keys.map(&:inspect)
      headers = { idx: '#', key: 'key', type: 'type', levels: 'level', data: 'data_preview' }
      header_format = make_header_format(levels, headers, quoted_keys)

      # 1st row: show shape of the dataframe
      vs = "Vector#{pl(ncol)}"
      stringio.puts \
        "#{self.class} : #{nrow} x #{ncol} #{vs}"

      # 2nd row: show var counts by type
      stringio.puts "#{vs} : #{var_type_count(type_groups).join(', ')}"

      # 3rd row: print header of rows
      stringio.printf header_format, *headers.values

      # 4th row ~: show details for each column (vector)
      vectors.each.with_index do |vector, i|
        key = quoted_keys[i]
        type = types[i]
        type_group = type_groups[i]
        data_tally = tallys[i]

        a = case type_group
            when :numeric, :string, :boolean
              if data_tally.size <= tally_level && data_tally.size != nrow
                [data_tally.to_s]
              else
                [shorthand(vector, nrow, max_element)].concat na_string(vector)
              end
            else
              shorthand(vector, nrow, max_element)
            end
        stringio.printf header_format, i + 1, key, type, data_tally.size, a.join(', ')
      end
      stringio.string
    end

    private # =====

    def pl(num)
      num > 1 ? 's' : ''
    end

    def make_header_format(levels, headers, quoted_keys)
      # find longest word to adjust column width
      w_idx = ncol.to_s.size
      w_key = [quoted_keys.map(&:size).max, headers[:key].size].max
      w_type = [types.map(&:size).max, headers[:type].size].max
      w_row = [levels.map { |l| l.to_s.size }.max, headers[:levels].size].max
      "%-#{w_idx}s %-#{w_key}s %-#{w_type}s %#{w_row}s %s\n"
    end

    def type_group(data_type)
      case data_type
      when Arrow::NumericDataType then :numeric
      when Arrow::StringDataType then :string
      when Arrow::BooleanDataType then :boolean
      when Arrow::TemporalDataType then :temporal
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

    def shorthand(vector, nrow, max_element)
      a = vector.to_a.take(max_element)
      a.map! { |e| e.nil? ? 'nil' : e.inspect }
      a << '... ' if nrow > max_element
      "[#{a.join(', ')}]"
    end

    def na_string(vector)
      n_nan = vector.n_nans
      n_nil = vector.n_nils
      a = []
      return a if (n_nan + n_nil).zero?

      a << "#{n_nan} NaN#{pl(n_nan)}" unless n_nan.zero?
      a << "#{n_nil} nil#{pl(n_nil)}" unless n_nil.zero?
      a
    end
  end
end
