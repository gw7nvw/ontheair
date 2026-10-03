# typed: false
class AddMailuserToUser < ActiveRecord::Migration[5.0]
  def change
   add_column :users, :mailuser, :string

  end
end
