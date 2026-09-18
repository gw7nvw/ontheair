# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpSpotTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/ALL
  ##################################################################
  test "Can post a spot - vkportalog style" do
    user1=create_test_user(activated: true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2, code_prefix: 'ZLFF-0')

    #  raw JSON treated as URL-encoded key
    malformed_payload = %Q{{"actClass":"ZLOTA","actSite":"#{asset1.code}","actCallsign":"ZL4TEST","freq":"7.000","mode":"SSB","comments":"test","userID":"#{user1.callsign}","APIKey":"#{user1.pin}"}}

    # Forcing the form content-type triggers the exact bug
    assert_difference 'ConsolidatedSpot.count', 1, "Expected 1 new Consolidated Spot" do 
    post '/api/SPOT',
         params: malformed_payload,
         headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }
    end

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal true, data["success"]

    cs=ConsolidatedSpot.last

    assert_equal [user1.callsign], cs.callsign 
    assert_equal "ZL4TEST", cs.activatorCallsign 
    assert_equal [asset1.code, asset2.code].sort, cs.code.sort
    assert_equal ["#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}"], cs.name 
    assert_equal "7.0", cs.frequency
    assert_equal "SSB", cs.mode
    assert_match /#{user1.callsign}: test (.+)/, cs.comments.first
    assert_equal ["ZLOTA", "POTA"], cs.spot_type
    assert_equal "40m", cs.band 
    assert_equal "ZL", cs.dxcc
    assert_equal "OC", cs.continent
  end

  test "Can post a spot - iPnP style" do
    user1=create_test_user(activated: true)
    malformed_payload = %Q{{"actClass":"SOTA","wwffID":"","comments":"test *[iPnP]","mode":"SSB","userID":"#{user1.callsign}","actSite":"ZL3\/OT-288","APIKey":"#{user1.pin}","freq":"7.0","actCallsign":"ZL4TEST"}}
    assert_difference 'ConsolidatedSpot.count', 1, "Expected 1 new Consolidated Spot" do 
      post '/api/SPOT',
         params: malformed_payload
    end

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal true, data["success"]

    cs=ConsolidatedSpot.last

    assert_equal [user1.callsign], cs.callsign 
    assert_equal "ZL4TEST", cs.activatorCallsign 
    assert_equal ["ZL3/OT-288"], cs.code
    assert_equal ["ZL3/OT-288 [ZL3/OT-288]"], cs.name 
    assert_equal "7.0", cs.frequency
    assert_equal "SSB", cs.mode
    assert_match /#{user1.callsign}: test \*\[iPnP\] \(.+\)/, cs.comments.first
    assert_equal ["SOTA"], cs.spot_type
    assert_equal "40m", cs.band 
    assert_equal "ZL", cs.dxcc
    assert_equal "OC", cs.continent
  end
end
