# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'red_amber'

require 'pathname'
require 'tempfile'
require 'timeout'
require 'webrick'
require 'zlib'

require 'test-unit'

module Helper
  def entity_path
    (Pathname.new(__dir__) / 'entity').expand_path
  end

  def assert_equal_array_in_delta(expected, actual, delta = 0.001, message = '')
    expected.to_a.zip(actual.to_a) do |e, a|
      assert_in_delta(e, a, delta, message)
    end
  end
end
