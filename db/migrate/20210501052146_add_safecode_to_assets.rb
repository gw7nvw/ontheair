# typed: false
class AddSafecodeToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :safecode, :string
  end
end
