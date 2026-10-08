class NotificationsController < ApplicationController
  def index
    @notifications = current_user_notifications.unread.recent
  end

  def update
    @notification = current_user_notifications.find(params[:id])
    @notification.mark_as_read!

    redirect_to polymorphic_path(@notification.target, anchor: "message_#{@notification.message.id}")
  end

  private

  def current_user_notifications
    Current.user.notifications
  end
end
