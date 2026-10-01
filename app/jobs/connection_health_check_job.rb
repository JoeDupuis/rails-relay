class ConnectionHealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    return unless Server.exists?

    checked_at = Time.current
    status = fetch_status
    return if status.nil?

    mark_dead_connections_disconnected(status["connections"], checked_at)
    mark_live_connections_connected(status["connected"], checked_at)
  end

  private

  def fetch_status
    response = InternalApiClient.status
    return unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue InternalApiClient::ServiceTimeout
    nil
  rescue InternalApiClient::ServiceUnavailable
    { "connections" => [], "connected" => [] }
  end

  def mark_dead_connections_disconnected(active_ids, checked_at)
    Server.where(connected_at: ...checked_at)
      .where.not(id: Array(active_ids))
      .find_each(&:mark_disconnected!)
  end

  def mark_live_connections_connected(connected_ids, checked_at)
    Server.where(id: Array(connected_ids), connected_at: nil, updated_at: ...checked_at).find_each do |server|
      IrcEventHandler.handle(server, { type: "connected" })
    end
  end
end
