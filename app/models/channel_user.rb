class ChannelUser < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :channel

  validates :nickname, presence: true
  validates :nickname, uniqueness: { scope: :channel_id }

  after_create_commit :broadcast_user_list_on_create
  after_destroy_commit :broadcast_user_list_on_destroy
  after_update_commit :broadcast_user_list_on_update, if: :saved_change_to_modes?

  scope :ops, -> { where("modes LIKE ?", "%o%") }
  scope :voiced, -> { where("modes LIKE ?", "%v%") }
  scope :regular, -> { where("(modes NOT LIKE ? OR modes IS NULL) AND (modes NOT LIKE ? OR modes IS NULL)", "%o%", "%v%") }

  def op?
    modes&.include?("o")
  end

  def voiced?
    modes&.include?("v")
  end

  private

  def broadcast_user_list_on_create
    broadcast_user_list
  end

  def broadcast_user_list_on_destroy
    return unless Channel.exists?(channel_id)
    broadcast_user_list
  end

  def broadcast_user_list_on_update
    broadcast_user_list
  end

  def broadcast_user_list
    channel.reload
    broadcast_replace_to(
      [ channel, :users ],
      target: "channel_#{channel.id}_user_list",
      partial: "channels/user_list",
      locals: { channel: channel }
    )
  end
end
