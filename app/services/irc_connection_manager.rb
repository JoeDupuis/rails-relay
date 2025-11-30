class IrcConnectionManager
  include Singleton

  def initialize
    @connections = {}
    @mutex = Mutex.new
  end

  def start(server_id:, user_id:, config:)
    @mutex.synchronize do
      @connections[server_id] = { user_id: user_id, config: config }
    end
  end

  def stop(server_id)
    @mutex.synchronize do
      @connections.delete(server_id)
    end
  end

  def send_command(server_id, command, params)
    @mutex.synchronize do
      return false unless @connections.key?(server_id)
      true
    end
  end

  def active_connections
    @mutex.synchronize do
      @connections.keys
    end
  end

  def reset!
    @mutex.synchronize do
      @connections.clear
    end
  end
end
