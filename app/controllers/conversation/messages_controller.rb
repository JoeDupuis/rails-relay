class Conversation::MessagesController < ApplicationController
  before_action :set_conversation

  def create
    content = params[:content]

    @message = Message.create!(
      server: @server,
      channel: nil,
      target: @conversation.target_nick,
      sender: @server.nickname,
      content: content,
      message_type: "privmsg"
    )

    InternalApiClient.send_command(
      server_id: @server.id,
      command: "privmsg",
      params: { target: @conversation.target_nick, message: content }
    )

    @conversation.touch(:last_message_at)

    head :ok
  rescue InternalApiClient::ConnectionNotFound
    flash[:alert] = "Server not connected"
    redirect_to @conversation
  rescue InternalApiClient::ServiceUnavailable
    flash[:alert] = "IRC service unavailable"
    redirect_to @conversation
  end

  private

  def set_conversation
    @conversation = Conversation.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:conversation_id])
    @server = @conversation.server
  end
end
