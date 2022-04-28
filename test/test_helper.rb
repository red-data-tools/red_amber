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
end
