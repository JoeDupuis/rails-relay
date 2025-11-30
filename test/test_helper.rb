ENV["RAILS_ENV"] ||= "test"
ENV["INTERNAL_API_SECRET"] ||= "test_internal_api_secret"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      User.find_each do |user|
        TenantRecord.create_tenant(user.id.to_s, if_not_exists: true)
      end
    end
  end
end
