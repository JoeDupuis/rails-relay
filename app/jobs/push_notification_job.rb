class PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    notification.push
  end
end
