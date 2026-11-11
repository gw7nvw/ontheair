require "test_helper"
include ApplicationHelper
include SessionsHelper

class QrpAlertsTest < ActionDispatch::IntegrationTest
  @controller = 
  test "Can alert QRP via webpage" do
    post sessions_path, params: { session: {email: "zl4nvw", password: "dummy" } }
    assert_redirected_to root_path
    follow_redirect!

    user1=User.find_by(callsign: "ZL4NVW")
    asset1=create_test_asset(location: create_point(173.1, -43))
    asset2=create_test_asset(location: create_point(173.1, -44))

    # create post
    post posts_path, params: { topic_id: ALERT_TOPIC, pnp: "off", post: { callsign: "ZL4TEST", freq: "7.090", mode: "AM", asset_codes: "Brighton beach", is_qrp: true, description: "qrp alert", referenced_date: 1.day.from_now.strftime('%Y-%m-%d'), referenced_time: 1.day.from_now.strftime('%H:%M')  } }

    assert_response :success
    post=Post.last
    assert_select ".alert-success", /Posted/, "Success message"
    assert_equal true, post.is_qrp
    assert_equal ["BRIGHTON BEACH"], post.asset_codes
    assert_equal "BRIGHTON BEACH", post.site
    assert_equal true, post.is_qrp

    #API
    get "/api/ALERTS.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 1
    #
    assert_equal data[0].excluding([ "alID", "alTime" ]),
      { "actSiteID" => 'BRIGHTON BEACH', "allAssetCodes" => ["BRIGHTON BEACH"], "CallSign" => "ZL4TEST", "Class" => "QRP", "Location" => "BRIGHTON BEACH", "alDay" => "0", "Freq" => "7.090", "MODE" => "AM", "Comments" => "qrp alert; BRIGHTON BEACH", "Duration" => nil}
   
  end

  test "Can alert QRP via API" do    
    user1=create_test_user(activated: true)
    user2=create_test_user(activated: true)

    #  raw JSON treated as URL-encoded key
    malformed_payload = %Q({"userID":"#{user1.callsign}","actComments":"test","alDate":"#{3.days.from_now.strftime("%Y-%m-%d")}","actFreq":"7.0","APIKey":"#{user1.pin}","actMode":"SSB","alTime":"00:30","actCallsign":"#{user2.callsign}","actSite":"BRIGHTON BEACH", "actClass": "QRP"})

    # Forcing the form content-type triggers the exact bug
    assert_difference "Post.count", 1, "Expected 1 new Post" do
    post "/api/ALERT",
         params: malformed_payload,
         headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
    end

    assert_response :success

    p=Post.last
    assert_equal 'BRIGHTON BEACH', p.site
    assert_equal ['BRIGHTON BEACH'], p.asset_codes
    assert_equal true, p.is_qrp

    #API
    get "/api/ALERTS.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 1
    #
    assert_equal data[0].excluding([ "alID", "alTime" ]),
      { "actSiteID" => 'BRIGHTON BEACH', "allAssetCodes" => ["BRIGHTON BEACH"], "CallSign" => user2.callsign, "Class" => "QRP", "Location" => "BRIGHTON BEACH", "alDay" => "0", "Freq" => "7.0", "MODE" => "SSB", "Comments" => "test; BRIGHTON BEACH", "Duration" => "1"}


  end

  test "Can add QRP to other alerts" do

    post sessions_path, params: { session: {email: "zl4nvw", password: "dummy" } }
    assert_redirected_to root_path
    follow_redirect!

    user1=User.find_by(callsign: "ZL4NVW")
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0', location: create_point(173.1, -43))

    # create post
    post posts_path, params: { topic_id: ALERT_TOPIC, pnp: "off", post: { callsign: "ZL4TEST", freq: "7.090", mode: "AM", asset_codes: asset1.code, is_qrp: true, description: "qrp POTA alert", referenced_date: 1.day.from_now.strftime('%Y-%m-%d'), referenced_time: 1.day.from_now.strftime('%H:%M'), duration: 1  } }

    assert_response :success
    post=Post.last
    assert_select ".alert-success", /Posted/, "Success message"
    assert_equal true, post.is_qrp
    assert_equal [asset1.code], post.asset_codes

    #API
    get "/api/ALERTS.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 1
    #
    assert_equal data[0].excluding([ "alID", "alTime" ]),
      { "WWFFID" => asset1.code, "actSiteID" => asset1.code, "allAssetCodes" => [asset1.code], "CallSign" => "ZL4TEST", "Class" => "POTA", "Location" => "#{asset1.name} [#{asset1.code}] {RE67na}", "alDay" => "0", "Freq" => "7.090", "MODE" => "AM", "Comments" => "qrp POTA alert", "Duration" => "1"}
  end

end


