# frozen_string_literal: true

module RedAmber
  # Mix-in for the class DataFrame
  module DataFrameSelectable
    # Array, Arrow::Array and Arrow::ChunkedArray are refined
    using RefineArray
    using RefineArrayLike

    # rubocop:disable Layout/LineLength

    # Select variables or records.
    #
    # @overload [](key)
    #   Select single variable (column) and return as a Vetor.
    #
    #   @param key [Symbol, String]
    #     key name to select.
    #   @return [Vector]
    #     selected variable as a Vector.
    #   @note DataFrame.v(key) is faster to create Vector from a variable.
    #   @example Select a column and return Vector
    #     penguins
    #
    #     # =>
    #     #<RedAmber::DataFrame : 344 x 8 Vectors, 0x00000000000039bc>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #       4 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     341 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #     342 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #     343 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    #     penguins[:bill_length_mm]
    #
    #     # =>
    #     #<RedAmber::Vector(:double, size=344):0x00000000000104dc>
    #     [39.1, 39.5, 40.3, nil, 36.7, 39.3, 38.9, 39.2, 34.1, 42.0, 37.8, 37.8, 41.1, ... ]
    #
    # @overload [](keys)
    #   Select variables and return a DataFrame.
    #
    #   @param keys [<Symbol, String>] key names to select.
    #   @return [DataFrame]
    #     selected variables as a DataFrame.
    #   @example Select columns
    #     penguins[:island, :bill_length_mm]
    #
    #     # =>
    #     #<RedAmber::DataFrame : 344 x 2 Vectors, 0x00000000000104f0>
    #         island    bill_length_mm
    #         <string>        <double>
    #       0 Torgersen           39.1
    #       1 Torgersen           39.5
    #       2 Torgersen           40.3
    #       3 Torgersen          (nil)
    #       4 Torgersen           36.7
    #       : :                      :
    #     341 Biscoe              50.4
    #     342 Biscoe              45.2
    #     343 Biscoe              49.9
    #
    # @overload [](index)
    #   Select a record and return a DataFrame.
    #
    #   @param index [Indeger, Float, Range<Integer>, Vector, Arrow::Array]
    #     index of a row to select.
    #   @return [DataFrame]
    #     selected variables as a DataFrame.
    #   @example Select a row
    #     penguins[0]
    #
    #     # =>
    #     #<RedAmber::DataFrame : 1 x 8 Vectors, 0x0000000000010504>
    #       species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #       <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #     0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #
    # @overload [](indices)
    #   Select records by indices and return a DataFrame.
    #
    #   @param indices [<Indeger>, <Float>, Range<Integer>, Vector, Arrow::Array>]
    #     indices of rows to select.
    #   @return [DataFrame]
    #     selected variables as a DataFrame.
    #   @example Select rows by indices
    #     penguins[0..100]
    #
    #     # =>
    #     #<RedAmber::DataFrame : 101 x 8 Vectors, 0x00000000000105e0>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #       4 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       : :        :                      :             :                 : ...        :
    #      98 Adelie   Dream               33.1          16.1               178 ...     2008
    #      99 Adelie   Dream               43.2          18.5               192 ...     2008
    #     100 Adelie   Biscoe              35.0          17.9               192 ...     2009
    #
    # @overload [](booleans)
    #   Select records by booleans and return a DataFrame.
    #
    #   @param booleans [Array<true, false, nil>, Vector, Arrow::Array>]
    #     booleans of rows to select.
    #   @return [DataFrame]
    #     selected variables as a DataFrame.
    #   @example Select rows by booleans
    #     penguins[penguins.species == 'Adelie']
    #
    #     # =>
    #     #<RedAmber::DataFrame : 152 x 8 Vectors, 0x0000000000010658>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #       4 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     149 Adelie   Dream               37.8          18.1               193 ...     2009
    #     150 Adelie   Dream               36.0          17.1               187 ...     2009
    #     151 Adelie   Dream               41.5          18.5               201 ...     2009
    #
    def [](*args)
      raise DataFrameArgumentError, 'self is an empty dataframe' if empty?

      case args
      in [] | [nil]
        return remove_all_values
      in [(Symbol | String) => k] if key? k
        return variables[k.to_sym]
      in [Integer => i]
        return take([i.negative? ? i + size : i])
      in [Vector => v]
        arrow_array = v.data
      in [(Arrow::Array | Arrow::ChunkedArray) => aa]
        arrow_array = aa
      else
        a = parse_args(args, size)
        return select_variables_by_keys(a) if a.symbol?
        return take(normalize_indices(Arrow::Array.new(a))) if a.integer?
        return remove_all_values if a.compact.empty?
        return filter_by_array(Arrow::BooleanArray.new(a)) if a.boolean?

        raise DataFrameArgumentError, "invalid arguments: #{args}"
      end

      return take(normalize_indices(arrow_array)) if arrow_array.numeric?
      return filter_by_array(arrow_array) if arrow_array.boolean?

      a = arrow_array.to_a
      return select_variables_by_keys(a) if a.symbol_or_string?

      raise DataFrameArgumentError, "invalid arguments: #{args}"
    end

    # Select a variable by String or Symbol and return as a Vector.
    #
    # @param key [Symbol, String]
    #   key name to select.
    # @return [Vector]
    #   selected variable as a Vector.
    # @note #v(key) is faster then #[](key).
    # @example Select a column and return Vector
    #   penguins.v(:bill_length_mm)
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=344):0x000000000000f140>
    #   [39.1, 39.5, 40.3, nil, 36.7, 39.3, 38.9, 39.2, 34.1, 42.0, 37.8, 37.8, 41.1, ... ]
    #
    def v(key)
      unless key.is_a?(Symbol) || key.is_a?(String)
        raise DataFrameArgumentError, "Key is not a Symbol or a String: [#{key}]"
      end
      raise DataFrameArgumentError, "Key does not exist: [#{key}]" unless key? key

      variables[key.to_sym]
    end

    # Select records to create a DataFrame.
    #
    # @overload slice(row)
    #   Select a record and return a DataFrame.
    #
    #   @param row [Indeger, Float]
    #     a row index to select.
    #   @return [DataFrame]
    #     selected variables as a DataFrame.
    #   @example Select a row
    #   penguins
    #
    #   # =>
    #   #<RedAmber::DataFrame : 344 x 8 Vectors, 0x00000000000039bc>
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
    #   penguins.slice(2)
    #
    #   # =>
    #   #<RedAmber::DataFrame : 1 x 8 Vectors, 0x00000000000039d0>
    #     species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #     <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #   0 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #
    # @overload slice(rows)
    #   Select records and return a DataFrame.
    #   - Duplicated selection is acceptable. The same record will be returned.
    #   - The order of records will be the same as specified indices.
    #
    #   @param rows [<Integer>, <Float>, Range<Integer>, Vector, Arrow::Array]
    #     row indeces to select.
    #   @return [DataFrame]
    #     selected variables as a DataFrame.
    #   @example Select rows
    #     penguins.slice(300..-1)
    #
    #     # =>
    #     #<RedAmber::DataFrame : 44 x 8 Vectors, 0x000000000000fb54>
    #        species  island   bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #        <string> <string>       <double>      <double>           <uint8> ... <uint16>
    #      0 Gentoo   Biscoe             49.1          14.5               212 ...     2009
    #      1 Gentoo   Biscoe             52.5          15.6               221 ...     2009
    #      2 Gentoo   Biscoe             47.4          14.6               212 ...     2009
    #      3 Gentoo   Biscoe             50.0          15.9               224 ...     2009
    #      4 Gentoo   Biscoe             44.9          13.8               212 ...     2009
    #      : :        :                     :             :                 : ...        :
    #     41 Gentoo   Biscoe             50.4          15.7               222 ...     2009
    #     42 Gentoo   Biscoe             45.2          14.8               212 ...     2009
    #     43 Gentoo   Biscoe             49.9          16.1               213 ...     2009
    #
    # @overload slice
    #   Select records by indices with block and return a DataFrame.
    #   - Duplicated selection is acceptable. The same record will be returned.
    #   - The order of records will be the same as specified indices.
    #
    #   @yield [self]
    #     gives self to the block.
    #     The block is evaluated within the context of self.
    #   @yieldparam self [DataFrame]
    #     self. Usually, it can be omitted.
    #   @yieldreturn [<Integer>, <Float>, Range<Integer>, Vector, Arrow::Array]
    #     row indeces to select.
    #   @return [DataFrame]
    #     selected records as a DataFrame.
    #   @example Select rows by block
    #     penguins.slice { 0.step(size, 10) }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 35 x 8 Vectors, 0x000000000000fd84>
    #        species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #        <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #      0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #      1 Adelie   Torgersen           37.8          17.1               186 ...     2007
    #      2 Adelie   Biscoe              37.8          18.3               174 ...     2007
    #      3 Adelie   Dream               39.5          16.7               178 ...     2007
    #      4 Adelie   Dream               36.5          18.0               182 ...     2007
    #      : :        :                      :             :                 : ...        :
    #     32 Gentoo   Biscoe              48.5          15.0               219 ...     2009
    #     33 Gentoo   Biscoe              50.5          15.2               216 ...     2009
    #     34 Gentoo   Biscoe              46.8          14.3               215 ...     2009
    #
    # @overload slice(booleans)
    #   Select records by filtering with booleans and return a DataFrame.
    #
    #   @param booleans [<Boolean, nil>, Vector, Arrow::Array]
    #     a boolean filter.
    #   @return [DataFrame]
    #     filtered records as a DataFrame.
    #   @example Select rows by boolean filter
    #     penguins.slice(penguins[:bill_length_mm] > 50)
    #
    #     # =>
    #     #<RedAmber::DataFrame : 52 x 8 Vectors, 0x000000000000fd98>
    #        species   island   bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #        <string>  <string>       <double>      <double>           <uint8> ... <uint16>
    #      0 Chinstrap Dream              51.3          19.2               193 ...     2007
    #      1 Chinstrap Dream              52.7          19.8               197 ...     2007
    #      2 Chinstrap Dream              51.3          18.2               197 ...     2007
    #      3 Chinstrap Dream              51.3          19.9               198 ...     2007
    #      4 Chinstrap Dream              51.7          20.3               194 ...     2007
    #      : :         :                     :             :                 : ...        :
    #     49 Gentoo    Biscoe             51.5          16.3               230 ...     2009
    #     50 Gentoo    Biscoe             55.1          16.0               230 ...     2009
    #     51 Gentoo    Biscoe             50.4          15.7               222 ...     2009
    #
    # @overload slice
    #   Select records by filtering with block and return a DataFrame.
    #
    #   @yield [self]
    #     gives self to the block.
    #     The block is evaluated within the context of self.
    #   @yieldparam self [DataFrame]
    #     self. Usually, it can be omitted.
    #   @yieldreturn [<Boolean, nil>, Vector, Arrow::Array]
    #     a boolean filter. `Vector` or `Arrow::Array` must be boolean type.
    #   @return [DataFrame]
    #     filtered records as a DataFrame.
    #   @example Select rows by booleans from block
    #     penguins.slice { indices.map(&:even?) }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 172 x 8 Vectors, 0x000000000000ff78>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       2 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       3 Adelie   Torgersen           38.9          17.8               181 ...     2007
    #       4 Adelie   Torgersen           34.1          18.1               193 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     169 Gentoo   Biscoe              47.2          13.7               214 ...     2009
    #     170 Gentoo   Biscoe              46.8          14.3               215 ...     2009
    #     171 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #
    def slice(*args, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?

      if block
        unless args.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and block.'
        end

        args = [instance_eval(&block)]
      end

      arrow_array =
        case args
        in [] | [[]]
          return remove_all_values
        in [Vector => v]
          v.data
        in [(Arrow::Array | Arrow::ChunkedArray) => aa]
          aa
        else
          Arrow::Array.new(parse_args(args, size))
        end

      if arrow_array.numeric?
        take(normalize_indices(arrow_array))
      elsif arrow_array.boolean?
        filter_by_array(arrow_array)
      elsif arrow_array.to_a.compact.empty?
        # Ruby 3.0.4 does not accept Arrow::Array#compact here. 2.7.6 and 3.1.2 is OK.
        remove_all_values
      else
        raise DataFrameArgumentError, "invalid arguments: #{args}"
      end
    end

    # Select records by a column specified by a key
    # and corresponding record with a block.
    #
    # @overload slice_by(key)
    #   Select records by elements.
    #
    #   @param key [Symbol, String]
    #     a key to select column.
    #   @param keep_key [true, false]
    #     preserve column specified by key in the result if true.
    #   @yield [self]
    #     gives self to the block.
    #     The block is evaluated within the context of self.
    #   @yieldparam self [DataFrame]
    #     self. Usually, it can be omitted.
    #   @yieldreturn [<elements>]
    #     array of elements to select.
    #   @return [DataFrame]
    #     selected records as a DataFrame.
    #   @example Select records by elements
    #     df
    #
    #     # =>
    #     #<RedAmber::DataFrame : 5 x 3 Vectors, 0x0000000000069e60>
    #         index    float string
    #       <uint8> <double> <string>
    #     0       0      0.0 A
    #     1       1      1.1 B
    #     2       2      2.2 C
    #     3       3      NaN D
    #     4   (nil)    (nil) (nil)
    #
    #     df.slice_by(:string) { ["A", "C"] }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 2 x 2 Vectors, 0x000000000001b1ac>
    #         index    float
    #       <uint8> <double>
    #     0       0      0.0
    #     1       2      2.2
    #
    # @overload slice_by(key)
    #   Select records by elements range.
    #
    #   @param key [Symbol, String]
    #     a key to select column.
    #   @param keep_key [true, false]
    #     preserve column specified by key in the result if true.
    #   @yield [self]
    #     gives self to the block.
    #     The block is evaluated within the context of self.
    #   @yieldparam self [DataFrame]
    #     self. Usually, it can be omitted.
    #   @yieldreturn [Range]
    #     specifies position of elements at the start and the end and
    #     select records between them.
    #   @return [DataFrame]
    #     selected records as a DataFrame.
    #   @example Select records by elements range
    #     df.slice_by(:string) { "A".."C" }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000069668>
    #         index    float
    #       <uint8> <double>
    #     0       0      0.0
    #     1       1      1.1
    #     2       2      2.2
    #
    # @since 0.2.1
    #
    def slice_by(key, keep_key: false, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?
      raise DataFrameArgumentError, 'No block given' unless block
      raise DataFrameArgumentError, "#{key} is not a key of self" unless key?(key)
      return self if key.nil?

      slicer = instance_eval(&block)
      return DataFrame.new unless slicer

      if slicer.is_a?(Range)
        from = slicer.begin
        from =
          if from.is_a?(String)
            self[key].index(from)
          elsif from.nil?
            0
          elsif from < 0
            size + from
          else
            from
          end
        to = slicer.end
        to =
          if to.is_a?(String)
            self[key].index(to)
          elsif to.nil?
            size - 1
          elsif to < 0
            size + to
          else
            to
          end
        slicer = (from..to).to_a
      else
        slicer = slicer.map { |x| x.is_a?(String) ? self[key].index(x) : x }
      end

      taken = take(normalize_indices(Arrow::Array.new(slicer)))
      keep_key ? taken : taken.drop(key)
    end

    # Select records by filtering with booleans to create a DataFrame.
    #
    # @overload filter(booleans)
    #   Select records by filtering with booleans and return a DataFrame.
    #
    #   @param booleans [<Boolean, nil>, Vector, Arrow::Array]
    #     a boolean filter.
    #   @return [DataFrame]
    #     filtered records as a DataFrame.
    #   @example Filter by boolean Vector
    #     penguins
    #
    #     # =>
    #     #<RedAmber::DataFrame : 344 x 8 Vectors, 0x00000000000039bc>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #       4 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     341 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #     342 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #     343 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    #     penguins.filter(penguins.bill_length_mm < 50)
    #
    #     # =>
    #     #<RedAmber::DataFrame : 285 x 8 Vectors, 0x00000000000101a8>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       4 Adelie   Torgersen           39.3          20.6               190 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     282 Gentoo   Biscoe              46.8          14.3               215 ...     2009
    #     283 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #     284 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    # @overload filter
    #   Select records by filtering with block and return a DataFrame.
    #
    #   @yield [self]
    #     gives self to the block.
    #     The block is evaluated within the context of self.
    #   @yieldparam self [DataFrame]
    #     self. Usually, it can be omitted.
    #   @yieldreturn [<Boolean, nil>, Vector, Arrow::Array]
    #     a boolean filter. `Vector` or `Arrow::Array` must be boolean type.
    #   @return [DataFrame]
    #     filtered records as a DataFrame.
    #   @example Filter by boolean Vector
    #     penguins.filter { bill_length_mm < 50 }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 285 x 8 Vectors, 0x00000000000101bc>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       4 Adelie   Torgersen           39.3          20.6               190 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     282 Gentoo   Biscoe              46.8          14.3               215 ...     2009
    #     283 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #     284 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    def filter(*booleans, &block)
      booleans.flatten!
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?

      if block
        unless booleans.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and block.'
        end

        booleans = [instance_eval(&block)]
      end

      case booleans
      in [] | [[]]
        return remove_all_values
      in [Vector => v] if v.boolean?
        filter_by_array(v.data)
      in [Arrow::ChunkedArray => ca] if ca.boolean?
        filter_by_array(ca)
      in [Arrow::BooleanArray => b]
        filter_by_array(b)
      else
        a = Arrow::Array.new(parse_args(booleans, size))
        unless a.boolean?
          raise DataFrameArgumentError, "not a boolean filter: #{booleans}"
        end

        filter_by_array(a)
      end
    end

    # Select records and remove them to create a remainer DataFrame.
    #
    # @overload remove(row)
    #   Select a record and remove it to create a remainer DataFrame.
    #   - The order of records in self will be preserved.
    #
    #   @param row [Indeger, Float]
    #     a row index to remove.
    #   @return [DataFrame]
    #     remainer variables as a DataFrame.
    #   @example Remove a row
    #     penguins.remove(-1)
    #
    #     # =>
    #     #<RedAmber::DataFrame : 343 x 8 Vectors, 0x0000000000010310>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #       4 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     340 Gentoo   Biscoe              46.8          14.3               215 ...     2009
    #     341 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #     342 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #
    # @overload remove(rows)
    #   Select records and remove them to create a remainer DataFrame.
    #   - Duplicated selection is acceptable.
    #   - The order of records in self will be preserved.
    #
    #   @param rows [<Integer>, <Float>, Range<Integer>, Vector, Arrow::Array]
    #     row indeces to remove.
    #   @return [DataFrame]
    #     remainer variables as a DataFrame.
    #   @example Remove rows
    #     penguins.remove(100..200)
    #
    #     # =>
    #     #<RedAmber::DataFrame : 243 x 8 Vectors, 0x0000000000010450>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #       4 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     240 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #     241 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #     242 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    # @overload remove
    #   Select records by indices from block
    #   and remove them to create a remainer DataFrame.
    #   - Duplicated selection is acceptable.
    #   - The order of records in self will be preserved.
    #
    #   @yield [self]
    #     gives self to the block.
    #     The block is evaluated within the context of self.
    #   @yieldparam self [DataFrame]
    #     self. Usually, it can be omitted.
    #   @yieldreturn [<Integer, Float>, Range<Integer>, Vector, Arrow::Array]
    #     row indeces to remove.
    #   @return [DataFrame]
    #     remainer variables as a DataFrame.
    #   @example Remove rows by indices from block
    #     penguins.remove { 0.step(size, 10) }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 309 x 8 Vectors, 0x00000000000104c8>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       1 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       2 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
    #       3 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       4 Adelie   Torgersen           39.3          20.6               190 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     306 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #     307 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #     308 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    # @overload remove(booleans)
    #   Select records by filtering with booleans and return a DataFrame.
    #   - The order of records in self will be preserved.
    #
    #   @param booleans [<Boolean, nil>, Vector, Arrow::Array]
    #     a boolean filter to remove.
    #   @return [DataFrame]
    #     remainer records as a DataFrame.
    #   @example Remove rows by boolean filter
    #     penguins.remove(penguins.bill_length_mm.is_nil)
    #
    #     # =>
    #     #<RedAmber::DataFrame : 342 x 8 Vectors, 0x0000000000010234>
    #         species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #       0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #       1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #       2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #       3 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #       4 Adelie   Torgersen           39.3          20.6               190 ...     2007
    #       : :        :                      :             :                 : ...        :
    #     339 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #     340 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #     341 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    # @overload remove
    #   Select records by booleans from block
    #   and remove them to create a remainer DataFrame.
    #   - The order of records in self will be preserved.
    #
    #   @yield [self]
    #     gives self to the block.
    #     The block is evaluated within the context of self.
    #   @yieldparam self [DataFrame]
    #     self. Usually, it can be omitted.
    #   @yieldreturn [<Boolean, nil>, Vector, Arrow::Array]
    #     a boolean filter to remove. `Vector` or `Arrow::Array` must be boolean type.
    #   @return [DataFrame]
    #     remainer records as a DataFrame.
    #   @example Remove rows by booleans from block
    #     penguins.remove { (species == 'Adelie') | (year == 2009) }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 124 x 8 Vectors, 0x00000000000102fc>
    #         species   island   bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #         <string>  <string>       <double>      <double>           <uint8> ... <uint16>
    #       0 Chinstrap Dream              46.5          17.9               192 ...     2007
    #       1 Chinstrap Dream              50.0          19.5               196 ...     2007
    #       2 Chinstrap Dream              51.3          19.2               193 ...     2007
    #       3 Chinstrap Dream              45.4          18.7               188 ...     2007
    #       4 Chinstrap Dream              52.7          19.8               197 ...     2007
    #       : :         :                     :             :                 : ...        :
    #     121 Gentoo    Biscoe             51.1          16.3               220 ...     2008
    #     122 Gentoo    Biscoe             45.2          13.8               215 ...     2008
    #     123 Gentoo    Biscoe             45.2          16.4               223 ...     2008
    #
    def remove(*args, &block)
      raise DataFrameArgumentError, 'Self is an empty dataframe' if empty?

      if block
        unless args.empty?
          raise DataFrameArgumentError, 'Must not specify both arguments and block.'
        end

        args = [instance_eval(&block)]
      end

      arrow_array =
        case args
        in [] | [[]] | [nil]
          return self
        in [Vector => v]
          v.data
        in [(Arrow::Array | Arrow::ChunkedArray) => aa]
          aa
        else
          Arrow::Array.new(parse_args(args, size))
        end

      if arrow_array.boolean?
        filter_by_array(arrow_array.primitive_invert)
      elsif arrow_array.numeric?
        remover = normalize_indices(arrow_array).to_a
        return self if remover.empty?

        slicer = indices.to_a - remover.map(&:to_i)
        return remove_all_values if slicer.empty?

        take(slicer)
      else
        raise DataFrameArgumentError, "Invalid argument #{args}"
      end
    end

    # Remove records (rows) contains any nil.
    #
    # @return [DataFrame]
    #   removed DataFrame.
    # @example
    #   penguins.remove_nil
    #   # =>
    #   #<RedAmber::DataFrame : 333 x 8 Vectors, 0x00000000000039d0>
    #       species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    #       <string> <string>        <double>      <double>           <uint8> ... <uint16>
    #     0 Adelie   Torgersen           39.1          18.7               181 ...     2007
    #     1 Adelie   Torgersen           39.5          17.4               186 ...     2007
    #     2 Adelie   Torgersen           40.3          18.0               195 ...     2007
    #     3 Adelie   Torgersen           36.7          19.3               193 ...     2007
    #     4 Adelie   Torgersen           39.3          20.6               190 ...     2007
    #     : :        :                      :             :                 : ...        :
    #   330 Gentoo   Biscoe              50.4          15.7               222 ...     2009
    #   331 Gentoo   Biscoe              45.2          14.8               212 ...     2009
    #   332 Gentoo   Biscoe              49.9          16.1               213 ...     2009
    #
    def remove_nil
      func = Arrow::Function.find(:drop_null)
      DataFrame.create(func.execute([table]).value)
    end
    alias_method :drop_nil, :remove_nil

    # Select records from the top.
    #
    # @param n_obs [Integer]
    #   number of records to select.
    # @return [DataFrame]
    #
    def head(n_obs = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_obs}" if n_obs.negative?

      self[0...[n_obs, size].min]
    end

    # Select records from the end.
    #
    # @param n_obs [Integer]
    #   number of records to select.
    # @return [DataFrame]
    #
    def tail(n_obs = 5)
      raise DataFrameArgumentError, "Index is out of range #{n_obs}" if n_obs.negative?

      self[-[n_obs, size].min..]
    end

    # Select records from the top.
    #
    # @param n_obs [Integer]
    #   number of records to select.
    # @return [DataFrame]
    #
    def first(n_obs = 1)
      head(n_obs)
    end

    # Select records from the end.
    #
    # @param n_obs [Integer]
    #   number of records to select.
    # @return [DataFrame]
    #
    def last(n_obs = 1)
      tail(n_obs)
    end

    # Select records by index Array to create a DataFrame.
    #
    # - TODO: support for option `boundscheck: true`
    # - Supports indices in an Arrow::UInt8, UInt16, Uint32, Uint64 or an Array
    # - Negative index is not supported.
    # @param index_array [<Integer>, Arrow::Array]
    #   row indeces to select.
    # @return [DataFrame]
    #   selected variables as a DataFrame.
    #
    # @api private
    #
    def take(index_array)
      DataFrame.create(@table.take(index_array))
    end

    # rubocop:enable Layout/LineLength

    private

    def select_variables_by_keys(keys)
      if keys.one?
        key = keys[0].to_sym
        raise DataFrameArgumentError, "Key does not exist: #{key}" unless key? key

        variables[key]
        # Vector.new(@table.find_column(*key).data)
      else
        check_duplicate_keys(keys)
        DataFrame.create(@table.select_columns(*keys))
      end
    end

    # Accepts indices by numeric arrow array and returns positive indices.
    def normalize_indices(arrow_array)
      b = Arrow::Function.find(:less).execute([arrow_array, 0])
      a = Arrow::Function.find(:add).execute([arrow_array, size])
      r = Arrow::Function.find(:if_else).execute([b, a, arrow_array]).value
      if r.float?
        r = Arrow::Function.find(:floor).execute([r]).value
        Arrow::UInt64ArrayBuilder.build(r)
      else
        r
      end
    end

    # Accepts booleans by a Arrow::BooleanArray or an Array
    def filter_by_array(boolean_array)
      unless boolean_array.length == size
        raise DataFrameArgumentError, 'Booleans must be same size as self.'
      end

      datum = Arrow::Function.find(:filter).execute([table, boolean_array])
      DataFrame.create(datum.value)
    end

    # return a DataFrame with same keys as self without values
    def remove_all_values
      filter_by_array(Arrow::BooleanArray.new([false] * size))
    end
  end
end
