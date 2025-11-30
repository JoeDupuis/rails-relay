class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :channel, null: false, foreign_key: true
      t.string :nickname, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
