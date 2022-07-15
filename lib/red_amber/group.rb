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

    def by(func, *target_keys)
      target_keys = Array(target_keys).flatten
      RedAmber::DataFrame.new(@group.send(func, *target_keys))
    end
  end
end
