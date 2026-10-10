require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joe)
    sign_in_as(@user)
  end

  test "create saves the browser's push subscription" do
    post push_subscriptions_path, params: subscription_params, as: :json

    assert_response :created
    subscription = @user.push_subscriptions.sole
    assert_equal "https://push.example.com/send/abc123", subscription.endpoint
    assert_equal "5vR17us8wBhIdl1G4Zl_IA", subscription.auth_key
  end

  test "create moves an existing endpoint to the signed in user" do
    users(:jane).push_subscriptions.create!(endpoint: "https://push.example.com/send/abc123", p256dh_key: "old", auth_key: "old")

    post push_subscriptions_path, params: subscription_params, as: :json

    assert_response :created
    assert_equal @user, PushSubscription.find_by(endpoint: "https://push.example.com/send/abc123").user
  end

  test "create rejects a non https endpoint" do
    post push_subscriptions_path, params: subscription_params(endpoint: "http://rails-relay-internal:3000/internal"), as: :json

    assert_response :unprocessable_entity
    assert_empty PushSubscription.all
  end

  test "create requires authentication" do
    sign_out

    post push_subscriptions_path, params: subscription_params, as: :json

    assert_empty PushSubscription.all
  end

  private

  def subscription_params(endpoint: "https://push.example.com/send/abc123")
    {
      endpoint: endpoint,
      expirationTime: nil,
      keys: { p256dh: "BPVlhw23nOgbBx8WsBDlRsSwa81irMttlLOw4q29DG-2vIHzBXNZzbYZpQ9-aWCYDib3PIDpJ8Q0Ol9giHD5boM", auth: "5vR17us8wBhIdl1G4Zl_IA" }
    }
  end
end
