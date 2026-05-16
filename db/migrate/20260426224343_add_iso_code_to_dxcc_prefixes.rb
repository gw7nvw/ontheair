class AddIsoCodeToDxccPrefixes < ActiveRecord::Migration
  def change
     add_column :dxcc_prefixes, :iso_code, :string
  end
end
