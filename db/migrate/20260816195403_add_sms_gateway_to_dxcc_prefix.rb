class AddSmsGatewayToDxccPrefix < ActiveRecord::Migration[5.0]
  def change
    add_column :dxcc_prefixes, :sms_gateway, :string
  end
end
