# frozen_string_literal: true

require 'arrow'

require 'red_amber/data_frame_output'
require 'red_amber/data_frame_selectable'
require 'red_amber/data_frame'
require 'red_amber/vector_functions'
require 'red_amber/vector'
require 'red_amber/version'

module RedAmber
  class Error < StandardError; end

  class DataFrameArgumentError < ArgumentError; end
  class DataFrameTypeError < TypeError; end
end
