class IrcEventHandler
  class << self
    def handle(server, event)
      event_type = event[:type] || event["type"]
      event_data = event[:data] || event["data"] || {}

      case event_type
      when "connected"
        handle_connected(server)
      when "disconnected"
        handle_disconnected(server)
      end
    end

    private

    def handle_connected(server)
      server.update!(connected_at: Time.current)
    end

    def handle_disconnected(server)
      server.update!(connected_at: nil)
    end
  end
end
