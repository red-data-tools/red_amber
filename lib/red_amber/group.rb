# frozen_string_literal: true

module RedAmber
  # group class
  class Group
    def initialize(dataframe, *group_keys)
      @dataframe = dataframe
      @table = @dataframe.table
      @group_keys = group_keys.flatten

      raise GroupArgumentError, 'group_keys is empty.' if @group_keys.empty?

      d = @group_keys - @dataframe.keys
      raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}." unless d.empty?

      @group = @table.group(*@group_keys)
    end

    def count(*summary_keys)
      by(:count, summary_keys)
    end

    def sum(*summary_keys)
      by(:sum, summary_keys)
    end

    def product(*summary_keys)
      by(:product, summary_keys)
    end

    def mean(*summary_keys)
      by(:mean, summary_keys)
    end

    def min(*summary_keys)
      by(:min, summary_keys)
    end

    def max(*summary_keys)
      by(:max, summary_keys)
    end

    def stddev(*summary_keys)
      by(:stddev, summary_keys)
    end

    def variance(*summary_keys)
      by(:variance, summary_keys)
    end

    private

    def by(func, summary_keys)
      summary_keys = Array(summary_keys).flatten
      d = summary_keys - @dataframe.keys
      raise GroupArgumentError, "#{d} is not a key of\n #{@dataframe}." unless summary_keys.empty? || d.empty?

      RedAmber::DataFrame.new(@group.send(func, *summary_keys))
    end
  end
end
