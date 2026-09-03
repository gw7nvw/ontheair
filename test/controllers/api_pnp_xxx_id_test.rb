# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpXxxIdTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/CALLSIGN 
  ##################################################################
  test "Should get api/SHIRESID details" do
    get "/api/SHIRESID/-41.5/173.5"
    assert_response :success
    assert_equal "(CD3) Central Otago [ZL-CD3]", @response.body
  end

  test "Should get api/SUMMITID details" do
    asset1 = create_test_asset(asset_type: 'summit', location: create_point(173.7764, -41.7529), code_prefix: 'ZL3-MB-')
    #Test inside  the AZ
    get "/api/SUMMITID/-41.7530/173.7765"
    assert_response :success
    assert_equal "(#{asset1.code}) #{asset1.name}", @response.body
    #TEst outside the AZ
    get "/api/SUMMITID/-41.7530/173.7739"
    assert_response :success
    assert_equal "Currently not within a summit AZ", @response.body
  end

  test "Should get api/PARKID details" do
    asset1 = create_test_asset(asset_type: 'wwff park', location: create_point(173, -41), code_prefix: 'ZLFF-0', test_radius: 0.1)
    #Test inside  the boundary
    get "/api/PARKID/-41/173.05"
    assert_response :success
    assert_equal "(#{asset1.code}) #{asset1.name}", @response.body
    #TEst outside the boundry
    get "/api/PARKID/-41/173.11"
    assert_response :success
    assert_equal "Currently not within a Park", @response.body
  end

end
