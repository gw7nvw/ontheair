class AddMailuserToUser < ActiveRecord::Migration
  def change
   add_column :users, :mailuser, :string

  end
end
