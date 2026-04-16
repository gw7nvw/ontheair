class AddBaselayerToUser < ActiveRecord::Migration
  def change
    add_column :users, :baselayer, :string
  end
end
