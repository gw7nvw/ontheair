require "test_helper"

class ExternalAlertTest < ActiveSupport::TestCase
test "should successfully fetch data from external APIs" do
 
  ExternalAlert.destroy_all

  VCR.use_cassette("external_alert/fetch_success") do
    # Run the controller action or model method that makes the real HTTP call
    ExternalAlert.fetch
  end

  sota = ExternalAlert.where(programme: "SOTA")
  wwff = ExternalAlert.where(programme: "WWFF")
  pota = ExternalAlert.where(programme: "POTA")

  assert_equal 295, sota.count, "Expected 295 SOTA records"
  assert_equal sota.first.attributes.excluding([ "created_at", "updated_at", "id" ]),
    { "starttime" => "2026-08-28 16:20:00.000000000 UTC +00:00".to_time, "activatingCallsign" => "EB2GKK/P", "code" => "EA2/NV-140", "name" => "Monteidorra, 831m, 2 pts", "frequency" => "14-cw", "comments" => "73! (de EB2GKK)", "mode" => nil, "programme" => "SOTA", "duration" => "1", "dxcc" => "EA", "continent" => "EU", "source" => "SOTA", "source_id" => 63948, "codes" => [ "EA2/NV-140" ] },
    "Got correct 1st SOTA salwrt"
  assert_equal sota.last.attributes.excluding([ "created_at", "updated_at", "id" ]),
    { "starttime" => "2028-12-01 12:00:00.000000000 UTC +00:00".to_time, "activatingCallsign" => "NG2E", "code" => "W4V/HB-008", "name" => "Cow Knob, 1230m, 10 pts", "frequency" => "20-cw, 40-cw, 146-fm", "comments" => " (de NG2E)", "mode" => nil, "programme" => "SOTA", "duration" => "1", "dxcc" => nil, "continent" => nil, "source" => "SOTA", "source_id" => 7123, "codes" => [ "W4V/HB-008" ] },
    "Got correct last SOTA spot"

  assert_equal wwff.count, 26, "Got 26 WWFF records"
  assert_equal wwff.first.attributes.excluding([ "created_at", "updated_at", "id" ]),
    { "starttime" => "2026-08-01 10:00:00.000000000 UTC +00:00".to_time, "activatingCallsign" => "ZX2O", "code" => "PYFF-0362", "name" => "[PYFF-0362]", "frequency" => "40m, 20m, 17m, 15m, 12m, 10m", "comments" => " (de PY2TIM)", "mode" => "CW, FT8", "programme" => "WWFF", "duration" => "709.0", "dxcc" => "PY", "continent" => "SA", "source" => "WWFF", "source_id" => 4582, "codes" => [ "PYFF-0362" ] },
    "Got correct 1st WWFF spot"
  assert_equal wwff.last.attributes.excluding([ "created_at", "updated_at", "id" ]),
    { "starttime" => "2026-09-08 13:00:00.000000000 UTC +00:00".to_time, "activatingCallsign" => "OU7M/P", "code" => "OZFF-0012", "name" => "[OZFF-0012]", "frequency" => "80m, 40m, 20m, 15m, 10m", "comments" => "EDR Fieldday - PSE RS(T) + Serie no (de OZ7AEI)", "mode" => "SSB, CW, FT8", "programme" => "WWFF", "duration" => "24.0", "dxcc" => "OZ", "continent" => "EU", "source" => "WWFF", "source_id" => 4916, "codes" => [ "OZFF-0012" ] },
    "Got correct last WWFF spot"

  assert_equal pota.count, 100, "Got 100 POTA records"
  assert_equal pota.first.attributes.excluding([ "created_at", "updated_at", "id" ]),
    { "starttime" => "2026-02-15 20:25:00.000000000 UTC +00:00".to_time, "activatingCallsign" => "K2AYE", "code" => "US-3812", "name" => "Fleming Wildlife Management Area", "frequency" => "20 meter", "comments" => "", "mode" => "", "programme" => "POTA", "duration" => "5686.566666666667", "dxcc" => "US", "continent" => "EU",  "source" => "POTA", "source_id" => 141809, "codes" => [ "US-3812" ] },
    "Got correct 1st POTA spot"
  assert_equal pota.last.attributes.excluding([ "created_at", "updated_at", "id" ]),
    { "starttime" => "2027-04-17 00:00:00.000000000 UTC +00:00", "activatingCallsign" => "N6EF", "code" => "US-3432", "name" => "Folsom Lake State Recreation Area", "frequency" => "40 to 10 CW, SSB, FT8", "comments" => "Camping for Support Your Parks weekend", "mode" => "", "programme" => "POTA", "duration" => "40.0", "dxcc" => "US", "continent" => "EU", "source" => "POTA", "source_id" => 144772, "codes" => [ "US-3432" ] },
    "Got correct last POTA spot"

  # check repull does not trigger duplicates
  assert_no_difference "ExternalAlert.count" do
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
    item=create_test_alert(user2, asset_codes: [ asset1.code, asset2.code ], callsign: user2.callsign, referenced_time: t1, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment")


    hota_alerts = Post.find_by_sql [ " select p.*, i.id as item_id from posts p inner join items i on i.item_id=p.id where i.id=#{item.id}" ]

    ea = ExternalAlert.import_hota_alerts(hota_alerts)

    assert_equal ea.first.attributes.excluding([ "created_at", "updated_at", "id" ]),
      { "starttime" => t1, "activatingCallsign" => user2.callsign, "code" => asset1.code, "name" => "#{asset1.name} [#{asset1.code}] {}; #{asset2.name} [#{asset2.code}] {}", "frequency" => "7.09", "comments" => "This is a comment", "mode" => "SSB", "programme" => "ZLOTA", "duration" => "1", "dxcc" => "ZL", "continent" => "OC", "source" => nil, "source_id" => nil, "codes" => [ asset1.code, asset2.code ] },
    "External alerts list internal alert"
end

test "Verify add -> update -> delete sequence works for external alerts" do
  second_record = <<~JSON
      {
        "id": 71430,
        "userID": 98534,
        "timeStamp": "2026-11-07T22:29:47.737788Z",
        "dateActivated": "#{1.day.from_now.beginning_of_hour.utc.iso8601}",
        "associationCode": "W2",
        "summitCode": "GM-154",
        "summitDetails": "Yet Another Mountain, 1041m, 6 pts",
        "frequency": "7-cw, 14-cw, 18-cw, 21-cw, 28-cw, 146-fm",
        "comments": "New unrelated alert",
        "activatingCallsign": "WB3LJK/P",
        "activatorName": "Kevin",
        "posterCallsign": "WB3LJK",
        "epoch": "2540eb9a-ce64-4790-bd55-997b5fdcb6e6"
      }
  JSON

  create_payload = <<~JSON
    [
      {
        "id": 71420,
        "userID": 98524,
        "timeStamp": "2026-11-07T22:28:47.737788Z",
        "dateActivated": "#{1.day.from_now.beginning_of_hour.utc.iso8601}",
        "associationCode": "W1",
        "summitCode": "GM-152",
        "summitDetails": "Ricker Mountain, 1039m, 6 pts",
        "frequency": "7-cw, 14-cw, 18-cw, 21-cw, 28-cw, 146-fm",
        "comments": null,
        "activatingCallsign": "WB2LJK/P",
        "activatorName": "Kevin",
        "posterCallsign": "WB2LJK",
        "epoch": "2540eb9a-ce64-4790-bd55-997b5fdcb6e6"
      },
      #{second_record}
    ]
  JSON
  update_payload = <<~JSON
    [
      {
        "id": 71420,
        "userID": 98524,
        "timeStamp": "2026-11-07T22:29:47.737788Z",
        "dateActivated": "#{1.day.from_now.beginning_of_hour.utc.iso8601}",
        "associationCode": "W1",
        "summitCode": "GM-153",
        "summitDetails": "Another Mountain, 1041m, 6 pts",
        "frequency": "7-cw, 14-cw, 18-cw, 21-cw, 28-cw, 146-fm",
        "comments": "Corrected reference",
        "activatingCallsign": "WB2LJK/P",
        "activatorName": "Kevin",
        "posterCallsign": "WB2LJK",
        "epoch": "2540eb9a-ce64-4790-bd55-997b5fdcb6e6"
      }, 
      #{second_record}
    ]
  JSON
  delete_payload = <<~JSON
    [#{second_record}]
  JSON
  # 1. Stub the exact API endpoint with the raw JSON text
  # 1. Stub the exact API endpoint with the raw JSON text
  stub_request(:get, "https://api-db2.sota.org.uk/api/alerts")
    .to_return([
      {
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: create_payload
      },
      {
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: update_payload
      },
      {
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: delete_payload
      }]
    )



  stub_request(:get, "https://api.pota.app/activation")
    .to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: "[]"
    )

  stub_request(:get, "https://spots.wwff.co/static/agendas.json")
    .to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: "[]"
    )

  stub_request(:get, "https://api-db2.sota.org.uk/api/alerts/epoch")
    .to_return(
        status: 200,
        headers: { 'Content-Type' => 'text/plain' },
        body: "82d0adf5-ea21-4e57-a40f-d87355e6ab04").times(1)
    .to_return(
        status: 200,
        headers: { 'Content-Type' => 'text/plain' },
        body: "82d0adf5-ea21-4e57-a40f-d87355e6ab05").times(1)
    .to_return(
        status: 200,
        headers: { 'Content-Type' => 'text/plain' },
        body: "82d0adf5-ea21-4e57-a40f-d87355e6ab06").times(1)


  # 2. Fetch the create
  assert_difference "ExternalAlert.count", 2 do
    result = ExternalAlert.fetch
  end

  ea=ExternalAlert.find_by(source_id: 71420)
  assert_equal "SOTA", ea.source
  assert_equal 71420, ea.source_id
  assert_equal "W1/GM-152", ea.code

  # 2. Fetch the update
  assert_difference "ExternalAlert.count", 0 do
    result = ExternalAlert.fetch
  end

  ea=ExternalAlert.find_by(source_id: 71420)
  assert_equal "SOTA", ea.source
  assert_equal 71420, ea.source_id
  assert_equal "W1/GM-153", ea.code

  # 2. Fetch the delete
  assert_difference "ExternalAlert.count", -1 do
    result = ExternalAlert.fetch
  end

  ea=ExternalAlert.find_by(source_id: 71420)
  assert_nil ea
end
end

