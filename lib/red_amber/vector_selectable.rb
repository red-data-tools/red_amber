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

    # @param values [Array, Arrow::Array, Vector]
    def is_in(*values)
      self_data = chunked? ? data.pack : data

      array =
        case values
        in [Vector] | [Arrow::Array] | [Arrow::ChunkedArray]
          values[0].to_a
        else
          Array(values).flatten
        end

      Vector.create(self_data.is_in(array))
    end

    # Arrow's support required
    def index(element)
      to_a.index(element)
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

    # Returns numerical rank of self.
    # - Nil values are considered greater than any value.
    # - NaN values are considered greater than any value but smaller than nil values.
    # - Tiebreakers are ranked in order of appearance.
    # - `RankOptions` in C++ function is not implemented in C GLib yet.
    #   This method is currently fixed to the default behavior.
    #
    # @return [Vector]
    #   0-based rank of self (0...size in range).
    # @example Rank of float Vector
    #   fv = Vector.new(0.1, nil, Float::NAN, 0.2, 0.1); fv
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=5):0x000000000000c65c>
    #   [0.1, nil, NaN, 0.2, 0.1]
    #
    #   fv.rank
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=5):0x0000000000003868>
    #   [0, 4, 3, 2, 1]
    #
    # @example Rank of string Vector
    #   sv = Vector.new("A", "B", nil, "A", "C"); sv
    #
    #   # =>
    #   #<RedAmber::Vector(:string, size=5):0x0000000000003854>
    #   ["A", "B", nil, "A", "C"]
    #
    #   sv.rank
    #
    #   # =>
    #   #<RedAmber::Vector(:uint64, size=5):0x0000000000003868>
    #   [0, 2, 4, 1, 3]
    #
    # @since 0.4.0
    #
    def rank
      datum = Arrow::Function.find(:rank).execute([data])
      Vector.create(datum.value) - 1
    end

    # Pick up elements at random.
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
    #   Pick up n elements at random.
    #
    #   @param n [Integer]
    #     positive number of elements to pick.
    #     If n is smaller or equal to size, elements are picked by non-repeating.
    #     If n is greater than `size`, elements are picked repeatedly.
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
    #   @example Sample same size of self: every element is picked in random order
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
    #   Pick up elements by proportion `prop` at random.
    #
    #   @param prop [Float]
    #     positive proportion of elements to pick.
    #     Absolute number of elements to pick:`prop*size` is rounded (by `half: :up``).
    #     If prop is smaller or equal to 1.0, elements are picked by non-repeating.
    #     If prop is greater than 1.0, some elements are picked repeatedly.
    #   @return [Vector]
    #     sampled elements.
    #     If picked element is only one, it returns a Vector of size == 1
    #     not a scalar.
    #   @example Sample same size of self: every element is picked in random order
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
          (n_or_prop * size).round
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
