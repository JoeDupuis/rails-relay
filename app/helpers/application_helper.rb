module ApplicationHelper
  def current_user_servers
    return [] unless Current.user
    Current.user.servers.includes(:channels)
  end

  def current_channel
    @channel
  end

  def unread_notification_count
    0
  end
end
