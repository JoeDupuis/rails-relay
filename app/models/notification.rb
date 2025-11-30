class Notification < ApplicationRecord
  belongs_to :message

  validates :reason, presence: true, inclusion: { in: %w[dm highlight] }
end
