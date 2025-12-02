class Channel < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :server
  has_many :channel_users, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true, format: { with: /\A[#&].+\z/ }
  validates :name, uniqueness: { scope: :server_id }

  scope :joined, -> { where(joined: true) }

  after_update_commit :broadcast_joined_status, if: :saved_change_to_joined?

  def unread_count
    return 0 unless last_read_message_id
    messages.where("id > ?", last_read_message_id).count
  end

  def unread?
    if last_read_message_id
      messages.where("id > ?", last_read_message_id).exists?
    else
      messages.exists?
    end
  end

  def mark_as_read!
    update!(last_read_message_id: messages.maximum(:id))
  end

  private

  def broadcast_joined_status
    broadcast_replace_to(
      self,
      target: ActionView::RecordIdentifier.dom_id(self, :header),
      partial: "channels/header",
      locals: { channel: self }
    )

    broadcast_replace_to(
      self,
      target: ActionView::RecordIdentifier.dom_id(self, :banner),
      partial: "channels/banner",
      locals: { channel: self }
    )

    broadcast_replace_to(
      self,
      target: ActionView::RecordIdentifier.dom_id(self, :input),
      partial: "channels/input",
      locals: { channel: self }
    )

    broadcast_replace_to(
      server,
      target: ActionView::RecordIdentifier.dom_id(server, :channels),
      partial: "servers/channels",
      locals: { server: server, channels: server.channels.includes(:channel_users).order(:name) }
    )
  end
end
