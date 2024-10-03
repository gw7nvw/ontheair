# typed: false
class AddRefIdToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :ref_id, :integer
  end
end
