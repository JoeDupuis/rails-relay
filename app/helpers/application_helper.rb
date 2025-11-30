module ApplicationHelper
  def current_user_servers
    return [] unless Current.user
    Current.user.servers.includes(:channels, :conversations)
  end

  def current_channel
    @channel
  end

  def current_conversation
    @conversation
  end

  def unread_notification_count
    return 0 unless Current.user
    Notification.joins(message: :server).where(servers: { user_id: Current.user.id }).unread.count
  end
end
