class AddActiveToDxccPrefix < ActiveRecord::Migration
  def change
     add_column :dxcc_prefixes, :is_active, :boolean
  end
end
