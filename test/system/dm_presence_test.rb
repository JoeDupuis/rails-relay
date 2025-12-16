require "application_system_test_case"

class DmPresenceTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  test "presence indicator shows offline by default" do
    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [] }.to_json, headers: { "Content-Type" => "application/json" })

    server = @user.servers.create!(
      address: "#{@test_id}-presence.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Conversation.create!(server: server, target_nick: "alice", online: false)

    sign_in_as(@user)
    visit server_path(server)

    within(".dm-item", text: "alice") do
      assert_selector ".presence-indicator.-offline"
    end
  end

  test "presence indicator shows online when user is online" do
    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [ "alice" ] }.to_json, headers: { "Content-Type" => "application/json" })

    server = @user.servers.create!(
      address: "#{@test_id}-online.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Conversation.create!(server: server, target_nick: "alice", online: true)

    sign_in_as(@user)
    visit server_path(server)

    within(".dm-item", text: "alice") do
      assert_selector ".presence-indicator.-online", wait: 5
    end
  end

  test "presence updates from offline to online when ISON returns user" do
    stub_ison = stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [] }.to_json, headers: { "Content-Type" => "application/json" })

    server = @user.servers.create!(
      address: "#{@test_id}-update.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Conversation.create!(server: server, target_nick: "alice", online: false)

    sign_in_as(@user)
    visit server_path(server)

    within(".dm-item", text: "alice") do
      assert_selector ".presence-indicator.-offline", wait: 5
    end

    remove_request_stub(stub_ison)
    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [ "alice" ] }.to_json, headers: { "Content-Type" => "application/json" })

    page.execute_script("document.querySelector('[data-controller~=\"ison\"]').ison.poll()")

    within(".dm-item", text: "alice") do
      assert_selector ".presence-indicator.-online", wait: 5
    end
  end

  test "presence updates from online to offline when ISON returns empty" do
    stub_ison = stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [ "alice" ] }.to_json, headers: { "Content-Type" => "application/json" })

    server = @user.servers.create!(
      address: "#{@test_id}-offline.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Conversation.create!(server: server, target_nick: "alice", online: true)

    sign_in_as(@user)
    visit server_path(server)

    within(".dm-item", text: "alice") do
      assert_selector ".presence-indicator.-online", wait: 5
    end

    remove_request_stub(stub_ison)
    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [] }.to_json, headers: { "Content-Type" => "application/json" })

    page.execute_script("document.querySelector('[data-controller~=\"ison\"]').ison.poll()")

    within(".dm-item", text: "alice") do
      assert_selector ".presence-indicator.-offline", wait: 5
    end
  end

  test "multiple DM presence indicators update correctly" do
    stub_request(:get, %r{#{Rails.configuration.irc_service_url}/internal/irc/ison})
      .to_return(status: 200, body: { online: [ "alice", "charlie" ] }.to_json, headers: { "Content-Type" => "application/json" })

    server = @user.servers.create!(
      address: "#{@test_id}-multi.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    Conversation.create!(server: server, target_nick: "alice", online: false)
    Conversation.create!(server: server, target_nick: "bob", online: false)
    Conversation.create!(server: server, target_nick: "charlie", online: false)

    sign_in_as(@user)
    visit server_path(server)

    within(".dm-item", text: "alice") do
      assert_selector ".presence-indicator.-online", wait: 5
    end

    within(".dm-item", text: "bob") do
      assert_selector ".presence-indicator.-offline"
    end

    within(".dm-item", text: "charlie") do
      assert_selector ".presence-indicator.-online"
    end
  end
end
