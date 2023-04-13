# frozen_string_literal: true

module RedAmber
  # Mix-in for the class DataFrame
  module Helper
    private

    # If num is larger than 1 return 's' to be plural.
    #
    # @param num [Numeric]
    #   some number.
    # @return ['s', '']
    #   return 's' if num is larger than 1.
    #   Otherwise return ''.
    #
    def pl(num)
      num > 1 ? 's' : ''
    end

    # Parse the argments in an Array and returns a parsed Array.
    #
    # @param args
    #   [<Integer, Symbol, true, false, nil, Array, Range, Enumerator, String, Float>]
    #   arguments.
    # @param array_size [Integer]
    #   size of target Array to use in a endless Range.
    # @return [<Integer, Symbol, true, false, nil>]
    #   parsed flat Array.
    # @note This method is recursively called to parse.
    #
    def parse_args(args, array_size, symbolize: true)
      args.flat_map do |elem|
        case elem
        when Integer, Symbol, NilClass, TrueClass, FalseClass
          elem
        when Array
          parse_args(elem, array_size, symbolize: symbolize)
        when Range
          parse_range(elem, array_size)
        when Enumerator
          parse_args(Array(elem), array_size, symbolize: symbolize)
        when String
          symbolize ? elem.to_sym : elem
        when Float
          elem.floor.to_i
        else
          Array(elem)
        end
      end
    end

    # Parse a Range to an Array
    #
    # @param range [Range]
    #   range to parse.
    # @param array_size [Integer]
    #   size of target Array to use in a endless Range.
    # @return [Array<Integer, Symbol, String>]
    #   parsed Array.
    #
    def parse_range(range, array_size)
      bg = range.begin
      en = range.end
      if [bg, en].any?(Integer)
        bg += array_size if bg&.negative?
        en += array_size if en&.negative?
        en -= 1 if en.is_a?(Integer) && range.exclude_end?
        if bg&.negative? || (en && en >= array_size)
          raise IndexError, "Index out of range: #{range} for 0..#{array_size - 1}"
        end

        Array(0...array_size)[range]
      elsif bg.nil?
        raise DataFrameArgumentError, "Cannot use beginless Range: #{range}"
      elsif en.nil?
        raise DataFrameArgumentError, "Cannot use endless Range: #{range}"
      else
        Array(range)
      end
    end

    # Create sink node and execute plan
    #
    # @param plan [Arrow::ExecutePlan]
    #   Execute plan of Acero.
    # @param node [Arrow::ExecuteNode]
    #   Execute node of Acero.
    # @param output_schema [Arrow::Schema, nil]
    #   Schema of table to output. If it is nil, output_schema of
    #   sink node is used.
    # @return [Arrow::Table]
    #   Result of plan.
    # @since 0.5.0
    #
    def sink_and_start_plan(plan, node, output_schema: nil)
      sink_node_options = Arrow::SinkNodeOptions.new
      plan.build_sink_node(node, sink_node_options)
      plan.validate
      plan.start
      plan.wait
      output_schema = node.output_schema if output_schema.nil?
      reader = sink_node_options.get_reader(output_schema)
      table = reader.read_all
      plan.stop
      table
    end
  end

  # rubocop:disable Layout/LineLength

  # Helper for Arrow Functions
  module ArrowFunction
    module_function

    # Find Arrow's compute function.
    #
    # {https://arrow.apache.org/docs/cpp/compute.html}
    # @param function_name [Symbol]
    #   function name.
    # @return [Arrow::Function]
    #   arrow compute function object.
    # @example
    #   RedAmber::ArrowFunction.find(:array_sort_indices)
    #
    #   # =>
    #   #<Arrow::Function:0x7fa8838a0d80 ptr=0x7fa87e9b7320 array_sort_indices(array, {order=Ascending, null_placement=AtEnd}): Return the indices that would sort an array>
    #
    def find(function_name)
      Arrow::Function.find(function_name)
    end

    # Show document of Arrow's compute function.
    #
    # @param function_name [Symbol]
    #   function name.
    # @return [String]
    #   document of compute function object.
    # @example
    #   puts RedAmber::ArrowFunction.arrow_doc(:array_sort_indices)
    #
    #   # =>
    #   array_sort_indices(array, {order=Ascending, null_placement=AtEnd}): Return the indices that would sort an array
    #   ------------------
    #   This function computes an array of indices that define a stable sort
    #   of the input array.  By default, Null values are considered greater
    #   than any other value and are therefore sorted at the end of the array.
    #   For floating-point types, NaNs are considered greater than any
    #   other non-null value, but smaller than null values.
    #
    #   The handling of nulls and NaNs can be changed in ArraySortOptions.
    #
    def arrow_doc(function_name)
      f = find(function_name)
      "#{f}\n#{'-' * function_name.size}\n#{f.doc.description}"
    end
  end

  # rubocop:enable Layout/LineLength
end
