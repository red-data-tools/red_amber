# frozen_string_literal: true

module RedAmber
  # group class
  class Group
    include Enumerable # This feature is experimental

    # Creates a new Group object.
    #
    # @param dataframe [DataFrame] dataframe to be grouped.
    # @param group_keys [Array<>] keys for grouping.
    def initialize(dataframe, *group_keys)
      @dataframe = dataframe
      @group_keys = group_keys.flatten

      raise GroupArgumentError, 'group_keys are empty.' if @group_keys.empty?

      d = @group_keys - @dataframe.keys
      raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}." unless d.empty?

      @filters = @group_counts = @base_table = nil
      @group = @dataframe.table.group(*@group_keys)
    end

    attr_reader :dataframe, :group_keys

    functions = %i[count sum product mean min max stddev variance]
    functions.each do |function|
      define_method(function) do |*summary_keys|
        summary_keys = Array(summary_keys).flatten
        d = summary_keys - @dataframe.keys
        raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}." unless summary_keys.empty? || d.empty?

        table = @group.aggregate(*build_aggregation_keys("hash_#{function}", summary_keys))
        df = DataFrame.create(table)
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

    def each
      filters
      return enum_for(:each) unless block_given?

      @filters.each do |filter|
        yield @dataframe[filter]
      end
      @filters.size
    end

    def group_count
      DataFrame.create(add_columns_to_table(base_table, [:group_count], [group_counts]))
    end

    def inspect
      "#<#{self.class} : #{format('0x%016x', object_id)}>\n#{group_count}"
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

    # @group_counts.sum == @dataframe.size
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
