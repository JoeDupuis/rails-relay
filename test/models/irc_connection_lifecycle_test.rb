require "test_helper"
require_relative "../test_helpers/fake_irc_server"

class IrcConnectionLifecycleTest < ActiveSupport::TestCase
  setup do
    @events = Concurrent::Array.new
    @connections = []
    @servers = []
  end

  teardown do
    @connections.each(&:stop)
    @servers.each(&:close)
  end

  test "reports disconnected with a reason when the server drops the connection" do
    server = start_server(ssl: true)
    connection = connect_to(server)

    server.drop

    assert wait_for { event_types.include?("disconnected") }
    assert_predicate disconnected_events.first[:reason], :present?
    assert wait_for { !connection.alive? }
  end

  test "reports disconnected with the server's reason when it closes the link" do
    server = start_server
    connect_to(server)

    server.send_line("ERROR :Closing Link: tester (Ping timeout: 240 seconds)")

    assert wait_for { event_types.include?("disconnected") }
    assert_includes disconnected_events.first[:reason], "Ping timeout: 240 seconds"
  end

  test "stop on a healthy connection sends QUIT and reports disconnected once" do
    server = start_server
    connection = connect_to(server)

    connection.stop

    assert server.wait_for_line(/\AQUIT/)
    assert_not connection.alive?
    assert_equal 1, disconnected_events.size
  end

  test "stop on a lost connection does not raise and reports disconnected once" do
    server = start_server(ssl: true)
    connection = connect_to(server)
    server.drop
    assert wait_for { event_types.include?("disconnected") }

    assert_nothing_raised { connection.stop }

    assert_not connection.alive?
    assert_equal 1, disconnected_events.size
  end

  test "stop racing with connection loss reports disconnected exactly once" do
    5.times do
      @events.clear
      server = start_server(ssl: true)
      connection = connect_to(server)

      server.drop
      assert_nothing_raised { connection.stop }

      assert_not connection.alive?
      assert_equal 1, disconnected_events.size
    end
  end

  test "stop while registration is pending does not raise" do
    server = start_server(welcome: false)
    connection = build_connection(server)
    connection.start
    assert server.wait_for_line(/\AUSER/)

    assert_nothing_raised { connection.stop }

    assert_not connection.alive?
    assert_equal 1, disconnected_events.size
  end

  test "execute on a lost connection raises a connection error" do
    server = start_server
    connection = connect_to(server)
    server.drop
    assert wait_for { event_types.include?("disconnected") }

    assert_raises(Yaic::ConnectionError) do
      connection.execute("privmsg", { target: "#ruby", message: "hello" })
    end
  end

  test "ison on a lost connection raises a connection error" do
    server = start_server
    connection = connect_to(server)
    server.drop
    assert wait_for { event_types.include?("disconnected") }

    assert_raises(Yaic::ConnectionError) { connection.ison([ "someone" ]) }
  end

  private

  def start_server(**options)
    FakeIrcServer.new(**options).start.tap { |server| @servers << server }
  end

  def build_connection(server)
    IrcConnection.new(server_id: 1, user_id: 1, config: server.config, on_event: ->(event) { @events << event })
      .tap { |connection| @connections << connection }
  end

  def connect_to(server)
    connection = build_connection(server)
    connection.start
    assert wait_for { event_types.include?("connected") }, "expected the connection to register"
    connection
  end

  def event_types
    @events.map { |event| event[:type] }
  end

  def disconnected_events
    @events.select { |event| event[:type] == "disconnected" }
  end

  def wait_for(timeout: 3)
    deadline = Time.now + timeout
    until Time.now > deadline
      return true if yield
      sleep 0.02
    end
    false
  end
end
