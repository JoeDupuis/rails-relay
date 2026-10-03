require "test_helper"
require "capybara/cuprite"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)
WebMock.globally_stub_request(:after_local_stubs) do |request|
  if request.method == :get && request.uri.to_s.start_with?("#{Rails.configuration.irc_service_url}/internal/irc/ison")
    { status: 200, body: { online: [] }.to_json, headers: { "Content-Type" => "application/json" } }
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Capybara.test_id = "data-qa"
  Capybara.add_selector(:test_id) do
    xpath do |locator|
      XPath.descendant[XPath.attr(Capybara.test_id) == locator]
    end
  end

  driven_by :cuprite, using: :chrome, screen_size: [ 1400, 1400 ], options: {
    headless: true,
    process_timeout: 20
  }
end
