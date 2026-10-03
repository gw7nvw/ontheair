class AddActiveToDxccPrefix < ActiveRecord::Migration[5.0]
  def change
     add_column :dxcc_prefixes, :is_active, :boolean
  end
end
