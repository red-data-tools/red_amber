# frozen_string_literal: true

# Namespace of RedAmber
module RedAmber
  # Add additional capabilities to Hash
  module RefineHash
    refine Hash do
      # Convert self to an Arrow::Table
      def to_arrow
        Arrow::Table.new(self)
      end
    end
  end

  # Add additional capabilities to Array-like classes
  module RefineArrayLike
    refine Array do
      def to_arrow_array
        Arrow::Array.new(self)
      end
    end

    refine Range do
      def to_arrow_array
        Arrow::Array.new(Array(self))
      end
    end

    # common methods for Arrow::Array and Arrow::ChunkedArray
    # Refinement#include is deprecated and will be removed in Ruby 3.2
    refine Arrow::Array do
      def to_arrow_array
        self
      end

      def type_class
        value_data_type.class
      end

      def boolean?
        value_data_type.instance_of?(Arrow::BooleanDataType)
      end

      def numeric?
        value_data_type.class < Arrow::NumericDataType
      end

      def float?
        value_data_type.class < Arrow::FloatingPointDataType
      end

      def integer?
        value_data_type.class < Arrow::IntegerDataType
      end

      def list?
        is_a? Arrow::ListArray
      end

      def unsigned_integer?
        value_data_type.instance_of?(Arrow::UInt8DataType) ||
          value_data_type.instance_of?(Arrow::UInt16DataType) ||
          value_data_type.instance_of?(Arrow::UInt32DataType) ||
          value_data_type.instance_of?(Arrow::UInt64DataType)
      end

      def string?
        value_data_type.instance_of?(Arrow::StringDataType)
      end

      def dictionary?
        value_data_type.instance_of?(Arrow::DictionaryDataType)
      end

      def temporal?
        value_data_type.class < Arrow::TemporalDataType
      end

      def primitive_invert
        n = Arrow::Function.find(:is_null).execute([self])
        i = Arrow::Function.find(:if_else).execute([n, false, self])
        Arrow::Function.find(:invert).execute([i]).value
      end
    end

    refine Arrow::ChunkedArray do
      def to_arrow_array
        self
      end

      def type_class
        value_data_type.class
      end

      def boolean?
        value_data_type.instance_of?(Arrow::BooleanDataType)
      end

      def numeric?
        value_data_type.class < Arrow::NumericDataType
      end

      def float?
        value_data_type.class < Arrow::FloatingPointDataType
      end

      def integer?
        value_data_type.class < Arrow::IntegerDataType
      end

      def unsigned_integer?
        value_data_type.instance_of?(Arrow::UInt8DataType) ||
          value_data_type.instance_of?(Arrow::UInt16DataType) ||
          value_data_type.instance_of?(Arrow::UInt32DataType) ||
          value_data_type.instance_of?(Arrow::UInt64DataType)
      end

      def string?
        value_data_type.instance_of?(Arrow::StringDataType)
      end

      def dictionary?
        value_data_type.instance_of?(Arrow::DictionaryDataType)
      end

      def temporal?
        value_data_type.class < Arrow::TemporalDataType
      end

      def list?
        value_type.nick == 'list'
      end

      def primitive_invert
        n = Arrow::Function.find(:is_null).execute([self])
        i = Arrow::Function.find(:if_else).execute([n, false, self])
        Arrow::Function.find(:invert).execute([i]).value
      end
    end
  end

  # Add additional capabilities to Arrow::Table
  module RefineArrowTable
    refine Arrow::Table do
      def keys
        columns.map { |column| column.name.to_sym }
      end

      def key?(key)
        keys.include?(key)
      end
    end
  end

  # Add additional capabilities to Array
  module RefineArray
    refine Array do
      def integer?
        all? { |e| e.is_a?(Integer) } # rubocop:disable Performance/RedundantEqualityComparisonBlock
      end

      def numeric?
        all? { |e| e.is_a?(Numeric) } # rubocop:disable Performance/RedundantEqualityComparisonBlock
      end

      def boolean?
        all? { |e| e.is_a?(TrueClass) || e.is_a?(FalseClass) || e.is_a?(NilClass) }
      end

      def symbol?
        all? { |e| e.is_a?(Symbol) } # rubocop:disable Performance/RedundantEqualityComparisonBlock
      end

      def string?
        all? { |e| e.is_a?(String) } # rubocop:disable Performance/RedundantEqualityComparisonBlock
      end

      def symbol_or_string?
        all? { |e| e.is_a?(Symbol) || e.is_a?(String) }
      end

      # convert booleans to indices
      def booleans_to_indices
        (0...size).select.with_index { |_, i| self[i] }
      end

      # select elements by booleans
      def select_by_booleans(booleans)
        select.with_index { |_, i| booleans[i] }
      end

      # reject elements by booleans
      def reject_by_booleans(booleans)
        reject.with_index { |_, i| booleans[i] }
      end

      # reject elements by indices
      # notice: order by indices is not considered.
      def reject_by_indices(indices)
        reject.with_index { |_, i| indices.include?(i) || indices.include?(i - size) }
      end
    end
  end

  # Add additional capabilities to String
  module RefineString
    refine String do
      def width
        chars
          .partition(&:ascii_only?)
          .map.with_index(1) { |a, i| a.size * i }
          .sum
      end
    end
  end

  private_constant :RefineArray, :RefineArrayLike, :RefineArrowTable,
                   :RefineHash, :RefineString
end
