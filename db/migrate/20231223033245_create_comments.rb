class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :comment
      t.string :code
      t.integer :updated_by_id

      t.timestamps
    end
  end
end
