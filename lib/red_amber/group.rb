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
      #   Returns aggregated DataFrame.
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
    #   Group object. It inspects grouped columns and its count.
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

    # @!macro group_aggregation
    #   @param group_keys [Array<Symbol, String>]
    #     keys for grouping.
    #   @return [DataFrame]
    #     aggregated DataFrame

    # Whether all elements in each group evaluate to true.
    #
    # @!method all(*group_keys)
    #   @macro group_aggregation
    #   @example For boolean columns by default.
    #     dataframe
    #
    #     # =>
    #     #<RedAmber::DataFrame : 6 x 3 Vectors, 0x00000000000230dc>
    #             x y        z
    #       <uint8> <string> <boolean>
    #     0       1 A        false
    #     1       2 A        true
    #     2       3 B        false
    #     3       4 B        (nil)
    #     4       5 B        true
    #     5       6 C        false
    #
    #     dataframe.group(:y).all
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000000fc08>
    #       y        all(z)
    #       <string> <boolean>
    #     0 A        false
    #     1 B        false
    #     2 C        false
    #
    define_group_aggregation :all

    # Whether any elements in each group evaluate to true.
    #
    # @!method any(*group_keys)
    #   @macro group_aggregation
    #   @example For boolean columns by default.
    #     dataframe.group(:y).any
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x00000000000117ec>
    #       y        any(z)
    #       <string> <boolean>
    #     0 A        true
    #     1 B        true
    #     2 C        false
    #
    define_group_aggregation :any

    # Count the number of non-nil values in each group.
    #   If counts are the same (and do not include NaN or nil),
    #   columns for counts are unified.
    #
    # @!method max(*group_keys)
    # @macro group_aggregation
    # @example Show counts for each group.
    #   dataframe.group(:y).count
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000011ea04>
    #     y        count(x) count(z)
    #     <string>  <int64>  <int64>
    #   0 A               2        2
    #   1 B               3        2
    #   2 C               1        1
    #
    #   dataframe.group(:z).count
    #   # same as dataframe.group(:z).count(:x, :y)
    #
    #   =>
    #   #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000122834>
    #     z           count
    #     <boolean> <int64>
    #   0 false           3
    #   1 true            2
    #   2 (nil)           1
    #
    define_group_aggregation :count
    alias_method :__count, :count
    private :__count

    def count(*group_keys)
      df = __count(group_keys)
      if df.pick(@group_keys.size..).to_h.values.uniq.size == 1
        df.pick(0..@group_keys.size).rename { [keys[-1], :count] }
      else
        df
      end
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
    alias_method :count_all, :group_count

    # Count the unique values in each group.
    #
    # @!method count_uniq(*group_keys)
    # @macro group_aggregation
    # @example Show counts for each group.
    #   dataframe.group(:y).count_uniq
    #
    #   # =>
    #   #<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000011ea04>
    #     y        count_uniq(x)
    #     <string>       <int64>
    #   0 A                    2
    #   1 B                    3
    #   2 C                    1
    #
    define_group_aggregation :count_distinct
    def count_uniq(*group_keys)
      df = count_distinct(*group_keys)
      df.rename do
        keys_org = keys.select { _1.start_with?('count_distinct') }
        keys_renamed = keys_org.map { _1.to_s.gsub('distinct', 'uniq') }
        keys_org.zip keys_renamed
      end
    end

    # Compute maximum of values in each group for numeric columns.
    #
    # @!method max(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).max
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000014ae74>
    #       y         max(x)
    #       <string> <uint8>
    #     0 A              2
    #     1 B              5
    #     2 C              6
    #
    define_group_aggregation :max

    # Compute mean of values in each group for numeric columns.
    #
    # @!method mean(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).mean
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000138a8>
    #       y         mean(x)
    #       <string> <double>
    #     0 A             1.5
    #     1 B             4.0
    #     2 C             6.0
    #
    define_group_aggregation :mean

    # Compute median of values in each group for numeric columns.
    #
    # @!method median(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).median
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x0000000000138a8>
    #       y        median(x)
    #       <string>  <double>
    #     0 A              1.5
    #     1 B              4.0
    #     2 C              6.0
    #
    define_group_aggregation :approximate_median
    def median(*group_keys)
      df = approximate_median(*group_keys)
      df.rename do
        keys_org = keys.select { _1.start_with?('approximate_') }
        keys_renamed = keys_org.map { _1.to_s.delete_prefix('approximate_') }
        keys_org.zip keys_renamed
      end
    end

    # Compute minimum of values in each group for numeric columns.
    #
    # @!method min(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).min
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000018f38>
    #       y         min(x)
    #       <string> <uint8>
    #     0 A              1
    #     1 B              3
    #     2 C              6
    #
    define_group_aggregation :min

    # Get one value from each group.
    #
    # @!method one(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).one
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000002885c>
    #       y         one(x)
    #       <string> <uint8>
    #     0 A              1
    #     1 B              3
    #     2 C              6
    #
    define_group_aggregation :one

    # Compute product of values in each group for numeric columns.
    #
    # @!method product(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).product
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000021a84>
    #       y        product(x)
    #       <string>   <uint64>
    #     0 A                 2
    #     1 B                60
    #     2 C                 6
    #
    define_group_aggregation :product

    # Compute standard deviation of values in each group for numeric columns.
    #
    # @!method stddev(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).stddev
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x00000000002be6c>
    #       y        stddev(x)
    #       <string>  <double>
    #     0 A              0.5
    #     1 B            0.082
    #     2 C              0.0
    #
    define_group_aggregation :stddev

    # Compute sum of values in each group for numeric columns.
    #
    # @!method sum(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).sum
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000032a14>
    #       y          sum(x)
    #       <string> <uint64>
    #     0 A               3
    #     1 B              12
    #     2 C               6
    #
    define_group_aggregation :sum

    # Compute variance of values in each group for numeric columns.
    #
    # @!method variance(*group_keys)
    #   @macro group_aggregation
    #   @example
    #     dataframe.group(:y).variance
    #
    #     # =>
    #     #<RedAmber::DataFrame : 3 x 2 Vectors, 0x00000000003b1dc>
    #       y        variance(x)
    #       <string>    <double>
    #     0 A               0.25
    #     1 B              0.067
    #     2 C                0.0
    #
    define_group_aggregation :variance

    # Returns Array of boolean filters to select each records in the Group.
    #
    # @api private
    # @return [Array]
    #   an Array of boolean filter Vectors.
    #
    def filters
      @filters ||= begin
        group_values = group_table[group_keys].each_record.map(&:to_a)

        Enumerator.new(group_table.n_rows) do |yielder|
          group_values.each do |values|
            booleans =
              values.map.with_index do |value, i|
                column = @dataframe[group_keys[i]].data
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

    # Return grouped DataFrame only for group keys.
    #
    # @return [DataFrame]
    #   grouped DataFrame projected only for group_keys.
    # @since 0.5.0
    #
    def grouped_frame
      DataFrame.create(group_table[group_keys])
    end
    alias_method :none, :grouped_frame

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
      options = Arrow::ProjectNodeOptions.new(expressions, keys + [:group_count])
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
        keys << :"#{func}(#{key})"
      rescue Arrow::Error::NotImplemented
        # next
      end
    end
  end
end
