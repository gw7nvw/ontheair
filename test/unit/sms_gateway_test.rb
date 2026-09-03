# test/integration/sms_webhook_test.rb
require 'test_helper'

class SmsGatewayTest < ActionDispatch::IntegrationTest

  test "should handle SOTA-Style SPOT with SPOT prefix" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')
  
    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')


    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')
    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "SPOT #{user1.callsign} #{sota_prefix} #{sota_suffix} 7.085 SSB SOTA *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "The webhook failed to process the SMS spot" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal newest_spot.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"callsign" => ["#{user1.callsign}"],"activatorCallsign" => "#{user1.callsign}","code" => [asset1.code],"name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"],"frequency" => "7.085","mode" => "SSB","spot_type" => ["SOTA"],"points" => nil,"altM" => nil,"old_spot_type" => [],"band" => "40m","dxcc" => "ZL","continent" => "OC"},
    "Wrong parameters in spot"
  end

  test "should return a bad request or ignore if crucial fields are missing" do
    invalid_payload = { sim: "sim1", text: "BROKEN SPOT" } # Missing the :from key

    post "/posts/sms", params: invalid_payload, as: :json

    # Assert that your application drops or rejects bad payloads gracefully
    assert_response :success # Or :success, depending on how your code treats skips
    json_response = JSON.parse(@response.body)
    assert_equal "failed", json_response["result"], "Should have returned failed"
  end


  test "should handle ZLOTA-Style SPOT with no prefix" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')
  
    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')


    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')
    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "#{user1.callsign} #{asset1.code} 7.085 SSB SOTA *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "The webhook failed to process the SMS spot" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal newest_spot.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"callsign" => ["#{user1.callsign}"],"activatorCallsign" => "#{user1.callsign}","code" => [asset1.code],"name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"],"frequency" => "7.085","mode" => "SSB","spot_type" => ["SOTA"],"points" => nil,"altM" => nil,"old_spot_type" => [],"band" => "40m","dxcc" => "ZL","continent" => "OC"},
    "Wrong parameters in spot"
  end

  test "should handle PnP-Style SPOT with no prefix" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')

    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')


    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')
    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "#{user1.callsign} SOTA #{asset1.code} 7.085 SSB SOTA *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "The webhook failed to process the SMS spot" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal newest_spot.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"callsign" => ["#{user1.callsign}"],"activatorCallsign" => "#{user1.callsign}","code" => [asset1.code],"name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"],"frequency" => "7.085","mode" => "SSB","spot_type" => ["SOTA"],"points" => nil,"altM" => nil,"old_spot_type" => [],"band" => "40m","dxcc" => "ZL","continent" => "OC"},
    "Wrong parameters in spot"
    assert_match /#{user1.callsign}: SOTA \*\[iPnP\] \(via SMS\) \(.+\)/, newest_spot.comments.first
  end

  test "should handle SOTA-Style SPOT with ! as callsign" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')

    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')


    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')
    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "! #{sota_prefix} #{sota_suffix} 7.085 SSB SOTA *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "The webhook failed to process the SMS spot" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal newest_spot.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"callsign" => ["#{user1.callsign}"],"activatorCallsign" => "#{user1.callsign}","code" => [asset1.code],"name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"],"frequency" => "7.085","mode" => "SSB","spot_type" => ["SOTA"],"points" => nil,"altM" => nil,"old_spot_type" => [],"band" => "40m","dxcc" => "ZL","continent" => "OC"},
    "Wrong parameters in spot"
  end

  test "should handle SOTA-Style SPOT with $ as callsign" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')

    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')


    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')
    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "$ #{sota_prefix} #{sota_suffix} 7.085 SSB SOTA *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'ConsolidatedSpot.count', 1, "The webhook failed to process the SMS spot" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal newest_spot.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"callsign" => ["#{user1.callsign}"],"activatorCallsign" => "#{user1.callsign}","code" => [asset1.code],"name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"],"frequency" => "7.085","mode" => "SSB","spot_type" => ["SOTA"],"points" => nil,"altM" => nil,"old_spot_type" => [],"band" => "40m","dxcc" => "ZL","continent" => "OC"},
    "Wrong parameters in spot"
  end

  test "should handle SOTA-Style ALERT with $ as callsign" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')

    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')


    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')
    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "ALERT $ #{sota_prefix} #{sota_suffix} 7.085 SSB 2022-01-01 12:00 SOTA *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'Post.count', 1, "The webhook failed to process the SMS alert" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_alert = Post.order(created_at: :desc).first
    assert_equal newest_alert.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"title" => "ALERT: #{user1.callsign} going portable to #{asset1.name} [#{asset1.code}] on 7.085/SSB at 2022-01-01 12:00 UTC", "description" => "SOTA *[iPnP] (via SMS)", "created_by_id" => user1.id, "updated_by_id" => user1.id, "filename" => nil, "image_file_name" => nil, "image_content_type" => nil, "image_file_size" => nil, "image_updated_at" => nil, "do_not_publish" => nil, "referenced_datetime" => nil, "referenced_date" => "2022-01-01".to_date, "referenced_time" => "2022-01-01 12:00:00.000000000 UTC +00:00".to_time, "duration" => 1, "site" => "#{asset1.name} [#{asset1.code}] {RE44nt}", "code" => nil, "mode" => "SSB", "freq" => "7.085", "is_hut" => nil, "is_park" => nil, "is_island" => nil, "is_summit" => nil, "hut" => nil, "park" => nil, "island" => nil, "summit" => nil, "callsign" => user1.callsign, "asset_codes" => [asset1.code], "user_id" => nil, "do_not_lookup" => nil, "location" => nil, "loc_source" => nil},
    "Wrong parameters in alert"
  end

  test "should handle PnP-Style ALERT with ! as callsign" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')

    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')


    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')
    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "ALERT ! SOTA #{asset1.code} 7.085 SSB 2022-01-01 12:00 SOTA *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'Post.count', 1, "The webhook failed to process the SMS alert" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_alert = Post.order(created_at: :desc).first
    assert_equal newest_alert.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"title" => "ALERT: #{user1.callsign} going portable to #{asset1.name} [#{asset1.code}] on 7.085/SSB at 2022-01-01 12:00 UTC", "description" => "SOTA *[iPnP] (via SMS)", "created_by_id" => user1.id, "updated_by_id" => user1.id, "filename" => nil, "image_file_name" => nil, "image_content_type" => nil, "image_file_size" => nil, "image_updated_at" => nil, "do_not_publish" => nil, "referenced_datetime" => nil, "referenced_date" => "2022-01-01".to_date, "referenced_time" => "2022-01-01 12:00:00.000000000 UTC +00:00".to_time, "duration" => 1, "site" => "#{asset1.name} [#{asset1.code}] {RE44nt}", "code" => nil, "mode" => "SSB", "freq" => "7.085", "is_hut" => nil, "is_park" => nil, "is_island" => nil, "is_summit" => nil, "hut" => nil, "park" => nil, "island" => nil, "summit" => nil, "callsign" => user1.callsign, "asset_codes" => [asset1.code], "user_id" => nil, "do_not_lookup" => nil, "location" => nil, "loc_source" => nil},
    "Wrong parameters in alert"
  end

  test "should look up containing parks by default for spots / alerts" do
    user1=create_test_user
    user1.update_column(:acctnumber, '+61407833843')
    user1.save

    asset1=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-')
    asset2=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.2, code_prefix: 'ZLFF-')

    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "ALERT ! WWFF #{asset1.code} 7.085 SSB 2022-01-01 12:00 WWFF n-fer *[iPnP]",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'Post.count', 1, "The webhook failed to process the SMS alert" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_alert = Post.order(created_at: :desc).first
    assert_equal newest_alert.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"title" => "ALERT: #{user1.callsign} going portable to #{asset1.name} [#{asset1.code}] on 7.085/SSB at 2022-01-01 12:00 UTC", "description" => "WWFF n-fer *[iPnP] (via SMS)", "created_by_id" => user1.id, "updated_by_id" => user1.id, "filename" => nil, "image_file_name" => nil, "image_content_type" => nil, "image_file_size" => nil, "image_updated_at" => nil, "do_not_publish" => nil, "referenced_datetime" => nil, "referenced_date" => "2022-01-01".to_date, "referenced_time" => "2022-01-01 12:00:00.000000000 UTC +00:00".to_time, "duration" => 1, "site" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}", "code" => nil, "mode" => "SSB", "freq" => "7.085", "is_hut" => nil, "is_park" => nil, "is_island" => nil, "is_summit" => nil, "hut" => nil, "park" => nil, "island" => nil, "summit" => nil, "callsign" => user1.callsign, "asset_codes" => [asset1.code, asset2.code], "user_id" => nil, "do_not_lookup" => nil, "location" => nil, "loc_source" => nil},
    "Wrong parameters in alert"
  end

  test "should look not up containing parks when /DNL present for spots / alerts" do
    user1=create_test_user
    user1.update_column(:acctnumber, '+61407833843')
    user1.save

    asset1=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-')
    asset2=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.2, code_prefix: 'ZLFF-')

    # 1. Replicate the exact JSON payload pattern from your live server log
    sms_payload = {
      from: "+61407833843",
      text: "ALERT ! WWFF #{asset1.code} 7.085 SSB 2022-01-01 12:00 WWFF single *[iPnP] /DNL",
      sentStamp: 1788041858000,
      receivedStamp: 1788041859090,
      sim: "sim1"
    }

    # 2. Assert that posting this payload creates an ExternalSpot record
    assert_difference 'Post.count', 1, "The webhook failed to process the SMS alert" do
      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end

    # 3. Assert the server returns a clean success response code back to the carrier gateway
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "success", json_response["result"], "Should have returned success"

    # 4. Deep-validate that only the exact fields you care about were parsed into your database
    newest_alert = Post.order(created_at: :desc).first
    assert_equal newest_alert.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"title" => "ALERT: #{user1.callsign} going portable to #{asset1.name} [#{asset1.code}] on 7.085/SSB at 2022-01-01 12:00 UTC", "description" => "WWFF single *[iPnP] (via SMS)", "created_by_id" => user1.id, "updated_by_id" => user1.id, "filename" => nil, "image_file_name" => nil, "image_content_type" => nil, "image_file_size" => nil, "image_updated_at" => nil, "do_not_publish" => nil, "referenced_datetime" => nil, "referenced_date" => "2022-01-01".to_date, "referenced_time" => "2022-01-01 12:00:00.000000000 UTC +00:00".to_time, "duration" => 1, "site" => "#{asset1.name} [#{asset1.code}] {RE44nt}", "code" => nil, "mode" => "SSB", "freq" => "7.085", "is_hut" => nil, "is_park" => nil, "is_island" => nil, "is_summit" => nil, "hut" => nil, "park" => nil, "island" => nil, "summit" => nil, "callsign" => user1.callsign, "asset_codes" => [asset1.code], "user_id" => nil, "do_not_lookup" => true, "location" => nil, "loc_source" => nil},
    "Wrong parameters in alert"
  end

end

