class AddSmsGatewayToDxccPrefix < ActiveRecord::Migration
  def change
    add_column :dxcc_prefixes, :sms_gateway, :string
  end
end
