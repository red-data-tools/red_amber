# frozen_string_literal: true

require 'stringio'

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameDisplayable
    def to_s
      @table.to_s
    end

    # def describe() end

    # def summary() end

    def inspect
      "#<#{shape_str(with_id: true)}>\n#{dataframe_info(3)}"
    end

    # - limit: max num of Vectors to show
    # - tally: max level to use tally mode
    # - elements: max element to show values in each vector
    def tdr(limit = 10, tally: 5, elements: 5)
      puts tdr_str(limit, tally: tally, elements: elements)
    end

    def tdr_str(limit = 10, tally: 5, elements: 5)
      "#{shape_str}\n#{dataframe_info(limit, tally_level: tally, max_element: elements)}"
    end

    private # =====

    def pl(num)
      num > 1 ? 's' : ''
    end

    def shape_str(with_id: false)
      shape_info = empty? ? '(empty)' : "#{size} x #{n_keys} Vector#{pl(n_keys)}"
      id = with_id ? format(', 0x%016x', object_id) : ''
      "#{self.class} : #{shape_info}#{id}"
    end

    def dataframe_info(limit, tally_level: 5, max_element: 5)
      return '' if empty?

      limit = n_keys if [:all, -1].include? limit

      tallys = vectors.map(&:tally)
      levels = tallys.map(&:size)
      type_groups = @table.columns.map { |column| type_group(column.data_type) }
      quoted_keys = keys.map(&:inspect)
      headers = { idx: '#', key: 'key', type: 'type', levels: 'level', data: 'data_preview' }
      header_format = make_header_format(levels, headers, quoted_keys)

      sio = StringIO.new # output string buffer
      sio.puts "Vector#{pl(n_keys)} : #{var_type_count(type_groups).join(', ')}"
      sio.printf header_format, *headers.values

      vectors.each.with_index do |vector, i|
        if i >= limit
          sio << " ... #{n_keys - i} more Vector#{pl(n_keys - i)} ...\n"
          break
        end
        key = quoted_keys[i]
        type = types[i]
        type_group = type_groups[i]
        data_tally = tallys[i]
        a = case type_group
            when :numeric, :string, :boolean
              if data_tally.size <= tally_level && data_tally.size != size
                [data_tally.to_s]
              else
                [shorthand(vector, size, max_element)].concat na_string(vector)
              end
            else
              [shorthand(vector, size, max_element)]
            end
        sio.printf header_format, i + 1, key, type, data_tally.size, a.join(', ')
      end
      sio.string
    end

    def make_header_format(levels, headers, quoted_keys)
      # find longest word to adjust width
      w_idx = n_keys.to_s.size
      w_key = [quoted_keys.map(&:size).max, headers[:key].size].max
      w_type = [types.map(&:size).max, headers[:type].size].max
      w_level = [levels.map { |l| l.to_s.size }.max, headers[:levels].size].max
      "%-#{w_idx}s %-#{w_key}s %-#{w_type}s %#{w_level}s %s\n"
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

    def shorthand(vector, size, max_element)
      max = vector.temporal? ? 2 : max_element
      a = vector.to_a.take(max)
      a.map! { |e| e.nil? ? 'nil' : e.inspect }
      a << '... ' if size > max
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
