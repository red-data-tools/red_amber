# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      private

      # @!macro [attach] define_unary_aggregation
      #   [Unary aggregation function] Returns a scalar.
      #
      def define_unary_aggregation(function)
        define_method(function) do |**options|
          datum = exec_func_unary(function, options)
          get_scalar(datum)
        end
      end
    end

    # Not implemented in red-arrow yet:
    # Arrow::Indexoptions, Arrow::ModeOptions, Arrow::TDigestOptions

    # @!macro scalar_aggregate_options
    #   @param skip_nulls [true, false]
    #     If true, nil values are ignored.
    #     Otherwise, if any value is nil, emit nil.
    #   @param min_count [Integer]
    #     if less than this many non-nil values are observed, emit nil.
    #     If skip_nulls is false, this option is not respected.

    # @!macro count_options
    #   @param mode [:only_valid, :only_null, :all]
    #     control count aggregate kernel behavior.
    #     - only_valid: count only non-nil values.
    #     - only_null: count only nil.
    #     - all: count both.

    # @!macro variance_options
    #   @param ddof [0, 1]
    #     Control Delta Degrees of Freedom (ddof) of Variance and Stddev kernel.
    #     The divisor used in calculations is N - ddof, where N is the number
    #     of elements. By default, ddof is zero, and population variance or stddev
    #     is returned.
    #   @macro scalar_aggregate_options

    # Test whether all elements in self are evaluated to true.
    #
    # @!method all(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [true, false]
    #   `all` result of self.
    # @example Default.
    #   Vector.new(true, true, nil).all # => true
    #
    # @example Skip nils.
    #   Vector.new(true, true, nil).all(skip_nulls: false) # => false
    #
    define_unary_aggregation :all
    alias_method :all?, :all

    # Test whether any elements in self are evaluated to true.
    #
    # @!method any(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [true, false]
    #   `any` result of self.
    # @example Default.
    #   Vector.new(true, false, nil).any # => true
    #
    define_unary_aggregation :any
    alias_method :any?, :any

    # Approximate median of a numeric Vector with T-Digest algorithm.
    #
    # @!method approximate_median(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [Float]
    #   median of self.
    #   A nil is returned if there is no valid data point.
    #
    define_unary_aggregation :approximate_median
    alias_method :median, :approximate_median

    # Count the number of nil / non-nil values.
    #
    # @!method count(mode: :non_null)
    # @macro count_options
    # @return [Integer] count of self.
    # @example Count only non-nil (default)
    #   Vector.new(1.0, -2.0, Float::NAN, nil).count # => 3
    #
    # @example Count nil only.
    #   Vector.new(1.0, -2.0, Float::NAN, nil).count(mode: :only_null) # => 1
    #
    # @example Count both non-nil and nil.
    #   Vector.new(1.0, -2.0, Float::NAN, nil).count(mode: :all) # => 4
    #
    define_unary_aggregation :count

    # Count the number of unique values.
    #
    # @!method count_distinct(mode: :only_valid)
    # @macro count_options
    # @return [Integer]
    #   unique count of self.
    # @example
    #   vector = Vector.new(1, 1.0, nil, nil, Float::NAN, Float::NAN)
    #   vector
    #
    #   # =>
    #   #<RedAmber::Vector(:double, size=6):0x000000000000d390>
    #   [1.0, 1.0, nil, nil, NaN, NaN]
    #
    #   # Float::NANs are counted as 1.
    #   vector.count_uniq # => 2
    #
    #   # nils are counted as 1.
    #   vector.count_uniq(mode: :only_null) # => 1
    #
    #   vector.count_uniq(mode: :all) # => 3
    #
    define_unary_aggregation :count_distinct
    alias_method :count_uniq, :count_distinct

    # Compute maximum value of self.
    #
    # @!method max(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [Numeric]
    #   maximum value of self.
    #
    define_unary_aggregation :max

    # Compute mean value of self.
    #
    # @!method mean(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [Numeric]
    #   mean of self.
    #
    define_unary_aggregation :mean

    # Compute minimum value of self.
    #
    # @!method min(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [Numeric]
    #   minimum of self.
    #
    define_unary_aggregation :min

    # Compute the min and max value of self.
    #
    # @!method min_max(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [Array<min, max>]
    #   min and max of self in an Array.
    #
    define_unary_aggregation :min_max

    # Compute the 1 most common values and their respective
    #   occurence counts.
    #
    # @note Self must be a numeric or a boolean Vector.
    # @note ModeOptions are not supported in 0.5.0 .
    #   Only one mode value is returned.
    # @api private
    # @return [Hash{'mode'=>mode, 'count'=>count}]
    #    mode and count of self in an array.
    # @since 0.5.0
    #
    def mode
      datum = find(:mode).execute([data])
      datum.value.to_a.first
    end

    # Compute product value of self.
    #
    # @note Self must be a numeric Vector.
    # @!method product(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [Numeric]
    #   product of self.
    #
    define_unary_aggregation :product

    # Calculate standard deviation of self.
    #
    # @note Self must be a numeric Vector.
    # @!method stddev(ddof: 0, skip_nulls: true, min_count: 1)
    # @macro variance_options
    # @return [Float]
    #   standard deviation of self. Biased (ddof=0) by default.
    #
    define_unary_aggregation :stddev

    # Calculate unbiased standard deviation of self.
    #
    # @note Self must be a numeric Vector.
    # @!method sd(ddof: 1, skip_nulls: true, min_count: 1)
    # @macro variance_options
    # @return [Float]
    #   standard deviation of self. Unviased (ddof=1)by default.
    #
    def sd
      stddev(ddof: 1)
    end
    alias_method :std, :sd

    # Compute sum of self.
    #
    # @note Self must be a numeric Vector.
    # @!method sum(skip_nulls: true, min_count: 1)
    # @macro scalar_aggregate_options
    # @return [Numeric]
    #   sum of self.
    #
    define_unary_aggregation :sum

    # Calculate variance of self.
    #
    # @note Self must be a numeric Vector.
    # @!method variance(ddof: 0, skip_nulls: true, min_count: 1)
    # @macro variance_options
    #
    # @return [Float]
    #   unviased (ddof=1) standard deviation of self by default.
    #
    # @return [Float]
    #   variance of self. Biased (ddof=0) by default.
    #
    define_unary_aggregation :variance

    # Calculate unbiased variance of self.
    #
    # @note self must be a numeric Vector.
    # @!method unbiased_variance(ddof: 1, skip_nulls: true, min_count: 1)
    # @macro variance_options
    # @return [Float]
    #   variance of self. Unviased (ddof=1) by default.
    #
    def unbiased_variance
      variance(ddof: 1)
    end
    alias_method :var, :unbiased_variance

    # @!macro quantile_interpolation
    #   @param interpolation [Symbol]
    #     specifies interpolation method to use,
    #     when the quantile lies between the data i and j.
    #     - Default value is :linear, which returns i + (j - i) * fraction.
    #     - lower: returns i.
    #     - higher: returns j.
    #     - nearest: returns i or j, whichever is closer.
    #     - midpoint: returns (i + j) / 2.

    # Get a non-nil element in self.
    #
    # @return [Object, nil]
    #   first non-nil value detected. If all elements are nil, return nil.
    # @since 0.5.0
    #
    def one
      each.find { !_1.nil? }
    end

    # Returns a quantile value.
    # - 0.5 quantile (median) is returned by default.
    # - Or return quantile for specified probability (prob).
    # - If quantile lies between two data points, interpolated value is
    #   returned based on selected interpolation method.
    # - Nils and NaNs are ignored.
    # - Nil is returned if there are no valid data point.
    #
    # @param prob [Float]
    #   probability.
    # @macro quantile_interpolation
    # @macro scalar_aggregate_options
    # @return [Float]
    #   quantile of self.
    # @example
    #   penguins[:bill_depth_mm].quantile
    #
    #   # =>
    #   17.3 # defaultis prob = 0.5
    #
    def quantile(prob = 0.5, interpolation: :linear, skip_nulls: true, min_count: 0)
      unless (0..1).cover? prob
        raise VectorArgumentError,
              "Invalid: probability #{prob} must be between 0 and 1"
      end

      datum = find(:quantile).execute([data],
                                      q: prob,
                                      interpolation: interpolation,
                                      skip_nulls: skip_nulls,
                                      min_count: min_count)
      datum.value.to_a.first
    end

    # Return quantiles in a DataFrame
    #
    # @param probs [Array]
    #   Array of probabilities. Default probabilities are 0.0, 0.25, 0.5 0.75, 1.0 .
    # @macro quantile_interpolation
    # @macro scalar_aggregate_options
    # @return [DataFrame]
    #   quantiles of self.
    # @example
    #   penguins[:bill_depth_mm].quantiles([0.05, 0.95])
    #
    #   # =>
    #   #<RedAmber::DataFrame : 2 x 2 Vectors, 0x000000000000fb2c>
    #        probs quantiles
    #     <double>  <double>
    #   0     0.05      13.9
    #   1     0.95      20.0
    #
    def quantiles(probs = [0.0, 0.25, 0.5, 0.75, 1.0],
                  interpolation: :linear, skip_nulls: true, min_count: 0)
      if probs.empty? || !probs.all? { |q| (0..1).cover?(q) }
        raise VectorArgumentError, "Invarid probavilities #{probs}"
      end

      DataFrame.new(
        probs: probs,
        quantiles: probs.map do |q|
          quantile(q,
                   interpolation: interpolation, skip_nulls: skip_nulls,
                   min_count: min_count)
        end
      )
    end
  end
end
