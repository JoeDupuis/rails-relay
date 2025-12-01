class ConnectionsController < ApplicationController
  before_action :set_server

  def create
    InternalApiClient.start_connection(
      server_id: @server.id,
      user_id: Current.user.id,
      config: {
        address: @server.address,
        port: @server.port,
        ssl: @server.ssl,
        ssl_verify: @server.ssl_verify,
        nickname: @server.nickname,
        username: @server.username,
        realname: @server.realname
      }
    )
    redirect_to @server, notice: "Connecting..."
  rescue InternalApiClient::ServiceUnavailable
    redirect_to @server, alert: "IRC service unavailable"
  end

  def destroy
    InternalApiClient.stop_connection(server_id: @server.id)
    redirect_to @server, notice: "Disconnecting..."
  rescue InternalApiClient::ServiceUnavailable
    redirect_to @server, alert: "IRC service unavailable"
  end

  private

  def set_server
    @server = Current.user.servers.find(params[:server_id])
  end
end
