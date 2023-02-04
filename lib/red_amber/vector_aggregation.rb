# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      private

      # @!macro [attach] define_unary_aggregation
      #   @!method $1
      #   [Unary aggregation function] Returns a scalar.
      #
      def define_unary_aggregation(function)
        define_method(function) do |**options|
          datum = exec_func_unary(function, options)
          get_scalar(datum)
        end
      end
    end

    # Test whether all elements in self are evaluated to true.
    #
    # @return [true, false] all? result of self.
    define_unary_aggregation(:all)
    alias_method :all?, :all

    # Test whether any elements in self are evaluated to true.
    #
    # @return [true, false] any? result of self.
    define_unary_aggregation(:any)
    alias_method :any?, :any

    # @return [Float] median of self.
    define_unary_aggregation(:approximate_median)
    alias_method :median, :approximate_median

    # @return [Integer] count of self.
    define_unary_aggregation(:count)

    # @return [Integer] unique count of self.
    define_unary_aggregation(:count_distinct)
    alias_method :count_uniq, :count_distinct

    # @return [Numeric] max of self.
    define_unary_aggregation(:max)

    # @return [Numeric] mean of self.
    define_unary_aggregation(:mean)

    # @return [Numeric] min of self.
    define_unary_aggregation(:min)

    # @return [Array<min, max>] min and max of self in an Array.
    define_unary_aggregation(:min_max)

    # @return [Numeric] product of self.
    define_unary_aggregation(:product)

    # @return [Float] standard deviation of self.
    define_unary_aggregation(:stddev)

    # @return [Float] unviased standard deviation of self.
    def sd
      stddev(ddof: 1)
    end
    alias_method :std, :sd

    # @return [Numeric] sum of self.
    define_unary_aggregation(:sum)

    # @return [Float] variance of self.
    define_unary_aggregation(:variance)

    # @return [Float] unviased variance of self.
    def unbiased_variance
      variance(ddof: 1)
    end
    alias_method :var, :unbiased_variance

    # Returns quantile
    #   - 0.5 quantile (median) is returned by default.
    #   - Or return quantile for specified probability (prob).
    #   - If quantile lies between two data points, interpolated value is
    #     returned based on selected interpolation method.
    #   - Nils and NaNs are ignored.
    #   - Nil is returned if there are no valid data point.
    #
    # @param prob [Float] probability.
    # @param interpolation [Symbol] specifies interpolation method to use,
    #   when the quantile lies between the data i and j.
    #   - Default value is :linear, which returns i + (j - i) * fraction.
    #   - :lower returns i.
    #   - :higher returns j.
    #   - :nearest returns i or j, whichever is closer.
    #   - :midpoint returns (i + j) / 2.
    # @param skip_nils [Boolean] wheather to ignore nil.
    # @param min_count [Integer] min count.
    # @return [Float] quantile of self.
    #
    def quantile(prob = 0.5, interpolation: :linear, skip_nils: true, min_count: 0)
      unless (0..1).cover? prob
        raise VectorArgumentError,
              "Invalid: probability #{prob} must be between 0 and 1"
      end

      datum = find(:quantile).execute([data],
                                      q: prob,
                                      interpolation: interpolation,
                                      skip_nulls: skip_nils,
                                      min_count: min_count)
      datum.value.to_a.first
    end

    # Return quantiles in a DataFrame
    #
    # @return [DataFrame] quantiles of self.
    #
    def quantiles(probs = [1.0, 0.75, 0.5, 0.25, 0.0],
                  interpolation: :linear, skip_nils: true, min_count: 0)
      if probs.empty? || !probs.all? { |q| (0..1).cover?(q) }
        raise VectorArgumentError, "Invarid probavilities #{probs}"
      end

      DataFrame.new(
        probs: probs,
        quantiles: probs.map do |q|
          quantile(q,
                   interpolation: interpolation, skip_nils: skip_nils,
                   min_count: min_count)
        end
      )
    end
  end
end
