class ChannelUser < TenantRecord
  belongs_to :channel

  validates :nickname, presence: true
  validates :nickname, uniqueness: { scope: :channel_id }

  scope :ops, -> { where("modes LIKE ?", "%o%") }
  scope :voiced, -> { where("modes LIKE ?", "%v%") }
  scope :regular, -> { where("(modes NOT LIKE ? OR modes IS NULL) AND (modes NOT LIKE ? OR modes IS NULL)", "%o%", "%v%") }

  def op?
    modes&.include?("o")
  end

  def voiced?
    modes&.include?("v")
  end
end
