class AddIsoCodeToDxccPrefixes < ActiveRecord::Migration[5.0]
  def change
     add_column :dxcc_prefixes, :iso_code, :string
  end
end
