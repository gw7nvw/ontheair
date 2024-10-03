# typed: false
class AddAcctnumberToUser < ActiveRecord::Migration
  def change
      add_column :users, :acctnumber, :string
  end
end
