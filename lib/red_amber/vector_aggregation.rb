# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # Representing a series of data.
  class Vector
    class << self
      private

      def define_unary_aggregation(function)
        define_method(function) do |**options|
          datum = exec_func_unary(function, options)
          get_scalar(datum)
        end
      end
    end

    # [Unary aggregations]: vector.func => scalar

    define_unary_aggregation(:all)
    alias_method :all?, :all

    define_unary_aggregation(:any)
    alias_method :any?, :any

    define_unary_aggregation(:approximate_median)
    alias_method :median, :approximate_median

    define_unary_aggregation(:count)

    define_unary_aggregation(:count_distinct)
    alias_method :count_uniq, :count_distinct

    define_unary_aggregation(:max)

    define_unary_aggregation(:mean)

    define_unary_aggregation(:min)

    define_unary_aggregation(:min_max)

    define_unary_aggregation(:product)

    define_unary_aggregation(:stddev)

    def sd
      stddev(ddof: 1)
    end
    alias_method :std, :sd

    define_unary_aggregation(:sum)
    define_unary_aggregation(:variance)

    def unbiased_variance
      variance(ddof: 1)
    end
    alias_method :var, :unbiased_variance

    # Return quantile
    #   0.5 quantile (median) is returned by default.
    #   Or return quantile for specified probability (prob).
    #   If quantile lies between two data points, interpolated value is
    #   returned based on selected interpolation method.
    #   Nils and NaNs are ignored.
    #   Nil is returned if there are no valid data point.
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
    # @return [Float] quantile.
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
