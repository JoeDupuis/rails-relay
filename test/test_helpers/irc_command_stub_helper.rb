module IrcCommandStubHelper
  def stub_irc_command
    stub_request(:post, "#{Rails.configuration.irc_service_url}/internal/irc/commands")
      .to_return do |request|
        body = JSON.parse(request.body)
        message = body.dig("params", "message")
        parts = message ? [ message ] : true
        { status: 202, body: { parts: parts }.to_json, headers: { "Content-Type" => "application/json" } }
      end
  end
end
