class AddSslVerifyToServers < ActiveRecord::Migration[8.1]
  def change
    add_column :servers, :ssl_verify, :boolean, default: true
  end
end
