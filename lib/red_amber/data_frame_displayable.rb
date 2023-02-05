# frozen_string_literal: true

require 'stringio'

module RedAmber
  # Mix-in for the class DataFrame
  module DataFrameDisplayable
    # Used internally to display table.
    INDEX_KEY = :index_key_for_format_table
    private_constant :INDEX_KEY

    # rubocop:disable Layout/LineLength

    # Show a preview of self as a string.
    #
    # @param width [Integer]
    #   maximum size of result.
    # @return [String]
    #   string representation of self.
    # @example Show penguins dataset
    #   puts penguins.to_s
    #
    #   # =>
    #       species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #       <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #     0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #     1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #     2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #     3 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #     4 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #     : :        :                      :             :                 : ...        :
    #   341 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #   342 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #   343 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    def to_s(width: 80)
      return '' if empty?

      format_table(width: width)
    end

    # Show statistical summary by a new DataFrame.
    #
    # This method will make stats only for numeric columns.
    # - NaNs are ignored.
    # - `count` shows non-NaN counts.
    #
    # @return [DataFrame]
    #   a new dataframe.
    # @example Statistical summary of penguins dataset
    #   # needs more width to show all stats in this example
    #   puts penguins.summary.to_s(width: 82)
    #
    #   # =>
    #     variables            count     mean      std      min      25%   median      75%      max
    #     <dictionary>      <uint16> <double> <double> <double> <double> <double> <double> <double>
    #   0 bill_length_mm         342    43.92     5.46     32.1    39.23    44.38     48.5     59.6
    #   1 bill_depth_mm          342    17.15     1.97     13.1     15.6    17.32     18.7     21.5
    #   2 flipper_length_mm      342   200.92    14.06    172.0    190.0    197.0    213.0    231.0
    #   3 body_mass_g            342  4201.75   801.95   2700.0   3550.0   4031.5   4750.0   6300.0
    #   4 year                   344  2008.03     0.82   2007.0   2007.0   2008.0   2009.0   2009.0
    #
    def summary
      num_keys = keys.select { |key| self[key].numeric? }

      DataFrame.new(
        variables: num_keys,
        count: num_keys.map { |k| self[k].count },
        mean: num_keys.map { |k| self[k].mean },
        std: num_keys.map { |k| self[k].std },
        min: num_keys.map { |k| self[k].min },
        '25%': num_keys.map { |k| self[k].quantile(0.25) },
        median: num_keys.map { |k| self[k].median },
        '75%': num_keys.map { |k| self[k].quantile(0.75) },
        max: num_keys.map { |k| self[k].max }
      )
    end
    alias_method :describe, :summary

    # Show information of self.
    #
    # According to `ENV [“RED_AMBER_OUTPUT_MODE”].upcase`,
    # - If it is 'TDR', returns class, shape and transposed preview by 3 rows.
    # - If it is 'MINIMUM', returns class and shape.
    # - If it is 'TABLE' or otherwise, returns class, shape and Table preview.
    #   Default value of the ENV is 'Table'.
    # @return [String]
    #   information of self.
    # @example Default (ENV ['RED_AMBER_OUTPUT_MODE'] == 'Table')
    #   puts df.inspect
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000000c148>
    #           x y
    #     <uint8> <string>
    #   0       1 A
    #   1       2 B
    #   2       3 C
    #
    # @example In case of ENV ['RED_AMBER_OUTPUT_MODE'] == 'TDR'
    #   puts df.inspect
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000000c148>
    #   Vectors : 1 numeric, 1 string
    #   # key type   level data_preview
    #   0 :x  uint8      3 [1, 2, 3]
    #   1 :y  string     3 ["A", "B", "C"]
    #
    # @example In case of ENV ['RED_AMBER_OUTPUT_MODE'] == 'Minimum'
    #   puts df.inspect
    #
    #   # =>
    #   RedAmber::DataFrame : 3 x 2 Vectors
    #
    def inspect
      mode = ENV.fetch('RED_AMBER_OUTPUT_MODE', 'Table')
      case mode.upcase
      when 'TDR'
        "#<#{shape_str(with_id: true)}>\n#{dataframe_info(3)}"
      when 'MINIMUM'
        shape_str
      else
        "#<#{shape_str(with_id: true)}>\n#{self}"
      end
    end

    # Shows some information about self in a transposed style.
    #
    # @param limit [Integer, :all]
    #   maximum number of variables (columns) to show.
    #   Shows all valiables (columns) if it is `:all`.
    # @param tally [Integer]
    #   maximum level to use tally mode.
    #   Tally mode counts the occurrences of each element and shows as a hash
    #   with the elements as keys and the corresponding counts as values.
    # @param elements [Integer]
    #   maximum number of elements to show values
    #   in each column.
    # @return [nil]
    # @example Default
    #   diamonds = diamonds.assign_left(:index) { indices }
    #   diamonds
    #
    #   # =>
    #   #<RedAmber::DataFrame : 53940 x 11 Vectors, 0x000000000000c314>
    #            index    carat cut       color    clarity     depth    table    price ...        z
    #         <uint16> <double> <string>  <string> <string> <double> <double> <uint16> ... <double>
    #       0        0     0.23 Ideal     E        SI2          61.5     55.0      326 ...     2.43
    #       1        1     0.21 Premium   E        SI1          59.8     61.0      326 ...     2.31
    #       2        2     0.23 Good      E        VS1          56.9     65.0      327 ...     2.31
    #       3        3     0.29 Premium   I        VS2          62.4     58.0      334 ...     2.63
    #       4        4     0.31 Good      J        SI2          63.3     58.0      335 ...     2.75
    #       :        :        : :         :        :               :        :        : ...        :
    #   53937    53937      0.7 Very Good D        SI1          62.8     60.0     2757 ...     3.56
    #   53938    53938     0.86 Premium   H        SI2          61.0     58.0     2757 ...     3.74
    #   53939    53939     0.75 Ideal     D        SI2          62.2     55.0     2757 ...     3.64
    #
    #   diamonds.tdr
    #
    #   # =>
    #   RedAmber::DataFrame : 53940 x 11 Vectors
    #   Vectors : 8 numeric, 3 strings
    #   #  key      type   level data_preview
    #   0  :index   uint16 53940 [0, 1, 2, 3, 4, ... ]
    #   1  :carat   double   273 [0.23, 0.21, 0.23, 0.29, 0.31, ... ]
    #   2  :cut     string     5 {"Ideal"=>21551, "Premium"=>13791, "Good"=>4906, "Very Good"=>12082, "Fair"=>1610}
    #   3  :color   string     7 ["E", "E", "E", "I", "J", ... ]
    #   4  :clarity string     8 ["SI2", "SI1", "VS1", "VS2", "SI2", ... ]
    #   5  :depth   double   184 [61.5, 59.8, 56.9, 62.4, 63.3, ... ]
    #   6  :table   double   127 [55.0, 61.0, 65.0, 58.0, 58.0, ... ]
    #   7  :price   uint16 11602 [326, 326, 327, 334, 335, ... ]
    #   8  :x       double   554 [3.95, 3.89, 4.05, 4.2, 4.34, ... ]
    #   9  :y       double   552 [3.98, 3.84, 4.07, 4.23, 4.35, ... ]
    #    ... 1 more Vector ...
    #
    # @example Show all variables
    #   diamonds.tdr(:all)
    #
    #   # =>
    #   RedAmber::DataFrame : 53940 x 11 Vectors
    #   Vectors : 8 numeric, 3 strings
    #   #  key      type   level data_preview
    #   0  :index   uint16 53940 [0, 1, 2, 3, 4, ... ]
    #   1  :carat   double   273 [0.23, 0.21, 0.23, 0.29, 0.31, ... ]
    #   2  :cut     string     5 {"Ideal"=>21551, "Premium"=>13791, "Good"=>4906, "Very Good"=>12082, "Fair"=>1610}
    #   3  :color   string     7 ["E", "E", "E", "I", "J", ... ]
    #   4  :clarity string     8 ["SI2", "SI1", "VS1", "VS2", "SI2", ... ]
    #   5  :depth   double   184 [61.5, 59.8, 56.9, 62.4, 63.3, ... ]
    #   6  :table   double   127 [55.0, 61.0, 65.0, 58.0, 58.0, ... ]
    #   7  :price   uint16 11602 [326, 326, 327, 334, 335, ... ]
    #   8  :x       double   554 [3.95, 3.89, 4.05, 4.2, 4.34, ... ]
    #   9  :y       double   552 [3.98, 3.84, 4.07, 4.23, 4.35, ... ]
    #   10 :z       double   375 [2.43, 2.31, 2.31, 2.63, 2.75, ... ]
    #
    # @example Use tally mode up to 8 levels
    #   diamonds.tdr(tally: 8)
    #
    #   # =>
    #   RedAmber::DataFrame : 53940 x 11 Vectors
    #   Vectors : 8 numeric, 3 strings
    #   #  key      type   level data_preview
    #   0  :index   uint16 53940 [0, 1, 2, 3, 4, ... ]
    #   1  :carat   double   273 [0.23, 0.21, 0.23, 0.29, 0.31, ... ]
    #   2  :cut     string     5 {"Ideal"=>21551, "Premium"=>13791, "Good"=>4906, "Very Good"=>12082, "Fair"=>1610}
    #   3  :color   string     7 {"E"=>9797, "I"=>5422, "J"=>2808, "H"=>8304, "F"=>9542, "G"=>11292, "D"=>6775}
    #   4  :clarity string     8 {"SI2"=>9194, "SI1"=>13065, "VS1"=>8171, "VS2"=>12258, "VVS2"=>5066, "VVS1"=>3655, "I1"=>741, "IF"=>1790}
    #   5  :depth   double   184 [61.5, 59.8, 56.9, 62.4, 63.3, ... ]
    #   6  :table   double   127 [55.0, 61.0, 65.0, 58.0, 58.0, ... ]
    #   7  :price   uint16 11602 [326, 326, 327, 334, 335, ... ]
    #   8  :x       double   554 [3.95, 3.89, 4.05, 4.2, 4.34, ... ]
    #   9  :y       double   552 [3.98, 3.84, 4.07, 4.23, 4.35, ... ]
    #    ... 1 more Vector ...
    #
    # @example Increase elements to show
    #   diamonds.tdr(elements: 10)
    #
    #   # =>
    #   RedAmber::DataFrame : 53940 x 11 Vectors
    #   Vectors : 8 numeric, 3 strings
    #   #  key      type   level data_preview
    #   0  :index   uint16 53940 [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ... ]
    #   1  :carat   double   273 [0.23, 0.21, 0.23, 0.29, 0.31, 0.24, 0.24, 0.26, 0.22, 0.23, ... ]
    #   2  :cut     string     5 {"Ideal"=>21551, "Premium"=>13791, "Good"=>4906, "Very Good"=>12082, "Fair"=>1610}
    #   3  :color   string     7 ["E", "E", "E", "I", "J", "J", "I", "H", "E", "H", ... ]
    #   4  :clarity string     8 ["SI2", "SI1", "VS1", "VS2", "SI2", "VVS2", "VVS1", "SI1", "VS2", "VS1", ... ]
    #   5  :depth   double   184 [61.5, 59.8, 56.9, 62.4, 63.3, 62.8, 62.3, 61.9, 65.1, 59.4, ... ]
    #   6  :table   double   127 [55.0, 61.0, 65.0, 58.0, 58.0, 57.0, 57.0, 55.0, 61.0, 61.0, ... ]
    #   7  :price   uint16 11602 [326, 326, 327, 334, 335, 336, 336, 337, 337, 338, ... ]
    #   8  :x       double   554 [3.95, 3.89, 4.05, 4.2, 4.34, 3.94, 3.95, 4.07, 3.87, 4.0, ... ]
    #   9  :y       double   552 [3.98, 3.84, 4.07, 4.23, 4.35, 3.96, 3.98, 4.11, 3.78, 4.05, ... ]
    #    ... 1 more Vector ...
    #
    def tdr(limit = 10, tally: 5, elements: 5)
      puts tdr_str(limit, tally: tally, elements: elements)
    end

    # rubocop:enable Layout/LineLength

    # Returns some information about self in a transposed style by a string.
    #
    # @param (see #tdr)
    # @option (see #tdr)
    # @return [String] TDR style string.
    #
    def tdr_str(limit = 10, tally: 5, elements: 5)
      "#{shape_str}\n#{dataframe_info(limit, tally_level: tally, max_element: elements)}"
    end

    # Returns html formatted text of self by IRuby::HTML.table.
    #
    # According to `ENV [“RED_AMBER_OUTPUT_MODE”].upcase`,
    # - If it is 'MINIMUM', returns shape by plain text.
    # - If it is 'PLAIN', returns `#inspect` value by plain text.
    # - If it is 'TDR', returns shape and transposed preview by plain text.
    # - If it is 'TABLE' or otherwise, returns Table preview by html format.
    #   Default value of the ENV is 'TABLE'.
    # @return [String]
    #   formatted string.
    #
    def to_iruby
      require 'iruby'
      return ['text/plain', '(empty DataFrame)'] if empty?

      mode = ENV.fetch('RED_AMBER_OUTPUT_MODE', 'Table')
      case mode.upcase
      when 'PLAIN'
        ['text/plain', inspect]
      when 'MINIMUM'
        ['text/plain', shape_str]
      when 'TDR'
        size <= 5 ? ['text/plain', tdr_str(tally: 0)] : ['text/plain', tdr_str]
      else # 'TABLE'
        ['text/html', html_table]
      end
    end

    # Return class and shape of self by a String.
    #
    # @param with_id [true, false]
    #   show id if true.
    # @return [String]
    #   shape string.
    # @example Default (without id)
    #   penguins.shape_str
    #
    #   # =>
    #   "RedAmber::DataFrame : 344 x 8 Vectors"
    #
    # @example With id
    #   penguins.shape_str(with_id: true)
    #
    #   # =>
    #   "RedAmber::DataFrame : 344 x 8 Vectors, 0x0000000000003980"
    #
    def shape_str(with_id: false)
      shape_info = empty? ? '(empty)' : "#{size} x #{n_keys} Vector#{pl(n_keys)}"
      id = with_id ? format(', 0x%016x', object_id) : ''
      "#{self.class} : #{shape_info}#{id}"
    end

    private # =====

    def dataframe_info(limit, tally_level: 5, max_element: 5)
      return '' if empty?

      limit = n_keys if [:all, -1].include? limit

      tallys = vectors.map(&:tally)
      levels = tallys.map(&:size)
      type_groups = @table.columns.map { |column| type_group(column.data_type) }
      quoted_keys = keys.map(&:inspect)
      headers = { idx: '#', key: 'key', type: 'type', levels: 'level',
                  data: 'data_preview' }
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
        sio.printf header_format, i, key, type, data_tally.size, a.join(', ')
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

    def format_table(width: 80, head: 5, tail: 3, n_digit: 2)
      return "  #{keys.join(' ')}\n  (Empty Vectors)\n" if size.zero?

      original = self
      indices = size > head + tail ? [*0..head, *(size - tail)...size] : [*0...size]
      df = slice(indices).assign do
        assigner = { INDEX_KEY => indices.map(&:to_s) }
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
      df = size > head + tail ? df[0, 0, 0..head, -tail..-1] : df[0, 0, 0..-1]
      df = df.assign do
        vectors.each_with_object({}) do |v, assigner|
          vec = v.replace(0, v.key == INDEX_KEY ? '' : v.key.to_s)
                 .replace(1, v.key == INDEX_KEY ? '' : "<#{original[v.key].type}>")
          assigner[v.key] =
            original.size > head + tail + 1 ? vec.replace(head + 2, ':') : vec
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

    def html_table
      reduced = size > 8 ? self[0..4, -4..-1] : self

      converted = reduced.assign do
        vectors.select.with_object({}) do |vector, assigner|
          assigner[vector.key] = vector.map do |element|
            case element
            in TrueClass
              '<i>(true)</i>'
            in FalseClass
              '<i>(false)</i>'
            in NilClass
              '<i>(nil)</i>'
            in ''
              '""'
            in String
              element.sub(/^(\s+)$/, '"\1"') # blank spaces
            in Float
              format('%g', element)
            in Integer
              format('%d', element)
            end
          end
        end
      end

      html = IRuby::HTML.table(converted.to_h, maxrows: 8, maxcols: 15)
      "#{self.class} <#{size} x #{n_keys} vector#{pl(n_keys)}> #{html}"
    end
  end
end
