require "test_helper"

class ExternalAlertTest < ActiveSupport::TestCase


test "should successfully fetch data from external APIs" do
  ExternalAlert.destroy_all

  VCR.use_cassette("external_alert/fetch_success") do
    # Run the controller action or model method that makes the real HTTP call
    ExternalAlert.fetch
  end

  sota = ExternalAlert.where(programme: 'SOTA')
  wwff = ExternalAlert.where(programme: 'WWFF')
  pota = ExternalAlert.where(programme: 'POTA')

  assert_equal sota.count, 295, 'Got 295 SOTA records'
  assert_equal sota.first.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"starttime" => "2026-08-28 16:20:00.000000000 UTC +00:00", "activatingCallsign" => "EB2GKK/P", "code" => "EA2/NV-140", "name" => "Monteidorra, 831m, 2 pts", "frequency" => "14-cw", "comments" => "73! (de EB2GKK)", "mode" => nil, "programme" => "SOTA", "duration" => "1", "dxcc" => "EA", "continent" => "EU"},
    "Got correct 1st SOTA spot"
  assert_equal sota.last.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"starttime" => "2028-12-01 12:00:00.000000000 UTC +00:00", "activatingCallsign" => "NG2E", "code" => "W4V/HB-008", "name" => "Cow Knob, 1230m, 10 pts", "frequency" => "20-cw, 40-cw, 146-fm", "comments" => " (de NG2E)", "mode" => nil, "programme" => "SOTA", "duration" => "1", "dxcc" => nil, "continent" => nil},

    "Got correct last SOTA spot"

  assert_equal wwff.count, 26, 'Got 26 WWFF records'
  assert_equal wwff.first.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"starttime" => "2026-08-01 10:00:00.000000000 UTC +00:00", "activatingCallsign" => "ZX2O", "code" => "PYFF-0362", "name" => "[PYFF-0362]", "frequency" => "40m, 20m, 17m, 15m, 12m, 10m", "comments" => " (de PY2TIM)", "mode" => "CW, FT8", "programme" => "WWFF", "duration" => "709.0", "dxcc" => "PY", "continent" => "SA"},
    "Got correct 1st WWFF spot"
  assert_equal wwff.last.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"starttime" => "2026-09-08 13:00:00.000000000 UTC +00:00", "activatingCallsign" => "OU7M/P", "code" => "OZFF-0012", "name" => "[OZFF-0012]", "frequency" => "80m, 40m, 20m, 15m, 10m", "comments" => "EDR Fieldday - PSE RS(T) + Serie no (de OZ7AEI)", "mode" => "SSB, CW, FT8", "programme" => "WWFF", "duration" => "24.0", "dxcc" => "OZ", "continent" => "EU"},
    "Got correct last WWFF spot"

  assert_equal pota.count, 100, 'Got 100 POTA records'
  assert_equal pota.first.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"starttime" => "2026-02-15 20:25:00.000000000 UTC +00:00", "activatingCallsign" => "K2AYE", "code" => "US-3812", "name" => "Fleming Wildlife Management Area", "frequency" => "20 meter", "comments" => "", "mode" => "", "programme" => "POTA", "duration" => "5686.566666666667", "dxcc" => "US", "continent" => "EU"},
    "Got correct 1st POTA spot"
  assert_equal pota.last.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"starttime" => "2027-04-17 00:00:00.000000000 UTC +00:00", "activatingCallsign" => "N6EF", "code" => "US-3432", "name" => "Folsom Lake State Recreation Area", "frequency" => "40 to 10 CW, SSB, FT8", "comments" => "Camping for Support Your Parks weekend", "mode" => "", "programme" => "POTA", "duration" => "40.0", "dxcc" => "US", "continent" => "EU"},
    "Got correct last POTA spot"

  #check repull does not trigger duplicates
  assert_no_difference 'ExternalAlert.count' do
    VCR.use_cassette("external_alert/fetch_success") do
      # Run the controller action or model method that makes the real HTTP call
      ExternalAlert.fetch
    end
  end
end

test "should include local alerts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    t1 = Time.now.floor
    item=create_test_alert(user2, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, referenced_time: t1, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment")


    hota_alerts = Post.find_by_sql [ " select p.*, i.id as item_id from posts p inner join items i on i.item_id=p.id and i.topic_id=1 and i.item_type='post' and ((p.referenced_date + interval '1 hours' * duration::numeric) > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}' or p.referenced_date > '#{(Time.now - 1.days).strftime("%Y-%m-%d %H:%M")}')" ]

    ea = ExternalAlert.import_hota_alerts(hota_alerts)

    assert_equal ea.first.attributes.excluding(["created_at", "updated_at", "id" ]),
      {"starttime" => t1, "activatingCallsign" => "ZL4AAAB", "code" => "[\"ZLH/ZZ-001\", \"ZLH/ZZ-002\"]", "name" => "place-AAAA [ZLH/ZZ-001] {}; place-AAAB [ZLH/ZZ-002] {}; ", "frequency" => "7.09", "comments" => "This is a comment", "mode" => "SSB", "programme" => "ZLOTA", "duration" => "1", "dxcc" => "ZL", "continent" => "OC"},
    "External alerts list internal alert"

end

end
