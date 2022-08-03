# frozen_string_literal: true

require 'stringio'

module RedAmber
  # mix-ins for the class DataFrame
  module DataFrameDisplayable
    INDEX_KEY = :index_key_for_format_table

    def to_s
      return '' if empty?

      format_table(width: 80)
    end

    # def describe() end

    # def summary() end

    def inspect
      if ENV.fetch('RED_AMBER_OUTPUT_MODE', 'Table') == 'TDR'
        "#<#{shape_str(with_id: true)}>\n#{dataframe_info(3)}"
      else
        "#<#{shape_str(with_id: true)}>\n#{self}"
      end
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

    def format_table(width: 80)
      head = 5
      tail = 3
      n_digit = 1

      original = self
      indices = size > head + tail ? [*0...head, *(size - tail)...size] : [*0...size]
      df = slice(indices).assign do
        assigner = { INDEX_KEY => indices.map { |i| (i + 1).to_s } }
        vectors.each_with_object(assigner) do |v, a|
          a[v.key] = v.to_a.map do |e|
            if e.nil?
              '(nil)'
            elsif v.float?
              e.round(n_digit).to_s
            elsif v.string?
              e
            else
              e.to_s
            end
          end
        end
      end

      df = df.pick { [INDEX_KEY, keys - [INDEX_KEY]] }
      df = size > head + tail ? df[0, 0, 0...head, 0, -tail..-1] : df[0, 0, 0..-1]
      df = df.assign do
        vectors.each_with_object({}) do |v, assigner|
          vec = v.replace(0, v.key == INDEX_KEY ? '' : v.key.to_s)
                 .replace(1, v.key == INDEX_KEY ? '' : "<#{original[v.key].type}>")
          assigner[v.key] = size > head + tail ? vec.replace(head + 2, ':') : vec
        end
      end

      width_list = df.vectors.map { |v| v.to_a.map(&:length).max }
      total_length = width_list[-1] # reserved for last column

      formats = []
      row_ellipsis = nil
      df.vectors.each_with_index do |v, i|
        w = width_list[i]
        if total_length + w > width && i < df.n_keys - 1
          row_ellipsis = i
          formats << '%3s'
          formats << format_for_column(df.vectors[-1], original, width_list[-1])
          break
        end
        formats << format_for_column(v, original, w)
        total_length += w
      end
      format_str = formats.join(' ')

      str = StringIO.new
      if row_ellipsis
        df = df[df.keys[0..row_ellipsis], df.keys[-1]]
        df = df.assign(df.keys[row_ellipsis] => ['...'] * df.size)
      end

      df.to_a.each do |row|
        str.puts format(format_str, *row).rstrip
      end

      str.string
    end

    def format_for_column(vector, original, width)
      if vector.key != INDEX_KEY && !original[vector.key].numeric?
        "%-#{width}s"
      else
        "%#{width}s"
      end
    end
  end
end
