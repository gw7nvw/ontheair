# typed: false
class CreateSessions < ActiveRecord::Migration[5.0]
  def change
    create_table :sessions do |t|
      t.text :session_id
      t.text :data

      t.timestamps
    end
  end
end
