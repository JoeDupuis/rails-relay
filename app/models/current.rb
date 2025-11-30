class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_id
  delegate :user, to: :session, allow_nil: true
end
