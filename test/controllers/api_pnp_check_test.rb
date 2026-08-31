# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpCheckTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/CHECK
  ##################################################################
  test "Should get api/CHECK last update details" do
    user1 = create_test_user 
    sleep 1
    hut=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    sleep 1
    wwff=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.3,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-0')
    pota=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.9,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    sleep 1
    sota=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.5,-45.2), code_prefix: 'ZL3/OT-')
    sleep 1
    zlota_spot=create_test_external_spot(user1, code: hut.code, activatorCallsign: user1.callsign, frequency: "7.09", mode: "SSB", spot_type: "ZLOTA")
    zlota_cs=ConsolidatedSpot.last
    sleep 1
    wwff_spot=create_test_external_spot(user1, code: wwff.code, activatorCallsign: user1.callsign, frequency: "14.09", mode: "SSB", spot_type: "WWFF")
    wwff_cs=ConsolidatedSpot.last
    sleep 1
    sota_spot=create_test_external_spot(user1, code: sota.code, activatorCallsign: user1.callsign, frequency: "21.09", mode: "SSB", spot_type: "SOTA")
    sota_cs=ConsolidatedSpot.last

    get "/api/CHECK"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["Class"] }
    assert_equal data.count, 13
    assert_equal data[0]["LastUpdate"].to_i, sota_cs.updated_at.to_i, "Activations last update"
    assert_equal data[1]["LastUpdate"].to_i, sota_cs.updated_at.to_i, "Activations last update"
    assert_equal data[2]["LastUpdate"].to_i, 1682308190, "IOTA last updated (hardcoded)"
    assert_equal data[3]["LastUpdate"].to_i, sota_cs.updated_at.to_i, "SOTA activations last updated"
    assert_equal data[4]["LastUpdate"].to_i, wwff_cs.updated_at.to_i, "WWFF activations last updated"
    assert_equal data[5]["LastUpdate"].to_i, wwff.updated_at.to_i, "PARKS (WWFF) sites last updated"
    assert_equal data[6]["LastUpdate"].to_i, pota.updated_at.to_i, "POTA sites last updated"
    assert_equal data[7]["LastUpdate"].to_i, 1781422821, "SHIRES activations last updated (hardcoded)"
    assert_equal data[8]["LastUpdate"].to_i, sota.updated_at.to_i, "sites last updated"
    assert_equal data[9]["LastUpdate"].to_i, sota.updated_at.to_i, "SOTA sites last updated"
    assert_equal data[10]["LastUpdate"].to_i, 0, "USERS last updated (hardcoded to 0)"
    assert_equal data[11]["LastUpdate"].to_i, wwff.updated_at.to_i, "PARKS (WWFF) activations last updated"
    assert_equal data[12]["LastUpdate"].to_i, hut.updated_at.to_i, "ZLOTA SITES last updated"
  end
end
