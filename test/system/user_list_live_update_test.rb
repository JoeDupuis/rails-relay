require "application_system_test_case"

class UserListLiveUpdateTest < ApplicationSystemTestCase
  setup do
    @user = users(:joe)
    @test_id = SecureRandom.hex(4)
  end

  def sign_in_user
    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
    assert_no_selector "input[id='password']", wait: 5
  end

  test "user list updates in real-time when another user joins" do
    server = @user.servers.create!(
      address: "#{@test_id}-join.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: true)

    sign_in_user
    visit channel_path(channel)

    assert_no_selector ".user-list .nick", text: "newuser123"

    IrcEventHandler.handle(server, {
      type: "join",
      data: {
        target: channel.name,
        source: "newuser123!user@host.example.com"
      }
    })

    assert_selector ".user-list .nick", text: "newuser123", wait: 5
  end

  test "user list updates in real-time when another user parts" do
    server = @user.servers.create!(
      address: "#{@test_id}-part.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: true)
    channel.channel_users.create!(nickname: "existinguser")

    sign_in_user
    visit channel_path(channel)

    assert_selector ".user-list .nick", text: "existinguser"

    IrcEventHandler.handle(server, {
      type: "part",
      data: {
        target: channel.name,
        source: "existinguser!user@host.example.com",
        text: "Goodbye!"
      }
    })

    assert_no_selector ".user-list .nick", text: "existinguser", wait: 5
  end

  test "user list updates in real-time when another user quits" do
    server = @user.servers.create!(
      address: "#{@test_id}-quit.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: true)
    channel.channel_users.create!(nickname: "quittinguser")

    sign_in_user
    visit channel_path(channel)

    assert_selector ".user-list .nick", text: "quittinguser"

    IrcEventHandler.handle(server, {
      type: "quit",
      data: {
        source: "quittinguser!user@host.example.com",
        text: "Connection reset"
      }
    })

    assert_no_selector ".user-list .nick", text: "quittinguser", wait: 5
  end

  test "user list updates in real-time when another user is kicked" do
    server = @user.servers.create!(
      address: "#{@test_id}-kick.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: true)
    channel.channel_users.create!(nickname: "kickeduser")

    sign_in_user
    visit channel_path(channel)

    assert_selector ".user-list .nick", text: "kickeduser"

    IrcEventHandler.handle(server, {
      type: "kick",
      data: {
        target: channel.name,
        source: "op!op@host.example.com",
        kicked: "kickeduser",
        text: "Bye!"
      }
    })

    assert_no_selector ".user-list .nick", text: "kickeduser", wait: 5
  end

  test "user list updates work for multiple sequential events" do
    server = @user.servers.create!(
      address: "#{@test_id}-multi.example.chat",
      nickname: "testnick",
      connected_at: Time.current
    )
    channel = Channel.create!(server: server, name: "#test-#{@test_id}", joined: true)

    sign_in_user
    visit channel_path(channel)

    IrcEventHandler.handle(server, {
      type: "join",
      data: {
        target: channel.name,
        source: "user1!user@host.example.com"
      }
    })

    assert_selector ".user-list .nick", text: "user1", wait: 5

    IrcEventHandler.handle(server, {
      type: "join",
      data: {
        target: channel.name,
        source: "user2!user@host.example.com"
      }
    })

    assert_selector ".user-list .nick", text: "user2", wait: 5

    IrcEventHandler.handle(server, {
      type: "part",
      data: {
        target: channel.name,
        source: "user1!user@host.example.com",
        text: "Leaving"
      }
    })

    assert_no_selector ".user-list .nick", text: "user1", wait: 5
    assert_selector ".user-list .nick", text: "user2"

    IrcEventHandler.handle(server, {
      type: "kick",
      data: {
        target: channel.name,
        source: "op!op@host.example.com",
        kicked: "user2",
        text: "Goodbye"
      }
    })

    assert_no_selector ".user-list .nick", text: "user2", wait: 5
  end
end
