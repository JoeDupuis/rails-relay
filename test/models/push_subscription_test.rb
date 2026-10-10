require "test_helper"
require "webmock/minitest"

class PushSubscriptionTest < ActiveSupport::TestCase
  ENDPOINT = "https://push.example.com/send/abc123"

  setup do
    @subscription = users(:joe).push_subscriptions.create!(
      endpoint: ENDPOINT,
      p256dh_key: "BPVlhw23nOgbBx8WsBDlRsSwa81irMttlLOw4q29DG-2vIHzBXNZzbYZpQ9-aWCYDib3PIDpJ8Q0Ol9giHD5boM",
      auth_key: "5vR17us8wBhIdl1G4Zl_IA"
    )
  end

  test "requires an https endpoint" do
    subscription = PushSubscription.new(user: users(:joe), endpoint: "http://internal:3000/x", p256dh_key: "k", auth_key: "a")

    assert_not subscription.valid?
    assert subscription.errors[:endpoint].any?
  end

  test "deliver sends an encrypted push with VAPID auth" do
    stub_request(:post, ENDPOINT).to_return(status: 201)

    @subscription.deliver({ title: "hi" })

    assert_requested(:post, ENDPOINT) do |request|
      request.headers["Content-Encoding"] == "aes128gcm" &&
        request.headers["Authorization"].start_with?("vapid ") &&
        request.headers["Urgency"] == "high"
    end
  end

  test "deliver removes the subscription when the push service says it expired" do
    stub_request(:post, ENDPOINT).to_return(status: 410)

    @subscription.deliver({ title: "hi" })

    assert_not PushSubscription.exists?(@subscription.id)
  end

  test "enabled? is false without VAPID keys" do
    original = Rails.configuration.vapid_private_key
    Rails.configuration.vapid_private_key = nil

    assert_not PushSubscription.enabled?
  ensure
    Rails.configuration.vapid_private_key = original
  end
end
