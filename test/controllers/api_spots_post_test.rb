# typed: false
require "test_helper"
include ApplicationHelper
class ApiSpotsPostTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/assets
  ##################################################################
  test "Should be able to post a spot with username/pin" do
    user1=create_test_user
    user1.update_column(:activated, true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)


    spot_payload = {
      userID: user1.callsign,
      APIKey: user1.pin,
      do_not_lookup: "true",
      activator: "ZL2TEST",
      spotter: user1.callsign,
      reference: asset1.code,
      frequency: "7090",
      mode: "SSB",
      comments: "testing spotting API"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "API failed to insert spot" do
      res = post "/api/spots",
           params: spot_payload,
           as: "json"
    end

    assert_response :success

    spot=ConsolidatedSpot.last
    assert_equal spot.attributes.excluding(["id", "time", "comments", "post_id", "created_at", "updated_at"]), 
      {"callsign" => [user1.callsign], "activatorCallsign" => "ZL2TEST", "code" => [asset1.code], "name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"], "frequency" => "7.09", "mode" => "SSB", "spot_type" => ["ZLOTA"], "points" => nil, "altM" => nil, "old_spot_type" => [], "band" => "40m", "dxcc" => "ZL", "continent" => "OC"}
      "first row should match"
      assert_match /#{user1.callsign}: testing spotting API \(.+\)/, spot.comments.first
  end

  test "Should be able to post a spot with username/APIKey" do
    user1=create_test_user
    user1.update_column(:pnp_imported, true)
    user1.update_column(:pnp_APIKey, "1234567890123456")

    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)

    spot_payload = {
      userID: user1.callsign,
      APIKey: user1.pnp_APIKey,
      do_not_lookup: "true",
      activator: "ZL2TEST",
      spotter: user1.callsign,
      reference: asset1.code,
      frequency: "7090",
      mode: "SSB",
      comments: "testing spotting API"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "API failed to insert spot" do
      res = post "/api/spots",
           params: spot_payload,
           as: "json"
    end

    assert_response :success

    spot=ConsolidatedSpot.last
    assert_equal spot.attributes.excluding(["id", "time", "comments", "post_id", "created_at", "updated_at"]),
      {"callsign" => [user1.callsign], "activatorCallsign" => "ZL2TEST", "code" => [asset1.code], "name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"], "frequency" => "7.09", "mode" => "SSB", "spot_type" => ["ZLOTA"], "points" => nil, "altM" => nil, "old_spot_type" => [], "band" => "40m", "dxcc" => "ZL", "continent" => "OC"}
      "first row should match"
      assert_match /#{user1.callsign}: testing spotting API \(.+\)/, spot.comments.first

  end

  test "Should NOT be able to post a spot with username/pin if not activated" do
    user1=create_test_user
    user2=create_test_user
    user1.update_column(:pnp_imported, true)
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)


    spot_payload = {
      userID: user1.callsign,
      APIKey: user1.pin,
      do_not_lookup: "true",
      activator: "ZL2TEST",
      spotter: user1.callsign,
      reference: asset1.code,
      frequency: "7090",
      mode: "SSB",
      comments: "testing spotting API"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_no_difference 'ConsolidatedSpot.count', "API should not have inserted spot" do
      res = post "/api/spots",
           params: spot_payload,
           as: "json"
    end
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res["success"], false, "Success should be false"
    assert_equal res["message"], "Authentication failed!", "message should indicate fail reason"
  end

  test "Should NOT be able to post a spot with username/APIKey if not imported" do
    user1=create_test_user
    user2=create_test_user
    user1.update_column(:activated, true)
    user1.update_column(:pnp_APIKey, "1234567890123456")

    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)

    spot_payload = {
      userID: user1.callsign,
      APIKey: user1.pnp_APIKey,
      do_not_lookup: "true",
      activator: "ZL2TEST",
      spotter: user1.callsign,
      reference: asset1.code,
      frequency: "7090",
      mode: "SSB",
      comments: "testing spotting API"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_no_difference 'ConsolidatedSpot.count', "API should not have inserted spot" do
      res = post "/api/spots",
           params: spot_payload,
           as: "json"
    end
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res["success"], false, "Success should be false"
    assert_equal res["message"], "Authentication failed!", "message should indicate fail reason"

  end

  test "Should only post to test spots if DEBUG specified" do
    user1=create_test_user
    user1.update_column(:activated, true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)


    spot_payload = {
      userID: user1.callsign,
      APIKey: user1.pin,
      do_not_lookup: "true",
      activator: "ZL2TEST",
      spotter: user1.callsign,
      reference: asset1.code,
      frequency: "7090",
      mode: "SSB",
      comments: "DEBUG testing spotting API"
    }

    # 2. Assert that posting this payload does not create an ExternalSpot record
    assert_difference 'Post.count', 1, "API should create a test spot" do
      assert_no_difference 'ConsolidatedSpot.count', "API should not have inserted a spot" do
        res = post "/api/spots",
           params: spot_payload,
           as: "json"
      end
    end

    assert_response :success
    
    spot=Post.last
    assert_equal spot.attributes.excluding(["id", "time", "comments", "post_id", "created_at", "updated_at", "referenced_date", "referenced_time", "referenced_datetime", "title"]), 
      {"description" => "DEBUG testing spotting API", "created_by_id" => user1.id, "updated_by_id" => user1.id, "filename" => nil, "image_file_name" => nil, "image_content_type" => nil, "image_file_size" => nil, "image_updated_at" => nil, "do_not_publish" => nil, "duration" => nil, "site" => "#{asset1.name} [#{asset1.code}] {RE44nt}", "code" => nil, "mode" => "SSB", "freq" => "7.09", "is_hut" => nil, "is_park" => nil, "is_island" => nil, "is_summit" => nil, "hut" => nil, "park" => nil, "island" => nil, "summit" => nil, "callsign" => "ZL2TEST", "asset_codes" => [asset1.code], "user_id" => nil, "do_not_lookup" => true, "location" => nil, "loc_source" => nil}
      "first row should match"
      assert_equal spot.topic_id, TEST_SPOT_TOPIC
      assert_match /SPOT: ZL2TEST spotted portable at #{asset1.name} \[#{asset1.code}\] on 7.09\/SSB at .+/, spot.title

  end


  test "Should be able to post a spot with lookup of containing assets" do
    user1=create_test_user
    user1.update_column(:activated, true)
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)


    spot_payload = {
      userID: user1.callsign,
      APIKey: user1.pin,
      activator: "ZL2TEST",
      spotter: user1.callsign,
      reference: asset1.code,
      frequency: "7090",
      mode: "SSB",
      comments: "testing spotting API"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "API failed to insert spot" do
      res = post "/api/spots",
           params: spot_payload,
           as: "json"
    end

    assert_response :success
    assert_equal JSON.parse(@response.body)["success"], true, "Success should be true"
 
    spot=ConsolidatedSpot.last
    assert_equal spot.attributes.excluding(["id", "time", "comments", "post_id", "created_at", "updated_at"]), 
      {"callsign" => [user1.callsign], "activatorCallsign" => "ZL2TEST", "code" => [asset1.code, asset2.code], "name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}"], "frequency" => "7.09", "mode" => "SSB", "spot_type" => ["ZLOTA", "ZLOTA"], "points" => nil, "altM" => nil, "old_spot_type" => [], "band" => "40m", "dxcc" => "ZL", "continent" => "OC"}
      "first row should match"
      assert_match /#{user1.callsign}: testing spotting API \(.+\)/, spot.comments.first
  end

end
