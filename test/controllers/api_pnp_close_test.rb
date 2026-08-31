# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpCheckTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/CLOSE (as in near) get nearest 10 sites in each cetegory
  ##################################################################
  test "Should get api/CLOSE details" do
    user1 = create_test_user 
    sleep 1
    count = 0
    hut=[]
    for long in 1690..1702 do
      hut[count]=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(1.0*long/10,-45.2))
      count+=1
    end
    wwff=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(171.8,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-0')
    pota=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(171.9,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    sota=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(180.0,-45.2), code_prefix: 'ZL3/OT-')

    get "/api/CLOSE/-45.2/169.0"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 13
    assert_equal data[0]["siteID"], hut[0].code
    assert_equal data[0]["siteDistance"], "0.00km "
    assert_equal data[0]["siteDistanceNumeric"], "0.0"
    assert_equal data[0]["awardID"], "ZLOTA"
    assert_equal data[0]["siteName"], hut[0].name
    assert_equal data[1]["siteID"], hut[1].code
    assert_equal data[1]["siteDistance"], "7.84km E"
    assert_equal data[9]["siteID"], hut[9].code
    assert_equal data[9]["siteDistance"], "70.52km E"
    assert_equal data[10]["siteID"], wwff.code
    assert_equal data[11]["siteID"], pota.code
    assert_equal data[12]["siteID"], sota.code
  end
end
