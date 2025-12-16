require "test_helper"

class ServerTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
  end

  test "validates presence of address" do
    server = @user.servers.build(nickname: "testnick")
    assert_not server.valid?
    assert_includes server.errors[:address], "can't be blank"
  end

  test "defaults port when blank string submitted" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick", port: "")
    server.valid?
    assert_equal 6697, server.port
  end

  test "validates port is numeric" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")
    server.port = "abc"
    assert_not server.valid?
    assert_includes server.errors[:port], "is not a number"
  end

  test "validates port in range 1-65535" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")

    server.port = 0
    assert_not server.valid?
    assert server.errors[:port].any? { |e| e.include?("in") || e.include?("greater") }

    server.port = 65536
    assert_not server.valid?
    assert server.errors[:port].any? { |e| e.include?("in") || e.include?("less") }

    server.port = 6697
    server.valid?
    assert_empty server.errors[:port]
  end

  test "validates presence of nickname" do
    server = @user.servers.build(address: "irc.example.com")
    assert_not server.valid?
    assert_includes server.errors[:nickname], "can't be blank"
  end

  test "validates nickname format" do
    server = @user.servers.build(address: "irc.example.com")

    server.nickname = "123abc"
    assert_not server.valid?
    assert server.errors[:nickname].any? { |e| e.include?("invalid") }

    server.nickname = "abc-def"
    server.valid?
    assert_empty server.errors[:nickname]

    server.nickname = "a"
    server.valid?
    assert_empty server.errors[:nickname]

    server.nickname = "TestNick1"
    server.valid?
    assert_empty server.errors[:nickname]
  end

  test "validates uniqueness of address+port per user" do
    @user.servers.create!(address: "irc.example.com", port: 6697, nickname: "testnick1")
    server = @user.servers.build(address: "irc.example.com", port: 6697, nickname: "testnick2")
    assert_not server.valid?
    assert_includes server.errors[:address], "has already been taken"
  end

  test "allows same address+port for different users" do
    other_user = users(:jane)
    @user.servers.create!(address: "irc.example.com", port: 6697, nickname: "testnick1")
    server = other_user.servers.build(address: "irc.example.com", port: 6697, nickname: "testnick2")
    assert server.valid?
  end

  test "validates auth_password present when auth_method is nickserv" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick", auth_method: "nickserv")
    assert_not server.valid?
    assert_includes server.errors[:auth_password], "can't be blank"
  end

  test "validates auth_password present when auth_method is sasl" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick", auth_method: "sasl")
    assert_not server.valid?
    assert_includes server.errors[:auth_password], "can't be blank"
  end

  test "defaults port to 6697" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")
    server.valid?
    assert_equal 6697, server.port
  end

  test "defaults ssl to true" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")
    server.valid?
    assert_equal true, server.ssl
  end

  test "defaults auth_method to none" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")
    server.valid?
    assert_equal "none", server.auth_method
  end

  test "defaults username to nickname when blank" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")
    server.valid?
    assert_equal "testnick", server.username
  end

  test "defaults realname to nickname when blank" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")
    server.valid?
    assert_equal "testnick", server.realname
  end

  test "encrypts auth_password" do
    server = @user.servers.create!(
      address: "irc.example.com",
      nickname: "testnick",
      auth_method: "nickserv",
      auth_password: "secretpassword"
    )
    server.reload
    assert_equal "secretpassword", server.auth_password
  end

  test "ssl_verify defaults to true" do
    server = @user.servers.build(address: "irc.example.com", nickname: "testnick")
    server.valid?
    assert_equal true, server.ssl_verify
  end

  test "ssl_verify can be set to false" do
    server = @user.servers.create!(
      address: "irc.example.com",
      nickname: "testnick",
      ssl: true,
      ssl_verify: false
    )
    server.reload
    assert_equal false, server.ssl_verify
  end

  test "broadcasts connection status when connected_at is set" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: nil)

    assert_turbo_stream_broadcasts server do
      server.update!(connected_at: Time.current)
    end
  end

  test "broadcasts connection status when connected_at is cleared" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)

    assert_turbo_stream_broadcasts server do
      server.update!(connected_at: nil)
    end
  end

  test "does not broadcast connection status when connected_at unchanged" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)

    assert_no_turbo_stream_broadcasts server do
      server.update!(address: "other.example.com")
    end
  end

  test "mark_disconnected! clears connected_at" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)
    assert server.connected?

    server.mark_disconnected!

    assert_nil server.connected_at
    assert_not server.connected?
  end

  test "mark_disconnected! sets all channels to not joined" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)
    channel1 = server.channels.create!(name: "#test1", joined: true)
    channel2 = server.channels.create!(name: "#test2", joined: true)

    server.mark_disconnected!

    assert_not channel1.reload.joined
    assert_not channel2.reload.joined
  end

  test "mark_disconnected! deletes all channel users" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)
    channel = server.channels.create!(name: "#test", joined: true)
    channel.channel_users.create!(nickname: "user1")
    channel.channel_users.create!(nickname: "user2")

    assert_equal 2, channel.channel_users.count

    server.mark_disconnected!

    assert_equal 0, channel.channel_users.count
  end

  test "mark_disconnected! broadcasts connection status change" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick", connected_at: Time.current)

    assert_turbo_stream_broadcasts server do
      server.mark_disconnected!
    end
  end

  test "broadcasts nickname change when nickname is updated" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "oldnick")

    assert_turbo_stream_broadcasts server do
      server.update!(nickname: "newnick")
    end
  end

  test "does not broadcast nickname change when nickname unchanged" do
    server = @user.servers.create!(address: "irc.example.com", nickname: "testnick")

    assert_no_turbo_stream_broadcasts server do
      server.update!(address: "other.example.com")
    end
  end
end
