# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpVerifyuserTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/VERIFYUSER
  ##################################################################
  test "Should get api/verifyuser with APIKey" do
    user1=create_test_user
    user1.update_column(:pnp_APIKey, '123456780123456')
    user1.update_column(:pnp_imported, true)

    get "/api/VERIFYUSER/#{user1.callsign}/#{user1.pnp_APIKey}"

    assert_response :success

    data = @response.body
    assert_equal data, '"TRUE"', 'Should return user "TRUE"'
  end

  test "Should get api/getuserkey with pin" do
    user1=create_test_user
    user1.update_column(:pin, '1234')
    user1.update_column(:activated, true)

    get "/api/VERIFYUSER/#{user1.callsign}/#{user1.pin}"

    assert_response :success

    data = @response.body
    assert_equal data, '"TRUE"', 'Should return user "TRUE"'
  end

  test "Should get rejected by api/getuserkey with wrong APIKey" do
    user1=create_test_user
    user1.update_column(:pnp_APIKey, '123456780123456')
    user1.update_column(:pnp_imported, true)

    get "/api/VERIFYUSER/#{user1.callsign}/6543210987654321"

    assert_response :success

    data = @response.body
    assert_equal data, '"FALSE"', 'Should return user "FALSE"'
  end
end
