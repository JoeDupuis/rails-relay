class CreateTenantTablesInPrimary < ActiveRecord::Migration[8.1]
  def change
    create_table :servers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address, null: false
      t.integer :port, default: 6697, null: false
      t.boolean :ssl, default: true, null: false
      t.string :nickname, null: false
      t.string :username
      t.string :realname
      t.string :auth_method, default: "none"
      t.string :auth_password
      t.integer :process_pid
      t.datetime :connected_at
      t.timestamps
    end
    add_index :servers, [ :user_id, :address, :port ], unique: true

    create_table :channels do |t|
      t.references :server, null: false, foreign_key: true
      t.string :name, null: false
      t.string :topic
      t.boolean :joined, default: false, null: false
      t.integer :last_read_message_id
      t.timestamps
    end
    add_index :channels, [ :server_id, :name ], unique: true

    create_table :channel_users do |t|
      t.references :channel, null: false, foreign_key: true
      t.string :nickname, null: false
      t.string :modes
      t.timestamps
    end
    add_index :channel_users, [ :channel_id, :nickname ], unique: true

    create_table :messages do |t|
      t.references :server, null: false, foreign_key: true
      t.references :channel, foreign_key: { on_delete: :nullify }
      t.string :sender, null: false
      t.text :content
      t.string :target
      t.string :message_type, default: "privmsg", null: false
      t.timestamps
    end

    create_table :notifications do |t|
      t.references :message, null: false, foreign_key: true
      t.string :reason, null: false
      t.timestamps
    end
  end
end
