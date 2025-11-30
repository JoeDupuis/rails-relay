class NotificationsController < ApplicationController
  def index
    @notifications = current_user_notifications.unread.recent
  end

  def update
    @notification = current_user_notifications.find(params[:id])
    @notification.mark_as_read!

    redirect_to notification_target_path(@notification)
  end

  private

  def current_user_notifications
    Notification.joins(message: :server).where(servers: { user_id: Current.user.id })
  end

  def notification_target_path(notification)
    if notification.message.channel
      channel_path(notification.message.channel, anchor: "message_#{notification.message.id}")
    else
      conversation = notification.message.server.conversations.find_by(target_nick: notification.message.target)
      if conversation
        conversation_path(conversation, anchor: "message_#{notification.message.id}")
      else
        server_path(notification.message.server)
      end
    end
  end
end
