class AddRemembertoken2ToUsers < ActiveRecord::Migration
  def change
   add_column :users, :remember_token2, :string

  end
end
