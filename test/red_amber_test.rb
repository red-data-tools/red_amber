# frozen_string_literal: true

require "test_helper"

class RedAmberTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::RedAmber.const_defined?(:VERSION)
    end
  end

  test "something useful" do
    assert_equal("expected", "actual")
  end
end
