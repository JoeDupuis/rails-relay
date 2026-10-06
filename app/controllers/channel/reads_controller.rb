class Channel::ReadsController < ApplicationController
  before_action :set_channel

  def create
    @channel.mark_as_read!
    head :no_content
  end

  private

  def set_channel
    @channel = Channel.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:channel_id])
  end
end
