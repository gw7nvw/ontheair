class AddDxccenumToDxccPrefix < ActiveRecord::Migration
  def change
    add_column :dxcc_prefixes, :dxcc_enum, :string
  end
end
