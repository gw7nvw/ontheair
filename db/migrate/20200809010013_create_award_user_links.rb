class CreateAwardUserLinks < ActiveRecord::Migration
  def change
    create_table :award_user_links do |t|
      t.integer :user_id
      t.integer :award_id
      t.boolean :notification_sent
      t.boolean :acknowledged
      t.timestamps
    end
  end
end
