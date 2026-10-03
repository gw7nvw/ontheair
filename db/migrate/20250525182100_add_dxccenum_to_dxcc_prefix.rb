class AddDxccenumToDxccPrefix < ActiveRecord::Migration[5.0]
  def change
    add_column :dxcc_prefixes, :dxcc_enum, :string
  end
end
