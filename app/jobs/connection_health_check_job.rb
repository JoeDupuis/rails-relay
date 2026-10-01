class ConnectionHealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    return unless Server.where.not(connected_at: nil).exists?

    checked_at = Time.current
    active_connection_ids = fetch_active_connections
    return if active_connection_ids.nil?

    Server.where(connected_at: ...checked_at)
      .where.not(id: active_connection_ids)
      .find_each(&:mark_disconnected!)
  end

  private

  def fetch_active_connections
    response = InternalApiClient.status
    return unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)["connections"]
  rescue InternalApiClient::ServiceTimeout
    nil
  rescue InternalApiClient::ServiceUnavailable
    []
  end
end
