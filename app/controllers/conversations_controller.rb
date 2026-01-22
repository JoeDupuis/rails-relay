class ConversationsController < ApplicationController
  before_action :set_server, only: [ :create ]
  before_action :set_conversation, only: [ :show ]

  def show
    @conversation.mark_as_read!
    @server = @conversation.server
    @messages = @conversation.messages.order(created_at: :desc).limit(50).reverse
    @has_more = @messages.size == 50
    @oldest_id = @messages.first&.id
  end

  def create
    @conversation = @server.conversations.find_or_initialize_by(target_nick: params[:target_nick])
    if @conversation.persisted? && @conversation.closed?
      @conversation.reopen!
      @conversation.broadcast_sidebar_add
    elsif @conversation.new_record?
      @conversation.save!
    end
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
