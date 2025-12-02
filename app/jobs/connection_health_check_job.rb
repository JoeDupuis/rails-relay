class ConnectionHealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    connected_servers = Server.where.not(connected_at: nil)
    return if connected_servers.none?

    active_connection_ids = fetch_active_connections
    mark_stale_connections_disconnected(connected_servers, active_connection_ids)
  end

  private

  def fetch_active_connections
    response = InternalApiClient.status
    json = JSON.parse(response.body)
    json["connections"]
  rescue InternalApiClient::ServiceUnavailable
    []
  end

  def mark_stale_connections_disconnected(connected_servers, active_connection_ids)
    connected_servers.find_each do |server|
      next if active_connection_ids.include?(server.id)

      mark_server_disconnected(server)
    end
  end

  def mark_server_disconnected(server)
    server.update!(connected_at: nil)
    server.channels.update_all(joined: false)
    ChannelUser.joins(:channel).where(channels: { server_id: server.id }).delete_all
  end
end
