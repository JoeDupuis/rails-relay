class ConversationsController < ApplicationController
  before_action :set_server, only: [ :create ]
  before_action :set_conversation, only: [ :show ]

  def show
    @conversation.mark_as_read!
    @server = @conversation.server
    @messages = @conversation.messages
  end

  def create
    @conversation = @server.conversations.find_or_create_by!(target_nick: params[:target_nick])
    redirect_to conversation_path(@conversation)
  end

  private

  def set_server
    @server = Current.user.servers.find(params[:server_id])
  end

  def set_conversation
    @conversation = Conversation.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:id])
  end
end
