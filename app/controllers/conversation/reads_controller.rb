class Conversation::ReadsController < ApplicationController
  before_action :set_conversation

  def create
    @conversation.mark_as_read!
    head :no_content
  end

  private

  def set_conversation
    @conversation = Conversation.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:conversation_id])
  end
end
