class ChannelsController < ApplicationController
  before_action :set_server, only: [ :create ]
  before_action :set_channel, only: [ :show, :destroy ]

  def show
  end

  def create
    @channel = @server.channels.find_or_initialize_by(name: channel_params[:name])

    InternalApiClient.send_command(
      server_id: @server.id,
      command: "join",
      params: { channel: @channel.name }
    )

    @channel.save! unless @channel.persisted?
    redirect_to @channel
  rescue InternalApiClient::ServiceUnavailable
    redirect_to @server, alert: "IRC service unavailable"
  rescue InternalApiClient::ConnectionNotFound
    redirect_to @server, alert: "Server not connected"
  end

  def destroy
    InternalApiClient.send_command(
      server_id: @channel.server_id,
      command: "part",
      params: { channel: @channel.name }
    )

    @channel.update!(joined: false)
    redirect_to @channel.server
  rescue InternalApiClient::ServiceUnavailable
    redirect_to @channel, alert: "IRC service unavailable"
  rescue InternalApiClient::ConnectionNotFound
    redirect_to @channel.server, alert: "Server not connected"
  end

  private

  def set_server
    @server = Server.find(params[:server_id])
  end

  def set_channel
    @channel = Channel.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(:name)
  end
end
