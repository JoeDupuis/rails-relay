class IrcConnectionManager
  include Singleton

  def initialize
    @connections = {}
    @mutex = Mutex.new
  end

  def start(server_id:, user_id:, config:)
    @mutex.synchronize do
      return false if @connections[server_id]

      connection = IrcConnection.new(
        server_id: server_id,
        user_id: user_id,
        config: config,
        on_event: ->(event) { notify_web_service(server_id, user_id, event) }
      )

      @connections[server_id] = connection
      connection.start
      true
    end
  end

  def stop(server_id)
    @mutex.synchronize do
      connection = @connections.delete(server_id)
      connection&.stop
      connection.present?
    end
  end

  def send_command(server_id, command, params)
    @mutex.synchronize do
      connection = @connections[server_id]
      return false unless connection

      connection.execute(command, params)
      true
    end
  end

  def ison(server_id, nicks)
    connection = @mutex.synchronize { @connections[server_id] }
    return nil unless connection
    connection.ison(nicks)
  end

  def active_connections
    @mutex.synchronize { @connections.keys }
  end

  def connected?(server_id)
    @mutex.synchronize { @connections.key?(server_id) }
  end

  def reset!
    @mutex.synchronize do
      @connections.each_value(&:stop)
      @connections.clear
    end
  end

  private

  def notify_web_service(server_id, user_id, event)
    InternalApiClient.post_event(
      server_id: server_id,
      user_id: user_id,
      event: event
    )
  rescue InternalApiClient::ServiceUnavailable => e
    Rails.logger.error "Failed to post event: #{e.message}"
  end
end
