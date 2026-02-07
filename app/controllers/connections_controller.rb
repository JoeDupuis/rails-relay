class ConnectionsController < ApplicationController
  before_action :set_server

  def create
    InternalApiClient.start_connection(
      server_id: @server.id,
      user_id: Current.user.id,
      config: @server.connection_config
    )
    redirect_back fallback_location: @server, notice: "Connecting..."
  rescue InternalApiClient::ServiceUnavailable
    redirect_back fallback_location: @server, alert: "IRC service unavailable"
  end

  def destroy
    InternalApiClient.stop_connection(server_id: @server.id)
    redirect_back fallback_location: @server
  rescue InternalApiClient::ServiceUnavailable
    redirect_back fallback_location: @server, alert: "IRC service unavailable"
  end

  private

  def set_server
    @server = Current.user.servers.find(params[:server_id])
  end
end
