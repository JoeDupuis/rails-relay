class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :server, null: false, foreign_key: true
      t.string :target_nick, null: false
      t.integer :last_read_message_id
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, [ :server_id, :target_nick ], unique: true
  end
end
