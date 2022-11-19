# frozen_string_literal: true

module RedAmber
  # Add additional capabilities to Hash for RedAmber
  module RefineHash
    refine Hash do
      # Convert self to an Arrow::Table
      def to_arrow
        Arrow::Table.new(self)
      end
    end
  end
end
