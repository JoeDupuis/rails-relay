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
      when "join"
        handle_join(server, event_data)
      when "part"
        handle_part(server, event_data)
      end
    end

    private

    def handle_connected(server)
      server.update!(connected_at: Time.current)
    end

    def handle_disconnected(server)
      server.update!(connected_at: nil)
    end

    def handle_join(server, data)
      channel_name = data[:channel] || data["channel"]
      return unless channel_name

      channel = server.channels.find_or_create_by!(name: channel_name)
      channel.update!(joined: true)
    end

    def handle_part(server, data)
      channel_name = data[:channel] || data["channel"]
      return unless channel_name

      channel = server.channels.find_by(name: channel_name)
      channel&.update!(joined: false)
    end
  end
end
