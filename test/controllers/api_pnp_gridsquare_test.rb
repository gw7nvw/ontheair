# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpGridsquareTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/GRIDSQUARE 
  ##################################################################
  test "Should get api/GRIDSQUARE maidenhead details" do
    get "/api/GRIDSQUARE/-45.29166/169.33334"
    assert_response :success
    assert_equal "RE44qr", @response.body
    get "/api/GRIDSQUARE/-45.29167/169.33334"
    assert_response :success
    assert_equal "RE44qq", @response.body
    get "/api/GRIDSQUARE/-45.29166/169.33333"
    assert_response :success
    assert_equal "RE44pr", @response.body
  end
end
