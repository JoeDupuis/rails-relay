class IrcConnectionManager
  include Singleton

  def initialize
    @connections = {}
    @mutex = Mutex.new
  end

  def start(server_id:, user_id:, config:)
    replaced = nil
    already_connected = false

    started = @mutex.synchronize do
      existing = @connections[server_id]
      if existing&.alive?
        already_connected = existing.connected?
        next false
      end

      replaced = existing
      connection = IrcConnection.new(
        server_id: server_id,
        user_id: user_id,
        config: config,
        on_event: ->(event) { handle_event(connection, server_id, user_id, event) }
      )

      @connections[server_id] = connection
      connection.start
      true
    end

    replaced&.stop
    notify_web_service(server_id, user_id, { type: "connected" }) if already_connected
    started
  end

  def stop(server_id)
    connection = @mutex.synchronize { @connections.delete(server_id) }
    connection&.stop
    connection.present?
  end

  def send_command(server_id, command, params)
    connection = @mutex.synchronize { @connections[server_id] }
    return false unless connection

    connection.execute(command, params) || true
  rescue Yaic::ConnectionError
    false
  end

  def ison(server_id, nicks)
    connection = @mutex.synchronize { @connections[server_id] }
    return nil unless connection
    connection.ison(nicks)
  rescue Yaic::ConnectionError
    nil
  end

  def active_connections
    @mutex.synchronize { @connections.keys }
  end

  def connected_connections
    connections = @mutex.synchronize { @connections.dup }
    connections.select { |_, connection| connection.connected? }.keys
  end

  def connected?(server_id)
    @mutex.synchronize { @connections.key?(server_id) }
  end

  def reset!
    connections = @mutex.synchronize { @connections.values.tap { @connections.clear } }
    connections.each(&:stop)
  end

  private

  def handle_event(connection, server_id, user_id, event)
    forward = @mutex.synchronize do
      current = @connections[server_id]
      next false if current && !current.equal?(connection)

      @connections.delete(server_id) if current && %w[disconnected error].include?(event[:type])
      true
    end

    notify_web_service(server_id, user_id, event) if forward
  end

  def notify_web_service(server_id, user_id, event)
    InternalApiClient.post_event(
      server_id: server_id,
      user_id: user_id,
      event: event
    )
  rescue StandardError => e
    Rails.logger.error "[IRC-#{server_id}] Event delivery failed: #{e.message}"
  end
end
