class AddClosedAtToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :closed_at, :datetime
  end
end
