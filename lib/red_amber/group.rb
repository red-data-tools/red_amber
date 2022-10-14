# frozen_string_literal: true

module RedAmber
  # group class
  class Group
    # Creates a new Group object.
    #
    # @param dataframe [DataFrame] dataframe to be grouped.
    # @param group_keys [Array<>] keys for grouping.
    def initialize(dataframe, *group_keys)
      @dataframe = dataframe
      @table = @dataframe.table
      @group_keys = group_keys.flatten

      raise GroupArgumentError, 'group_keys are empty.' if @group_keys.empty?

      d = @group_keys - @dataframe.keys
      raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}." unless d.empty?

      @group = @table.group(*@group_keys)
    end

    functions = %i[count sum product mean min max stddev variance]
    functions.each do |function|
      define_method(function) do |*summary_keys|
        summary_keys = Array(summary_keys).flatten
        d = summary_keys - @dataframe.keys
        raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}." unless summary_keys.empty? || d.empty?

        table = @group.aggregate(*build_aggregation_keys("hash_#{function}", summary_keys))
        df = DataFrame.new(table)
        df.pick(@group_keys, df.keys - @group_keys)
      end
    end

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

    def inspect
      tallys = @dataframe.pick(@group_keys).vectors.map.with_object({}) do |v, h|
        h[v.key] = v.tally
      end
      "#<#{self.class}:#{format('0x%016x', object_id)}\n#{tallys}>"
    end

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

    private

    def build_aggregation_keys(function_name, summary_keys)
      if summary_keys.empty?
        [function_name]
      else
        summary_keys.map { |key| "#{function_name}(#{key})" }
      end
    end
  end
end
