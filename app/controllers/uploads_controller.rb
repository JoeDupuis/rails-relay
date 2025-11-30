class UploadsController < ApplicationController
  before_action :set_channel

  ALLOWED_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_SIZE = 10.megabytes

  def create
    file = params[:file]

    unless valid_file?(file)
      render json: { error: "Invalid file type or size" }, status: :unprocessable_entity
      return
    end

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )

    url = rails_blob_url(blob, host: request.base_url)

    @message = Message.create!(
      server: @server,
      channel: @channel,
      sender: @server.nickname,
      content: url,
      message_type: "privmsg"
    )

    InternalApiClient.send_command(
      server_id: @server.id,
      command: "privmsg",
      params: { target: @channel.name, message: url }
    )

    respond_to do |format|
      format.json { render json: { url: url, message_id: @message.id } }
    end
  rescue InternalApiClient::ConnectionNotFound, InternalApiClient::ServiceUnavailable => e
    render json: { error: e.message }, status: :service_unavailable
  end

  private

  def set_channel
    @channel = Channel.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:channel_id])
    @server = @channel.server
  end

  def valid_file?(file)
    return false unless file.present?
    return false unless ALLOWED_TYPES.include?(file.content_type)
    return false if file.size > MAX_SIZE
    true
  end
end
