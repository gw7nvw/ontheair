# typed: false
class AddCreatedByToAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :createdBy_id, :integer
  end
end
