class ChannelUser < ApplicationRecord
  belongs_to :channel

  validates :nickname, presence: true
  validates :nickname, uniqueness: { scope: :channel_id }

  after_create_commit :broadcast_user_list
  after_destroy_commit :broadcast_user_list
  after_update_commit :broadcast_user_list, if: :saved_change_to_modes?

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

  def broadcast_user_list
    broadcast_replace_to(
      [ channel, :users ],
      target: "channel_#{channel.id}_user_list",
      partial: "channels/user_list",
      locals: { channel: channel }
    )
  end
end
