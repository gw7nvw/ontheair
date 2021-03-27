class CreateAwards < ActiveRecord::Migration
  def change
    create_table :awards do |t|
      t.string :name
      t.text :description
      t.text :email_text

      t.integer :huts_minimum
      t.integer :parks_minimum
      t.integer :islands_minimum
      t.boolean :user_qrp
      t.boolean :contact_qrp
      t.boolean :is_active

      t.integer :createdBy_id
      t.timestamps
    end
  end
end
