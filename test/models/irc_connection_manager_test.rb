require "test_helper"

class MockIrcConnection
  attr_accessor :started, :stopped, :executed_commands

  def initialize(**)
    @started = false
    @stopped = false
    @executed_commands = []
  end

  def start
    @started = true
  end

  def stop
    @stopped = true
  end

  def execute(command, params)
    @executed_commands << { command: command, params: params }
  end
end

class IrcConnectionManagerTest < ActiveSupport::TestCase
  setup do
    @manager = IrcConnectionManager.instance
    @manager.reset!
  end

  test "start creates a new connection and returns true" do
    mock_connection = MockIrcConnection.new

    IrcConnection.stub :new, mock_connection do
      result = @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })
      assert result
      assert_includes @manager.active_connections, 1
      assert mock_connection.started
    end
  end

  test "start returns false for duplicate server_id" do
    mock_connection = MockIrcConnection.new

    IrcConnection.stub :new, mock_connection do
      @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })

      result = @manager.start(server_id: 1, user_id: 2, config: { address: "irc.other.com" })
      assert_not result
      assert_equal [ 1 ], @manager.active_connections
    end
  end

  test "stop removes connection and returns true" do
    mock_connection = MockIrcConnection.new

    IrcConnection.stub :new, mock_connection do
      @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })

      result = @manager.stop(1)
      assert result
      assert_empty @manager.active_connections
      assert mock_connection.stopped
    end
  end

  test "stop returns false for non-existent connection" do
    result = @manager.stop(999)
    assert_not result
  end

  test "send_command routes to connection and returns true" do
    mock_connection = MockIrcConnection.new

    IrcConnection.stub :new, mock_connection do
      @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })

      result = @manager.send_command(1, "join", { channel: "#test" })
      assert result
      assert_equal [ { command: "join", params: { channel: "#test" } } ], mock_connection.executed_commands
    end
  end

  test "send_command returns false for non-existent connection" do
    result = @manager.send_command(999, "join", { channel: "#test" })
    assert_not result
  end

  test "connected? returns true for active connection" do
    mock_connection = MockIrcConnection.new

    IrcConnection.stub :new, mock_connection do
      @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })

      assert @manager.connected?(1)
    end
  end

  test "connected? returns false for non-existent connection" do
    assert_not @manager.connected?(999)
  end

  test "active_connections returns array of server_ids" do
    mock_connection = MockIrcConnection.new

    IrcConnection.stub :new, mock_connection do
      @manager.start(server_id: 1, user_id: 1, config: { address: "irc1.test.com" })
      @manager.start(server_id: 2, user_id: 1, config: { address: "irc2.test.com" })
      @manager.start(server_id: 3, user_id: 1, config: { address: "irc3.test.com" })

      assert_equal [ 1, 2, 3 ], @manager.active_connections.sort
    end
  end

  test "connection is removed when disconnected event is received" do
    captured_on_event = nil
    mock_connection = MockIrcConnection.new

    fake_new = ->(**kwargs) {
      captured_on_event = kwargs[:on_event]
      mock_connection
    }

    IrcConnection.stub :new, fake_new do
      InternalApiClient.stub :post_event, nil do
        @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })
        assert_includes @manager.active_connections, 1

        captured_on_event.call(type: "disconnected")

        assert_not_includes @manager.active_connections, 1
      end
    end
  end

  test "connection is removed when error event is received" do
    captured_on_event = nil
    mock_connection = MockIrcConnection.new

    fake_new = ->(**kwargs) {
      captured_on_event = kwargs[:on_event]
      mock_connection
    }

    IrcConnection.stub :new, fake_new do
      InternalApiClient.stub :post_event, nil do
        @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })
        assert_includes @manager.active_connections, 1

        captured_on_event.call(type: "error", message: "SSL_write failed")

        assert_not_includes @manager.active_connections, 1
      end
    end
  end

  test "send_command returns false after connection disconnects" do
    captured_on_event = nil
    mock_connection = MockIrcConnection.new

    fake_new = ->(**kwargs) {
      captured_on_event = kwargs[:on_event]
      mock_connection
    }

    IrcConnection.stub :new, fake_new do
      InternalApiClient.stub :post_event, nil do
        @manager.start(server_id: 1, user_id: 1, config: { address: "irc.test.com" })

        assert @manager.send_command(1, "privmsg", { target: "#test", message: "hello" })

        captured_on_event.call(type: "disconnected")

        assert_not @manager.send_command(1, "privmsg", { target: "#test", message: "hello" })
      end
    end
  end
end
