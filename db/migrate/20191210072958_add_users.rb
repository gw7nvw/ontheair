# typed: false
class AddUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :callsign
      t.string :email
      t.string :firstname
      t.string :lastname
      t.string  :password_digest
      t.string :remember_token
      t.string :activation_digest
      t.boolean :activated, default: false
      t.datetime :activated_at
      t.boolean :is_admin, default: false
      t.boolean :is_active, default: true
      t.boolean :is_modifier, default: false
      t.integer :huts_bagged
      t.integer :parks_bagged
      t.integer :huts_first_bagged
      t.integer :parks_first_bagged


      t.index :remember_token

      t.timestamps
    end

  end
end
