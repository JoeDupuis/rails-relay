class Message < TenantRecord
  belongs_to :channel

  validates :nickname, presence: true
  validates :content, presence: true
end
