# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpCallsignTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/CALLSIGN 
  ##################################################################
  test "Should get api/CALLSIGN details" do
    user1 = create_test_user({firstname: 'bob', activated: true})
    user2 = create_test_user({firstname: 'colin', activated: false})

    get "/api/CALLSIGN"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by{|d| d["callSign"]}
    assert_equal data.count, 4, "Should get 3 built un users, an user1, but not user2"
    assert_equal data[0]["callSign"], "ZL3CC"
    assert_equal data[0]["name"], "Bob"
    assert_equal data[1]["callSign"], user1.callsign
    assert_equal data[1]["name"], user1.firstname
    assert_equal data[2]["callSign"], "ZL4NVW"
    assert_equal data[3]["callSign"], "ZL4TEST"
  end
end
