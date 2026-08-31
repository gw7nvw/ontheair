# typed: false
require "test_helper"
include ApplicationHelper
class ApiLogsPostTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/assets
  ##################################################################
  test "Should be able to post a log with username/pin" do
    user=users(:zl4test)
    uc2=create_callsign(user, {callsign: 'ZL4TEST'})
    user.update_column(:activated, true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)

    fixture_path = Rails.root.join('test', 'fixtures', 'files', 'logs', 'zl2dr.adi')
    
    # 1. Wrap the fixture into a secure Rack UploadedFile wrapper stream
    uploaded_file = Rack::Test::UploadedFile.new(fixture_path, 'application/octet-stream')

    # 2. Replicate API curl form parameters array (-F data blocks)
    multipart_payload = {
      userID: user.callsign,
      APIKey: user.pin,
      file: uploaded_file
    }

    # 3. Assert that posting this payload creates a Log record
    assert_difference 'Log.count', 1, "API failed to insert log" do
      post "/api/logs",
           params: multipart_payload
    end

    assert_response :success
    assert_equal JSON.parse(@response.body)["success"], true, "Success should be true"
 
    # 4. Verify the record properties match the parsed log
    log = Log.order(created_at: :desc).first

    #log created
    assert_equal user.id, log.user1_id, "User ID"
    assert_equal ['NZ-0001', 'ZL3/CB-001'].sort, log.asset_codes.sort, "Asset codes"
    assert_equal ['pota park', 'summit'].sort, log.asset_classes.sort, "Asset classes"
    assert_equal user.callsign, log.callsign1, "Callsign"
    assert_equal true, log.is_portable1, "Portable"

    #contacts created
    assert_equal 2, log.contacts.count, "Correct # contacts"
    contacts=log.contacts.order(:time)

    #1st entry correct
    assert_equal "10m", contacts[0].band, "Band"
    assert_equal 28.39, contacts[0].frequency, "Freq"
    assert_equal 'SSB', contacts[0].mode, "Mode"
    assert_equal "K6ARK", contacts[0].callsign2, "Callsign"
    assert_equal "2023-11-04", contacts[0].date.strftime("%Y-%m-%d"), "Date"
    assert_equal "01:32", contacts[0].time.strftime("%H:%M"), "Time"
    assert_equal "55", contacts[0].signal1, "Signal1"
    assert_equal "55", contacts[0].signal2, "Signal1"
    assert_equal ["W6/SD396"], contacts[0].asset2_codes, "Asset2_codes"
    assert_equal ['NZ-0001', 'ZL3/CB-001'], contacts[0].asset1_codes.sort, "Asset1_codes"
    assert_equal "ESTIMATED RSTS BY EAR-OMETER ON G90", contacts[0].comments1, "Comment1"

    #rest of entries exist
    assert_equal "VK4MWL", contacts[1].callsign2, "Callsign"
  end

  test "post log for another user not allowed" do
    user=create_test_user
    uc2=create_callsign(user, {callsign: 'ZL1TEST'})
    user.update_column(:activated, true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)

    fixture_path = Rails.root.join('test', 'fixtures', 'files', 'logs', 'zl2dr.adi')
    uploaded_file = Rack::Test::UploadedFile.new(fixture_path, 'application/octet-stream')

    multipart_payload = {
      userID: user.callsign,
      APIKey: user.pin,
      file: uploaded_file
    }

    assert_difference 'Log.count', 0, "API should not have inserted log" do
      post "/api/logs",
           params: multipart_payload
    end

    assert_response :success
    assert_equal JSON.parse(@response.body)["success"], false, "Success should be false"
    assert_match /Warning.+/, JSON.parse(@response.body)["message"], "But warnings should be given"
  end
end
