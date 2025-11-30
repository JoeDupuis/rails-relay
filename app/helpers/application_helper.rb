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
    0
  end
end
