# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpXxxIdTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/WITHIN 
  ##################################################################
  test "Should get api/WITHIN details" do
    asset1 = create_test_asset(asset_type: 'summit', location: create_point(173.7764, -41.7529), code_prefix: 'ZL3/MB-')
    asset2 = create_test_asset(asset_type: 'wwff park', location: create_point(173.7764, -41.7529), code_prefix: 'ZLFF-0', test_radius: 0.1)
    asset3 = create_test_asset(asset_type: 'wwff park', location: create_point(173.7764, -41.7529), code_prefix: 'ZLFF-0', test_radius: 0.2)
    asset4 = create_test_asset(asset_type: 'pota park', location: create_point(173.7764, -41.7529), code_prefix: 'NZ-0', test_radius: 0.1)
    asset5 = create_test_asset(asset_type: 'pota park', location: create_point(173.7764, -41.7529), code_prefix: 'NZ-0', test_radius: 0.2)
    #Test inside  the AZ
    get "/api/WITHIN/-41.7530/173.7765"
    assert_response :success
    data = JSON.parse(response.body)
    data = data.sort_by{|d| d["code"]}
    assert_equal 5, data.count
    assert_equal asset4.code, data[0]["code"]
    assert_equal asset5.code, data[1]["code"]
    assert_equal asset1.code, data[2]["code"]
    assert_equal asset1.name, data[2]["name"]
    assert_equal 'summit', data[2]["class"]
    assert_equal 'SOTA', data[2]["award"]

    assert_equal asset2.code, data[3]["code"]
    assert_equal asset3.code, data[4]["code"]
    
    #TEst outside the AZ
    get "/api/WITHIN/-41.7530/173.7739"
    assert_response :success
    data = JSON.parse(response.body)
    data = data.sort_by{|d| d["code"]}
    assert_equal 4, data.count
    assert_equal asset4.code, data[0]["code"]
    assert_equal asset5.code, data[1]["code"]
    assert_equal asset2.code, data[2]["code"]
    assert_equal asset3.code, data[3]["code"]
    #No summit, but in parks
  end
end
