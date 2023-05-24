# frozen_string_literal: true

require 'arrow'

require_relative 'red_amber/refinements'
require_relative 'red_amber/helper'

require_relative 'red_amber/data_frame_combinable'
require_relative 'red_amber/data_frame_displayable'
require_relative 'red_amber/data_frame_indexable'
require_relative 'red_amber/data_frame_loadsave'
require_relative 'red_amber/data_frame_reshaping'
require_relative 'red_amber/data_frame_selectable'
require_relative 'red_amber/data_frame_variable_operation'
require_relative 'red_amber/data_frame'
require_relative 'red_amber/group'
require_relative 'red_amber/subframes'
require_relative 'red_amber/vector_aggregation'
require_relative 'red_amber/vector_binary_element_wise'
require_relative 'red_amber/vector_selectable'
require_relative 'red_amber/vector_string_function'
require_relative 'red_amber/vector_unary_element_wise'
require_relative 'red_amber/vector_updatable'
require_relative 'red_amber/vector'
require_relative 'red_amber/version'

module RedAmber
  # Generic error
  class Error < StandardError; end

  # Argument error in DataFrame
  class DataFrameArgumentError < ArgumentError; end
  # Data type error in DataFrame
  class DataFrameTypeError < TypeError; end

  # Argument error in Vector
  class VectorArgumentError < ArgumentError; end
  # Data type error in DataFrame
  class VectorTypeError < TypeError; end

  # Argument error in Group
  class GroupArgumentError < ArgumentError; end

  # Argument error in SubFrames
  class SubFramesArgumentError < ArgumentError; end
end
