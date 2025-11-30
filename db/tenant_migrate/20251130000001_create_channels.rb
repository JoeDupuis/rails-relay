class CreateChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :channels do |t|
      t.references :server, null: false, foreign_key: true
      t.string :name, null: false
      t.string :topic
      t.boolean :joined, null: false, default: false
      t.integer :last_read_message_id

      t.timestamps
    end

    add_index :channels, [ :server_id, :name ], unique: true
  end
end
