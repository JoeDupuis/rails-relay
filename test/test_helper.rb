ENV["RAILS_ENV"] ||= "test"
ENV["INTERNAL_API_SECRET"] ||= "test_internal_api_secret"

require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "minitest/mock"
require "turbo/broadcastable/test_helper"

module ActiveSupport
  class TestCase
    include SessionTestHelper
    include ActiveJob::TestHelper
    include Turbo::Broadcastable::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
