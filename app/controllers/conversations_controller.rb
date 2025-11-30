class ConversationsController < ApplicationController
  before_action :set_conversation

  def show
    @conversation.mark_as_read!
    @server = @conversation.server
    @messages = @conversation.messages
  end

  private

  def set_conversation
    @conversation = Conversation.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:id])
  end
end
