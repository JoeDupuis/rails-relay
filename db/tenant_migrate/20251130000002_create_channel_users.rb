class CreateChannelUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_users do |t|
      t.references :channel, null: false, foreign_key: true
      t.string :nickname, null: false
      t.string :modes

      t.timestamps
    end

    add_index :channel_users, [ :channel_id, :nickname ], unique: true
  end
end
