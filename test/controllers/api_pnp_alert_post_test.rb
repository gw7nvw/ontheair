# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpAlertPostTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/ALERT
  ##################################################################
  test "Can post an alert - vkportalog style" do
    user1=create_test_user(activated: true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2, code_prefix: 'ZLFF-0')

    #  raw JSON treated as URL-encoded key
    malformed_payload = %Q{{"userID":"#{user1.callsign}","actComments":"test","alDate":"#{3.days.from_now.strftime("%Y-%m-%d")}","actFreq":"7.0","APIKey":"#{user1.pin}","actMode":"SSB","alTime":"00:30","actCallsign":"#{user2.callsign}","actSite":"#{asset1.code}"}}
    # Forcing the form content-type triggers the exact bug
    assert_difference 'Post.count', 1, "Expected 1 new Consolidated Spot" do 
    post '/api/ALERT',
         params: malformed_payload,
         headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }
    end

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal true, data["success"]

    post=Post.last

    assert_equal user2.callsign, post.callsign, "Activator callsign"
    assert_equal user1.id, post.created_by_id, "Poster callsign"
    assert_equal '7.0', post.freq, "Freq"
    assert_equal 'SSB', post.mode, "Mode"
    assert_equal 1, post.duration, "duration"
    assert_equal 3.days.from_now.strftime("%Y-%m-%d"), post.referenced_date.strftime('%Y-%m-%d'), "eDate"
    assert_equal "00:30", post.referenced_time.strftime('%H:%M'), "Time"
    assert_equal [asset1.code, asset2.code].sort, post.asset_codes.sort, "Codes"
  end

  test "Can post an alert - iPnP style" do
    user1=create_test_user(activated: true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2, code_prefix: 'ZLFF-0')

    #  raw JSON treated as URL-encoded key
    malformed_payload = %Q{{"userID":"#{user1.callsign}","actComments":"test","alDate":"#{3.days.from_now.strftime("%Y-%m-%d")}","actFreq":"7.0","APIKey":"#{user1.pin}","actMode":"SSB","alTime":"00:30","actCallsign":"#{user2.callsign}","actSite":"#{asset1.code}"}}
    # Forcing the form content-type triggers the exact bug
    assert_difference 'Post.count', 1, "Expected 1 new Consolidated Spot" do 
    post '/api/ALERT',
         params: malformed_payload
    end

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal true, data["success"]

    post=Post.last

    assert_equal user2.callsign, post.callsign, "Activator callsign"
    assert_equal user1.id, post.created_by_id, "Poster callsign"
    assert_equal '7.0', post.freq, "Freq"
    assert_equal 'SSB', post.mode, "Mode"
    assert_equal 1, post.duration, "duration"
    assert_equal 3.days.from_now.strftime("%Y-%m-%d"), post.referenced_date.strftime('%Y-%m-%d'), "eDate"
    assert_equal "00:30", post.referenced_time.strftime('%H:%M'), "Time"
    assert_equal [asset1.code, asset2.code].sort, post.asset_codes.sort, "Codes"
  end
end
