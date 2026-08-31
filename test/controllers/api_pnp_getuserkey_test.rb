# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpGetuserkeyTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/GETUSERKEY
  ##################################################################
  test "Should get api/getuserkey with APIKey" do
    user1=create_test_user
    user1.update_column(:pnp_APIKey, '123456780123456')
    user1.update_column(:pnp_imported, true)

    get "/api/GETUSERKEY/#{user1.callsign}/#{user1.pnp_APIKey}"

    assert_response :success

    data = @response.body
    assert_equal data, user1.pin, "Should return user PIN"
  end

  test "Should get api/getuserkey with pin" do
    user1=create_test_user
    user1.update_column(:pin, '1234')
    user1.update_column(:activated, true)

    get "/api/GETUSERKEY/#{user1.callsign}/#{user1.pin}"

    assert_response :success

    data = @response.body
    assert_equal data, user1.pin, "Should return user PIN"
  end

  test "Should get rejected by api/getuserkey with wrong APIKey" do
    user1=create_test_user
    user1.update_column(:pnp_APIKey, '123456780123456')
    user1.update_column(:pnp_imported, true)

    get "/api/GETUSERKEY/#{user1.callsign}/6543210987654321"

    assert_response :success

    data = @response.body
    assert_equal data, "false", "Should return false"
  end
end
