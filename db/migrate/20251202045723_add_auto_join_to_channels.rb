class AddAutoJoinToChannels < ActiveRecord::Migration[8.1]
  def change
    add_column :channels, :auto_join, :boolean, default: false, null: false
  end
end
