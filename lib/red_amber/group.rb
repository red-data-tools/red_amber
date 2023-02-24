# frozen_string_literal: true

module RedAmber
  # Group class
  class Group
    include Enumerable # This feature is experimental

    using RefineArrowTable

    attr_reader :dataframe, :group_keys

    class << self
      private

      # @!macro [attach] define_group_aggregation
      #   @!method $1(*summary_keys)
      #     Group aggregation function `$1`.
      #     @param summary_keys [Array<Symbol, String>]
      #       summary keys.
      #     @return [DataFrame]
      #       aggregated DataFrame
      #
      def define_group_aggregation(function)
        define_method(function) do |*summary_keys|
          summary_keys = Array(summary_keys).flatten
          d = summary_keys - @dataframe.keys
          unless summary_keys.empty? || d.empty?
            raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}."
          end

          table = @group.aggregate(*build_aggregation_keys("hash_#{function}",
                                                           summary_keys))
          g = @group_keys.map(&:to_s)
          DataFrame.new(table[g + (table.keys - g)])
        end
      end
    end

    # Creates a new Group object.
    #
    # @param dataframe [DataFrame]
    #   dataframe to be grouped.
    # @param group_keys [Array<Symbol, String>]
    #   keys for grouping.
    # @return [Group]
    #   Group object.
    # @example
    #   Group.new(penguins, :species)
    #
    #   # =>
    #   #<RedAmber::Group : 0x000000000000f410>
    #     species   group_count
    #     <string>      <uint8>
    #   0 Adelie            152
    #   1 Chinstrap          68
    #   2 Gentoo            124
    #
    def initialize(dataframe, *group_keys)
      @dataframe = dataframe
      @group_keys = group_keys.flatten

      raise GroupArgumentError, 'group_keys are empty.' if @group_keys.empty?

      d = @group_keys - @dataframe.keys
      raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}." unless d.empty?

      @group = @dataframe.table.group(*@group_keys)
    end

    define_group_aggregation(:count)
    alias_method :__count, :count
    private :__count

    def count(*summary_keys)
      df = __count(summary_keys)
      # if counts are the same (and do not include NaN or nil), aggregate count columns.
      if df.pick(@group_keys.size..).to_h.values.uniq.size == 1
        df.pick(0..@group_keys.size).rename { [keys[-1], :count] }
      else
        df
      end
    end

    define_group_aggregation(:sum)

    define_group_aggregation(:product)

    define_group_aggregation(:mean)

    define_group_aggregation(:min)

    define_group_aggregation(:max)

    define_group_aggregation(:stddev)

    define_group_aggregation(:variance)

    # Returns Array of boolean filters to select each records in the Group.
    #
    # @api private
    # @return [Array]
    #   an Array of boolean filter Vectors.
    #
    def filters
      @filters ||= begin
        first, *others = @group_keys.map do |key|
          vector = @dataframe[key]
          vector.uniq.each.map { |u| u.nil? ? vector.is_nil : vector == u }
        end

        if others.empty?
          first.select(&:any?)
        else
          first.product(*others).map { |a| a.reduce(&:&) }.select(&:any?)
        end
      end
    end

    # Iterates over each record group as a DataFrame or returns a Enumerator.
    #
    # @api private
    # @overload each
    #   Returns a new Enumerator if no block given.
    #
    #   @return [Enumerator]
    #     Enumerator of each group as a DataFrame.
    #
    # @overload each
    #   When a block given, passes each record group as a DataFrame to the block.
    #
    #   @yield [DataFrame]
    #     each record group
    #   @yieldparam df [DataFrame]
    #     passes each record group as a DataFrame by a block parameter.
    #   @yieldreturn [Object]
    #     evaluated result value from the block.
    #   @return [Integer]
    #     group size.
    #
    def each
      filters
      return enum_for(:each) unless block_given?

      @filters.each do |filter|
        yield @dataframe[filter]
      end
      @filters.size
    end

    # Returns each record group size as a DataFrame.
    #
    # @return [DataFrame]
    #   DataFrame consists of:
    #   - Group key columns.
    #   - Result columns by group aggregation.
    # @example
    #   penguins.group(:species).group_count
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000003a70>
    #     species   group_count
    #     <string>      <uint8>
    #   0 Adelie            152
    #   1 Chinstrap          68
    #   2 Gentoo            124
    #
    def group_count
      DataFrame.create(add_columns_to_table(base_table, [:group_count], [group_counts]))
    end

    # String representation of self.
    #
    # @return [String]
    #   show information of self as a String.
    # @example
    #   puts penguins.group(:species).inspect
    #
    #   # =>
    #   #<RedAmber::Group : 0x0000000000003a98>
    #     species   group_count
    #     <string>      <uint8>
    #   0 Adelie            152
    #   1 Chinstrap          68
    #   2 Gentoo            124
    #
    def inspect
      "#<#{self.class} : #{format('0x%016x', object_id)}>\n#{group_count}"
    end

    # Summarize Group by aggregation functions from the block.
    #
    # @yield [self]
    #   passes self.
    # @yieldparam group [Group]
    #   passes group object self.
    # @yieldreturn [DataFrame, Array<DataFrame>]
    #   an aggregated DataFrame or an array of aggregated DataFrames.
    # @return [DataFrame]
    #   summarized DataFrame.
    # @example Single function and single variable
    #   group = penguins.group(:species)
    #   group
    #
    #   # =>
    #   #<RedAmber::Group : 0x000000000000c314>
    #     species   group_count
    #     <string>      <uint8>
    #   0 Adelie            152
    #   1 Chinstrap          68
    #   2 Gentoo            124
    #
    #   group.summarize { mean(:bill_length_mm) }
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000000c364>
    #     species   mean(bill_length_mm)
    #     <string>              <double>
    #   0 Adelie                   38.79
    #   1 Chinstrap                48.83
    #   2 Gentoo                    47.5
    #
    # @example Single function only
    #   group.summarize { mean }
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 6 Vectors, 0x000000000000c350>
    #     species   mean(bill_length_mm) mean(bill_depth_mm) ... mean(year)
    #     <string>              <double>            <double> ...   <double>
    #   0 Adelie                   38.79               18.35 ...    2008.01
    #   1 Chinstrap                48.83               18.42 ...    2007.97
    #   2 Gentoo                    47.5               14.98 ...    2008.08
    #
    # @example Multiple functions
    #   group.summarize { [min(:bill_length_mm), max(:bill_length_mm)] }
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000c378>
    #     species   min(bill_length_mm) max(bill_length_mm)
    #     <string>             <double>            <double>
    #   0 Adelie                   32.1                46.0
    #   1 Chinstrap                40.9                58.0
    #   2 Gentoo                   40.9                59.6
    #
    def summarize(&block)
      agg = instance_eval(&block)
      case agg
      when DataFrame
        agg
      when Array
        agg.reduce { |aggregated, df| aggregated.assign(df.to_h) }
      else
        raise GroupArgumentError, "Unknown argument: #{agg}"
      end
    end

    # @api private
    def agg_sum(*summary_keys)
      call_aggregating_function(:sum, summary_keys, _options = nil)
    end

    private

    def build_aggregation_keys(function_name, summary_keys)
      if summary_keys.empty?
        [function_name]
      else
        summary_keys.map { |key| "#{function_name}(#{key})" }
      end
    end

    # @note `@group_counts.sum == @dataframe.size``
    def group_counts
      @group_counts ||= filters.map(&:sum)
    end

    def base_table
      @base_table ||= begin
        indexes = filters.map { |filter| filter.index(true) }
        @dataframe.table[@group_keys].take(indexes)
      end
    end

    def add_columns_to_table(table, keys, data_arrays)
      fields = table.schema.fields
      arrays = table.columns.map(&:data)

      keys.zip(data_arrays).each do |key, array|
        data = Arrow::ChunkedArray.new([array])
        fields << Arrow::Field.new(key, data.value_data_type)
        arrays << data
      end

      Arrow::Table.new(Arrow::Schema.new(fields), arrays)
    end

    # Call Vector aggregating function and return an array of arrays:
    #   [keys, data_arrays]
    #   (Experimental feature)
    def call_aggregating_function(func, summary_keys, _options)
      summary_keys.each.with_object([[], []]) do |key, (keys, arrays)|
        vector = @dataframe[key]
        arrays << filters.map { |filter| vector.filter(filter).send(func) }
        keys << "#{func}(#{key})".to_sym
      rescue Arrow::Error::NotImplemented
        # next
      end
    end
  end
end
