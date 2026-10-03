# typed: false
class AddRefIdToAsset < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :ref_id, :integer
  end
end
