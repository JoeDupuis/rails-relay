class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: true, format: { with: %r{\Ahttps://\S+\z} }
  validates :p256dh_key, :auth_key, presence: true

  def self.enabled?
    Rails.configuration.vapid_public_key.present? && Rails.configuration.vapid_private_key.present?
  end

  def deliver(payload)
    WebPush.payload_send(
      message: payload.to_json,
      endpoint: endpoint,
      p256dh: p256dh_key,
      auth: auth_key,
      ttl: 1.day.to_i,
      urgency: "high",
      vapid: vapid
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription, WebPush::Unauthorized
    destroy
  end

  private

  def vapid
    {
      subject: "mailto:#{user.email_address}",
      public_key: Rails.configuration.vapid_public_key,
      private_key: Rails.configuration.vapid_private_key
    }
  end
end
