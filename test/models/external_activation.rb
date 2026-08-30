require "test_helper"

class ExternalActivationTest < ActiveSupport::TestCase


test "should successfully fetch next SOTA" do
  asset1=create_test_asset(asset_type: 'summit', code: 'ZL3/SL-001')
  asset2=create_test_asset(asset_type: 'summit', code: 'ZL3/SL-002')

  as=AdminSettings.first
  as.update_column(:last_sota_update_id, asset1.code)
  assert_difference 'ExternalActivation.count', 1 do
    VCR.use_cassette("external_activation/fetch_sota") do
      # Run the controller action or model method that makes the real HTTP call
      ExternalActivation.import_next_sota
    end
  end

  ea = ExternalActivation.last
  assert_equal ea.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"callsign" => "ZL4NVW", "summit_code" => "ZL3/SL-002", "summit_sota_id" => nil, "date" => "2021-11-24".to_date, "qso_count" => 10, "user_id" => nil, "external_activation_id" => 584186, "asset_type" => "summit"},
    "Got activation from SOTA"
 
  ecs = ExternalChase.all
  assert_equal ecs.count, 6, "Got 6 chases" 
  assert_equal ecs.first.attributes.excluding(["created_at", "updated_at", "id", "user_id", "external_activation_id" ]),
    {"callsign" => "ZL1BQD", "summit_code" => "ZL3/SL-002", "summit_sota_id" => nil, "band" => "5MHz", "mode" => "SSB", "date" => "2021-11-24".to_date, "time" => "2000-01-01 01:45:00".to_time, "asset_type" => "summit"},
    "Got first chase from SOTA"
  assert_equal ecs.last.attributes.excluding(["created_at", "updated_at", "id", "user_id", "external_activation_id" ]),
    {"callsign" => "ZL3GA", "summit_code" => "ZL3/SL-002", "summit_sota_id" => nil, "band" => "7MHz", "mode" => "SSB", "date" => "2021-11-24".to_date, "time" => "2000-01-01 02:02:00".to_time, "asset_type" => "summit"}
    "Got last chase from SOTA"

end

test "should successfully fetch next POTA" do
  asset1=create_test_asset(asset_type: 'pota park', code: 'NZ-0001')
  asset2=create_test_asset(asset_type: 'pota park', code: 'NZ-0002')

  as=AdminSettings.first
  as.update_column(:last_pota_update_id, asset1.code)
  assert_difference 'ExternalActivation.count', 7 do
    VCR.use_cassette("external_activation/fetch_pota") do
      # Run the controller action or model method that makes the real HTTP call
      ExternalActivation.import_next_pota
    end
  end

  ea = ExternalActivation.first
  assert_equal ea.attributes.excluding(["created_at", "updated_at", "id", "user_id", "external_activation_id" ]),
    {"callsign" => "ZL1RDK", "summit_code" => "NZ-0002", "summit_sota_id" => nil, "date" => "2026-01-02".to_date, "qso_count" => 23, "asset_type" => "pota park"}
    "Got activation from POTA"
  ea = ExternalActivation.last
  assert_equal ea.attributes.excluding(["created_at", "updated_at", "id", "user_id", "external_activation_id" ]),
    {"callsign" => "ZL1BQD", "summit_code" => "NZ-0002", "summit_sota_id" => nil, "date" => "2022-06-23".to_date, "qso_count" => 55, "asset_type" => "pota park"}
    "Got activation from POTA"
end

end
