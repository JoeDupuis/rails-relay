class CreateServers < ActiveRecord::Migration[8.1]
  def change
    create_table :servers do |t|
      t.string :address, null: false
      t.integer :port, null: false, default: 6697
      t.boolean :ssl, null: false, default: true
      t.string :nickname, null: false
      t.string :username
      t.string :realname
      t.string :auth_method, default: "none"
      t.string :auth_password
      t.integer :process_pid
      t.datetime :connected_at

      t.timestamps
    end
  end
end
