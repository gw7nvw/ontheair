class CreateUserTokens < ActiveRecord::Migration
  def change
    create_table :user_tokens do |t|
      t.string   "remember_token"
      t.integer "user_id"

      t.timestamps
    end
  end
end
