class Channel < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :server
  has_many :channel_users, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true, format: { with: /\A[#&].+\z/ }
  validates :name, uniqueness: { scope: :server_id }

  scope :joined, -> { where(joined: true) }

  def display_name
    name
  end

  def subtitle
    topic
  end

  after_update_commit :broadcast_joined_status, if: :saved_change_to_joined?
  after_update_commit :broadcast_sidebar_joined_status, if: :saved_change_to_joined?
  after_update_commit :broadcast_sidebar_read_status, if: :saved_change_to_last_read_message_id?

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

  def broadcast_user_list
    broadcast_replace_to(
      [ self, :users ],
      target: "channel_#{id}_user_list",
      partial: "channels/user_list",
      locals: { channel: self }
    )
    broadcast_update_to(
      [ self, :users ],
      target: "channel_#{id}_user_count",
      html: channel_users.size.to_s
    )
  end

  private

  def broadcast_sidebar_joined_status
    return unless server.user_id

    if joined?
      broadcast_append_to(
        "sidebar_#{server.user_id}",
        target: "server_#{server.id}_channels",
        partial: "shared/channel_sidebar_item",
        locals: { channel: self }
      )
    else
      broadcast_remove_to(
        "sidebar_#{server.user_id}",
        target: "channel_#{id}_sidebar"
      )
    end
  end

  def broadcast_sidebar_read_status
    return unless server.user_id

    broadcast_replace_to(
      "sidebar_#{server.user_id}",
      target: "channel_#{id}_sidebar",
      partial: "shared/channel_sidebar_item",
      locals: { channel: self }
    )
  end

  def broadcast_joined_status
    broadcast_replace_to(
      self,
      target: ActionView::RecordIdentifier.dom_id(self, :header),
      partial: "channels/header",
      locals: { messageable: self }
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
      locals: { messageable: self }
    )

    broadcast_replace_to(
      server,
      target: ActionView::RecordIdentifier.dom_id(server, :channels),
      partial: "servers/channels",
      locals: { server: server, channels: server.channels.includes(:channel_users).order(:name) }
    )
  end
end
