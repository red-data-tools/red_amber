# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Mix-in for class Vector
  #   Functions to select some data.
  module VectorSelectable
    using RefineArray
    using RefineArrayLike

    # Select elements in the self by indices.
    #
    # @param indices [Array<Numeric>, Vector]
    #   an array-like of indices.
    # @yieldreturn [Array<Numeric>, Vector]
    #   an array-like of indices from the block.
    # @return [Vector]
    #   vector by selected elements.
    #
    # TODO: support for the option `boundscheck: true`
    def take(*indices, &block)
      if block
        unless indices.empty?
          raise VectorArgumentError, 'Must not specify both arguments and block.'
        end

        indices = [yield]
      end

      vector =
        case indices
        in [Vector => v] if v.numeric?
          return Vector.create(take_by_vector(v))
        in []
          return Vector.new
        in [(Arrow::Array | Arrow::ChunkedArray) => aa]
          Vector.create(aa)
        else
          Vector.new(indices.flatten)
        end

      unless vector.numeric?
        raise VectorArgumentError, "argument must be a integers: #{indices}"
      end

      Vector.create(take_by_vector(vector))
    end

    # Select elements in the self by booleans.
    #
    # @param booleans [Array<true, false, nil>, Vector]
    #   an array-like of booleans.
    # @yieldreturn [Array<true, false, nil>, Vector]
    #   an array-like of booleans from the block.
    # @return [Vector]
    #   vector by selected elements.
    #
    # TODO: support for the option `null_selection_behavior: :drop`
    def filter(*booleans, &block)
      if block
        unless booleans.empty?
          raise VectorArgumentError, 'Must not specify both arguments and block.'
        end

        booleans = [yield]
      end

      case booleans
      in [Vector => v]
        raise VectorTypeError, 'Argument is not a boolean.' unless v.boolean?

        Vector.create(filter_by_array(v.data))
      in [Arrow::BooleanArray => ba]
        Vector.create(filter_by_array(ba))
      in []
        Vector.new
      else
        booleans.flatten!
        a = Arrow::Array.new(booleans)
        if a.boolean?
          Vector.create(filter_by_array(a))
        elsif booleans.compact.empty? # [nil, nil] becomes string array
          Vector.new
        else
          raise VectorTypeError, "Argument is not a boolean: #{booleans}"
        end
      end
    end
    alias_method :select, :filter
    alias_method :find_all, :filter

    # Select elements in the self by indices or booleans.
    #
    # @param args [Array<Numeric, true, false, nil>, Vector]
    #   specifier. Indices or booleans.
    # @yieldparam [Array<Numeric, true, false, nil>, Vector]
    #   specifier. Indices or booleans.
    # @return [scalar, Array]
    #   returns scalar or array.
    #
    def [](*args)
      array =
        case args
        in [Vector => v]
          return scalar_or_array(take_by_vector(v)) if v.numeric?
          return scalar_or_array(filter_by_array(v.data)) if v.boolean?

          raise VectorTypeError, "Argument must be numeric or boolean: #{args}"
        in [Arrow::BooleanArray => ba]
          return scalar_or_array(filter_by_array(ba))
        in []
          return nil
        in [Arrow::Array => arrow_array]
          arrow_array
        in [Range => r]
          Arrow::Array.new(parse_range(r, size))
        else
          Arrow::Array.new(args.flatten)
        end

      return scalar_or_array(filter_by_array(array)) if array.boolean?

      vector = Vector.new(array)
      return scalar_or_array(take_by_vector(vector)) if vector.numeric?

      raise VectorArgumentError, "Invalid argument: #{args}"
    end

    # Check if elements of self are in the other values.
    #
    # @param values [Vector, Array, Arrow::Array, Arrow::ChunkedArray]
    #   values to test existence.
    # @return [Vector]
    #   boolean Vector.
    #
    def is_in(*values)
      enum =
        case values
        in [] | [[]] | [nil] |[[nil]]
          return Vector.new([false] * size)
        in [Vector | Arrow::Array | Arrow::ChunkedArray]
          values[0].each
        else
          parse_args(values, size, symbolize: false)
        end
      enum.filter_map { self == _1 unless _1.nil? }.reduce(&:|)
    end

    # Returns index of first matched position of element in self.
    #
    # @param element
    #   an element of self.
    # @return [integer, nil]
    #   position of element. If it is not found, returns nil.
    #
    def index(element)
      if element.nil?
        datum = find(:is_null).execute([data])
        value = Arrow::Scalar.resolve(true, :boolean)
      else
        datum = data
        value = Arrow::Scalar.resolve(element, type)
      end
      datum = find(:index).execute([datum], value: value)
      index = get_scalar(datum)
      if index.negative?
        nil
      else
        index
      end
    end

    # Returns first element of self.
    #
    # @return
    #   the first element.
    # @since 0.4.1
    #
    def first
      data[0]
    end

    # Returns last element of self.
    #
    # @return
    #   the last element.
    # @since 0.4.1
    #
    def last
      data[-1]
    end

    # Drop nil in self and returns a new Vector as a result.
    #
    # @return [Vector]
    #   a Vector without nils.
    #
    def drop_nil
      datum = find(:drop_null).execute([data])
      Vector.create(datum.value)
    end

    # Arrange values in Vector.
    #
    # @param order [Symbol]
    #   sort order.
    #   - `:+`, `:ascending` or without argument will sort in increasing order.
    #   - `:-` or `:descending` will sort in decreasing order.
    # @return [Vector]
    #   sorted Vector.
    # @example Sort in increasing order (default)
    #   Vector.new(%w[B D A E C]).sort
    #   # same as #sort(:+)
    #   # same as #sort(:ascending)
    #
    #   # =>
    #   #<RedAmber::Vector(:string, size=5):0x000000000000c134>
    #   ["A", "B", "C", "D", "E"]
    #
    # @example Sort in decreasing order
    #   Vector.new(%w[B D A E C]).sort(:-)
    #   # same as #sort(:descending)
    #
    #   # =>
    #   #<RedAmber::Vector(:string, size=5):0x000000000000c148>
    #   ["E", "D", "C", "B", "A"]
    #
    # @since 0.4.0
    #
    def sort(order = :ascending)
      order =
        case order.to_sym
        when :+, :ascending, :increasing
          :ascending
        when :-, :descending, :decreasing
          :descending
        else
          raise VectorArgumentError, "illegal order option: #{order}"
        end
      take(sort_indices(order: order))
    end

    # Returns 1-based numerical rank of self.
    # - Nil values are considered greater than any value.
    # - NaN values are considered greater than any value but smaller than nil values.
    # - Order of each element is considered as ascending by default. It is
    #   changable by the parameter `order = :descending`.
    # - Tiebreakers are ranked in order of appearance by default or
    #   with `tie: :first` option.
    # - Null values (nil and NaN) are placed at end by default.
    #   This behavior can be changed by the option `null_placement: :at_start`.
    #
    # @param order [:ascending, '+', :descending, '-']
    #   the order of the elements should be ranked in.
    #   - :ascending or '+' : rank is computed in ascending order.
    #   - :descending or '-' : rank is computed in descending order.
    # @param tie [:first, :min, :max, :dense]
    #   configure how ties between equal values are handled.
    #   - first: Ranks are assigned in order of when ties appear in the input.
    #   - min: Ties get the smallest possible rank in the sorted order.
    #   - max: Ties get the largest possible rank in the sorted order.
    #   - dense: The ranks span a dense [1, M] interval where M is the number
    #     of distinct values in the input.
    # @param null_placement [:at_end, :at_start]
    #   configure the position of nulls to be located.
    #   Nulls are considered as `NaN < nil`.
    # @return [Vector]
    #   1-based rank in uint64 of self (1..size in range) at maximum.
    # @example Rank of float Vector
    #   float = Vector[1, 0, nil, Float::NAN, Float::INFINITY, -Float::INFINITY, 3, 2]
    #   float
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=8):0x0000000000036858>
    #   [1.0, 0.0, nil, NaN, Infinity, -Infinity, 3.0, 2.0]
    #
    #   float.rank
    #   # or float.rank(:ascending, tie: :first, null_placement: :at_end)
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=8):0x000000000003af84>
    #   [3, 2, 8, 7, 6, 1, 5, 4]
    #
    # @example Rank of string Vector
    #   string = Vector["A", "A", nil, nil, "C", "B"]
    #   string
    #
    #   # =>
    #   #<RedAmber::Vector(:string, size=6):0x000000000003d568>
    #   ["A", "A", nil, nil, "C", "B"]
    #
    #   string.rank
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=6):0x0000000000049bc4>
    #   [1, 2, 5, 6, 4, 3]
    #
    # @example Rank with order = :descending
    #   float.rank(:descending) # or float.rank('-')
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=8):0x000000000006ef00>
    #   [4, 5, 8, 7, 1, 6, 2, 3]
    #
    # @example Rank with tie: :min
    #   string.rank(tie: :min)
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=6):0x000000000007a1d4>
    #   [1, 1, 5, 5, 4, 3]
    #
    # @example Rank with tie: :max
    #   string.rank(tie: :max)
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=6):0x000000000007cba0>
    #   [2, 2, 6, 6, 4, 3]
    #
    # @example Rank with tie: :dense
    #   string.rank(tie: :dense)
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=6):0x0000000000080930>
    #   [1, 1, 4, 4, 3, 2]
    #
    # @example Rank with null_placement: :at_start
    #   float.rank(null_placement: :at_start)
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=8):0x0000000000082104>
    #   [5, 4, 1, 2, 8, 3, 7, 6]
    #
    # @since 0.4.0
    #
    def rank(order = :ascending, tie: :first, null_placement: :at_end)
      func = find(:rank)
      options = func.default_options
      order =
        case order.to_sym
        when :+, :ascending, :increasing
          :ascending
        when :-, :descending, :decreasing
          :descending
        else
          raise VectorArgumentError, "illegal order option: #{order}"
        end
      options.sort_keys = [Arrow::SortKey.resolve('', order)]
      options.tiebreaker = tie
      options.null_placement = null_placement
      Vector.create(func.execute([data], options).value)
    end

    # Pick up elements at random.
    # @note This method requires 'arrow-numo-narray' gem.
    #
    # @overload sample()
    #   Return a randomly selected element.
    #   This is one of an aggregation function.
    #
    #   @return [scalar]
    #     one of an element in self.
    #   @example Sample a element
    #     v = Vector.new('A'..'H'); v
    #
    #     # =>
    #     #<RedAmber::Vector(:string, size=8):0x0000000000011b20>
    #     ["A", "B", "C", "D", "E", "F", "G", "H"]
    #
    #     v.sample
    #
    #     # =>
    #     "C"
    #
    # @overload sample(n)
    #   Select n elements at random.
    #
    #   @param n [Integer]
    #     positive number of elements to select.
    #     If n is smaller or equal to size, elements are selected by non-repeating.
    #     If n is greater than `size`, elements are selected repeatedly.
    #   @return [Vector]
    #     sampled elements.
    #     If n == 1 (in case of `sample(1)`), it returns a Vector of size == 1
    #     not a scalar.
    #   @example Sample Vector in size 1
    #     v.sample(1)
    #
    #     # =>
    #     #<RedAmber::Vector(:string, size=1):0x000000000001a3b0>
    #     ["H"]
    #
    #   @example Sample same size of self: every element is selected in random order
    #     v.sample(8)
    #
    #     # =>
    #     #<RedAmber::Vector(:string, size=8):0x000000000001bda0>
    #     ["H", "D", "B", "F", "E", "A", "G", "C"]
    #
    #   @example Over sampling: "E" and "A" are sampled repeatedly
    #     v.sample(9)
    #
    #     # =>
    #     #<RedAmber::Vector(:string, size=9):0x000000000001d790>
    #     ["E", "E", "A", "D", "H", "C", "A", "F", "H"]
    #
    # @overload sample(prop)
    #   Select elements by proportion `prop` at random.
    #
    #   @param prop [Float]
    #     positive proportion of elements to select.
    #     Absolute number of elements to select:`prop*size` is rounded (by `half: :up`).
    #     If prop is smaller or equal to 1.0, elements are selected by non-repeating.
    #     If prop is greater than 1.0, some elements are selected repeatedly.
    #   @return [Vector]
    #     sampled elements.
    #     If selected element is only one, it returns a Vector of size == 1
    #     not a scalar.
    #   @example Sample same size of self: every element is selected in random order
    #     v.sample(1.0)
    #
    #     # =>
    #     #<RedAmber::Vector(:string, size=8):0x000000000001bda0>
    #     ["D", "H", "F", "C", "A", "B", "E", "G"]
    #
    #   @example 2 times over sampling
    #     v.sample(2.0)
    #
    #     # =>
    #     #<RedAmber::Vector(:string, size=16):0x00000000000233e8>
    #     ["H", "B", "C", "B", "C", "A", "F", "A", "E", "C", "H", "F", "F", "A", ... ]
    #
    #   @example prop less than 1.0
    #     v.sample(0.7)
    #
    #     # =>
    #     # Take (8 * 0.7).truncate => 5 samples
    #     #<RedAmber::Vector(:string, size=5):0x000000000001afe0>
    #     ["C", "A", "E", "H", "D"]
    #
    # @since 0.4.0
    #
    def sample(n_or_prop = nil)
      require 'arrow-numo-narray'

      return nil if size == 0

      n_sample =
        case n_or_prop
        in Integer
          n_or_prop
        in Float
          (n_or_prop * size).truncate
        in nil
          return to_a.sample
        else
          raise VectorArgumentError, "must specify Integer or Float but #{n_or_prop}"
        end
      if n_or_prop < 0
        raise VectorArgumentError, '#sample does not accept negative number.'
      end
      return Vector.new([]) if n_sample == 0

      over_sample = [8 * size, n_sample].max
      over_size = n_sample > size ? n_sample / size * size * 2 : size
      over_vector =
        Vector.create(Numo::UInt32.new(over_size).rand(over_sample).to_arrow_array)
      indices = over_vector.rank.take(*0...n_sample)
      take(indices - ((indices / size) * size))
    end

    private

    # Accepts indices by numeric Vector
    def take_by_vector(indices)
      indices = (indices < 0).if_else(indices + size, indices) if (indices < 0).any?

      min, max = indices.min_max
      raise VectorArgumentError, "Index out of range: #{min}" if min < 0
      raise VectorArgumentError, "Index out of range: #{max}" if max >= size

      index_array =
        if indices.float?
          Arrow::UInt64ArrayBuilder.build(indices.data)
        else
          indices.data
        end

      # :array_take will fail with ChunkedArray
      find(:take).execute([data, index_array]).value
    end

    # Accepts booleans by Arrow::BooleanArray
    def filter_by_array(boolean_array)
      unless boolean_array.length == size
        raise VectorArgumentError, 'Booleans must be same size as self.'
      end

      find(:array_filter).execute([data, boolean_array]).value
    end

    def scalar_or_array(arrow_array)
      a = arrow_array.to_a
      a.size > 1 ? a : a[0]
    end
  end
end
