class AddOnlineToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :online, :boolean, default: false, null: false
  end
end
