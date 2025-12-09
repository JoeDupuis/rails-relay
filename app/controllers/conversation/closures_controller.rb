class Conversation::ClosuresController < ApplicationController
  before_action :set_conversation

  def create
    @conversation.close!
    @conversation.broadcast_sidebar_remove
    redirect_to server_path(@conversation.server), notice: "Conversation closed"
  end

  private

  def set_conversation
    @conversation = Conversation.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:conversation_id])
  end
end
