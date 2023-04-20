# frozen_string_literal: true

module RedAmber
  # Group class
  class Group
    include Enumerable # This feature is experimental
    include Helper

    using RefineArrowTable

    # Source DataFrame.
    #
    # @return [DataFrame]
    #   source DataFrame.
    #
    attr_reader :dataframe

    # Keys for grouping by value.
    #
    # @return [Array]
    #   group keys.
    #
    attr_reader :group_keys

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
          DataFrame.new(table[@group_keys + (table.keys - @group_keys)])
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
    #     species     count
    #     <string>  <uint8>
    #   0 Adelie        152
    #   1 Chinstrap      68
    #   2 Gentoo        124
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
        keys = group_table.column_names[..-2]
        group_values = group_table.each_record.map { |record| record.to_a[..-2] }

        Enumerator.new(group_table.n_rows) do |yielder|
          group_values.each do |values|
            booleans =
              values.map.with_index do |value, i|
                column = @dataframe[keys[i]].data
                if value.nil?
                  Arrow::Function.find('is_null').execute([column])
                elsif value.is_a?(Float) && value.nan?
                  Arrow::Function.find('is_nan').execute([column])
                else
                  Arrow::Function.find('equal').execute([column, value])
                end
              end
            filter =
              booleans.reduce do |result, datum|
                Arrow::Function.find('and_kleene').execute([result, datum])
              end
            yielder << Vector.create(filter.value)
          end
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
    #   @yieldparam df [DataFrame]
    #     passes each record group as a DataFrame by a block parameter.
    #   @yieldreturn [Object]
    #     evaluated result value from the block.
    #   @return [Integer]
    #     group size.
    #
    def each
      return enum_for(:each) unless block_given?

      filters.each do |filter|
        yield @dataframe.filter(filter)
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
      DataFrame.create(group_table)
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
    # @overload summarize
    #   Summarize by a function.
    #   @yieldparam group [Group]
    #     passes group object self.
    #   @yieldreturn [DataFrame]
    #   @yieldreturn [DataFrame, Array<DataFrame>, Hash{Symbol, String => DataFrame}]
    #     an aggregated DataFrame or an array of aggregated DataFrames.
    #   @return [DataFrame]
    #     summarized DataFrame.
    #   @example Single function and single variable
    #     group = penguins.group(:species)
    #     group
    #
    #     # =>
    #     #<RedAmber::Group : 0x000000000000c314>
    #       species   group_count
    #       <string>      <uint8>
    #     0 Adelie            152
    #     1 Chinstrap          68
    #     2 Gentoo            124
    #
    #     group.summarize { mean(:bill_length_mm) }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000000c364>
    #       species   mean(bill_length_mm)
    #       <string>              <double>
    #     0 Adelie                   38.79
    #     1 Chinstrap                48.83
    #     2 Gentoo                    47.5
    #
    #   @example Single function only
    #     group.summarize { mean }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 6 Vectors, 0x000000000000c350>
    #       species   mean(bill_length_mm) mean(bill_depth_mm) ... mean(year)
    #       <string>              <double>            <double> ...   <double>
    #     0 Adelie                   38.79               18.35 ...    2008.01
    #     1 Chinstrap                48.83               18.42 ...    2007.97
    #     2 Gentoo                    47.5               14.98 ...    2008.08
    #
    # @overload summarize
    #   Summarize by a function.
    #
    #   @yieldparam group [Group]
    #     passes group object self.
    #   @yieldreturn [Array<DataFrame>]
    #     an aggregated DataFrame or an array of aggregated DataFrames.
    #   @return [DataFrame]
    #     summarized DataFrame.
    #   @example Multiple functions
    #     group.summarize { [min(:bill_length_mm), max(:bill_length_mm)] }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000c378>
    #       species   min(bill_length_mm) max(bill_length_mm)
    #       <string>             <double>            <double>
    #     0 Adelie                   32.1                46.0
    #     1 Chinstrap                40.9                58.0
    #     2 Gentoo                   40.9                59.6
    #
    # @overload summarize
    #   Summarize by a function.
    #
    #   @yieldparam group [Group]
    #     passes group object self.
    #   @yieldreturn [Hash{Symbol, String => DataFrame}]
    #     an aggregated DataFrame or an array of aggregated DataFrames.
    #     The DataFrame must return only one aggregated column.
    #   @return [DataFrame]
    #     summarized DataFrame.
    #   @example Rename column name by Hash
    #     group.summarize {
    #       {
    #         min_bill_length_mm: min(:bill_length_mm),
    #         max_bill_length_mm: max(:bill_length_mm),
    #       }
    #     }
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000c378>
    #       species   min_bill_length_mm max_bill_length_mm
    #       <string>            <double>           <double>
    #     0 Adelie                  32.1               46.0
    #     1 Chinstrap               40.9               58.0
    #     2 Gentoo                  40.9               59.6
    #
    def summarize(*args, &block)
      if block
        agg = instance_eval(&block)
        unless args.empty?
          agg = [agg] if agg.is_a?(DataFrame)
          agg = args.zip(agg).to_h
        end
      else
        agg = args
      end

      case agg
      when DataFrame
        agg
      when Array
        aggregations =
          agg.map do |df|
            v = df.vectors[-1]
            [v.key, v]
          end
        agg[0].assign(aggregations)
      when Hash
        aggregations =
          agg.map do |key, df|
            aggregated_keys = df.keys - @group_keys
            if aggregated_keys.size > 1
              message =
                "accept only one column from the Hash: #{aggregated_keys.join(', ')}"
              raise GroupArgumentError, message
            end

            v = df.vectors[-1]
            [key, v]
          end
        agg.values[-1].drop(-1).assign(aggregations)
      else
        raise GroupArgumentError, "Unknown argument: #{agg}"
      end
    end

    # Aggregating summary.
    #
    # @api private
    #
    def agg_sum(*summary_keys)
      call_aggregating_function(:sum, summary_keys, _options = nil)
    end

    private

    def group_table
      @group_table ||= build_aggregated_table
    end

    def build_aggregated_table
      keys = @group_keys
      key = keys[0]
      table = @dataframe.table

      plan = Arrow::ExecutePlan.new
      source_node = plan.build_source_node(table)

      aggregate_node =
        plan.build_aggregate_node(source_node, {
                                    aggregations: [{ function: 'hash_count',
                                                     input: key }], keys: keys
                                  })
      expressions = keys.map { |k| Arrow::FieldExpression.new(k) }
      null_count = Arrow::Function.find('is_null').execute([table[key]]).value.sum
      count_field = Arrow::FieldExpression.new("count(#{key})")
      if null_count.zero?
        expressions << count_field
      else
        is_zero =
          Arrow::CallExpression.new('equal', [count_field, Arrow::Int64Scalar.new(0)])
        null_count_scalar = Arrow::Int64Scalar.new(null_count)
        expressions <<
          Arrow::CallExpression.new('if_else', [
                                      is_zero, null_count_scalar, count_field
                                    ])
      end
      options = Arrow::ProjectNodeOptions.new(expressions, keys << 'group_count')
      project_node = plan.build_project_node(aggregate_node, options)

      sink_and_start_plan(plan, project_node)
    end

    def build_aggregation_keys(function_name, summary_keys)
      if summary_keys.empty?
        [function_name]
      else
        summary_keys.map { |key| "#{function_name}(#{key})" }
      end
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
