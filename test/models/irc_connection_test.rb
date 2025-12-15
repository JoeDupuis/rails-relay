require "test_helper"

class MockYaicClient
  attr_reader :join_calls, :quit_calls, :connected

  def initialize(raise_on_connect: nil)
    @handlers = {}
    @join_calls = []
    @quit_calls = []
    @connected = false
    @raise_on_connect = raise_on_connect
  end

  def on(event_type, &block)
    @handlers[event_type] = block
    self
  end

  def connect
    raise @raise_on_connect if @raise_on_connect
    @connected = true
  end

  def connected?
    @connected
  end

  def join(channel)
    @join_calls << channel
  end

  def quit(message = nil)
    @quit_calls << message
    @connected = false
  end

  def trigger(event_type, event)
    @handlers[event_type]&.call(event)
  end
end

class IrcConnectionTest < ActiveSupport::TestCase
  setup do
    @config = {
      address: "irc.test.com",
      port: 6697,
      ssl: true,
      nickname: "testbot",
      username: "testbot",
      realname: "Test Bot"
    }
    @events = []
    @on_event = ->(event) { @events << event }
    @mock_client = MockYaicClient.new
  end

  test "start spawns thread" do
    Yaic::Client.stub :new, @mock_client do
      connection = IrcConnection.new(
        server_id: 1,
        user_id: 1,
        config: @config,
        on_event: @on_event
      )

      connection.start
      sleep 0.05

      assert connection.alive?
      assert connection.running?

      connection.stop
    end
  end

  test "stop signals thread to exit" do
    Yaic::Client.stub :new, @mock_client do
      connection = IrcConnection.new(
        server_id: 1,
        user_id: 1,
        config: @config,
        on_event: @on_event
      )

      connection.start
      sleep 0.05
      assert connection.alive?

      connection.stop

      assert_not connection.alive?
      assert_not connection.running?
      assert_includes @mock_client.quit_calls, nil
    end
  end

  test "execute queues command" do
    Yaic::Client.stub :new, @mock_client do
      connection = IrcConnection.new(
        server_id: 1,
        user_id: 1,
        config: @config,
        on_event: @on_event
      )

      connection.start
      sleep 0.05

      connection.execute("join", { channel: "#test" })
      sleep 0.15

      assert_includes @mock_client.join_calls, "#test"

      connection.stop
    end
  end

  test "process_commands executes queued commands" do
    Yaic::Client.stub :new, @mock_client do
      connection = IrcConnection.new(
        server_id: 1,
        user_id: 1,
        config: @config,
        on_event: @on_event
      )

      connection.start
      sleep 0.05

      connection.execute("join", { channel: "#ruby" })
      connection.execute("join", { channel: "#elixir" })
      sleep 0.2

      assert_includes @mock_client.join_calls, "#ruby"
      assert_includes @mock_client.join_calls, "#elixir"

      connection.stop
    end
  end

  test "on_event callback is called for IRC events" do
    Yaic::Client.stub :new, @mock_client do
      connection = IrcConnection.new(
        server_id: 1,
        user_id: 1,
        config: @config,
        on_event: @on_event
      )

      connection.start
      sleep 0.05

      assert_includes @events.map { |e| e[:type] }, "connected"

      connection.stop

      assert_includes @events.map { |e| e[:type] }, "disconnected"
    end
  end

  test "connect timeout triggers error and disconnect events" do
    timeout_error = Yaic::TimeoutError.new("Operation timed out after 30 seconds")
    timeout_client = MockYaicClient.new(raise_on_connect: timeout_error)

    Yaic::Client.stub :new, timeout_client do
      connection = IrcConnection.new(
        server_id: 1,
        user_id: 1,
        config: @config,
        on_event: @on_event
      )

      connection.start
      sleep 0.1

      error_event = @events.find { |e| e[:type] == "error" }
      assert_not_nil error_event, "Expected an error event"
      assert_includes error_event[:message], "timed out"

      assert_includes @events.map { |e| e[:type] }, "disconnected"

      assert_not connection.alive?, "Thread should have exited after error"
    end
  end
end
