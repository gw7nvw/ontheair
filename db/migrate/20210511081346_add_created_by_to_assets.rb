# typed: false
class AddCreatedByToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :createdBy_id, :integer
  end
end
