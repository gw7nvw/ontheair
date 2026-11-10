require "test_helper"
include ApplicationHelper
include SessionsHelper

class QrpSpotsTest < ActionDispatch::IntegrationTest
  @controller = 
  test "Can spot QRP via webpage" do
    post sessions_path, params: { session: {email: "zl4nvw", password: "dummy" } }
    assert_redirected_to root_path
    follow_redirect!

    user1=User.find_by(callsign: "ZL4NVW")
    asset1=create_test_asset(location: create_point(173.1, -43))
    asset2=create_test_asset(location: create_point(173.1, -44))

    # create post
    post posts_path, params: { topic_id: SPOT_TOPIC, pnp: "off", post: { callsign: "ZL4TEST", freq: "7.090", mode: "AM", asset_codes: "Brighton beach", is_qrp: true, description: "qrp spot"  } }

    assert_response :success
    post=Post.last
    assert_select ".alert-success", /Posted/, "Success message"
    assert_equal true, post.is_qrp
    assert_equal ["BRIGHTON BEACH"], post.asset_codes

    puts post.to_json

    cs = ConsolidatedSpot.last
    assert_equal ['QRP'], cs.spot_type
    assert_equal ['BRIGHTON BEACH'], cs.name
    assert_equal [''], cs.code
    assert_equal true, cs.is_qrp

    #API
    get "/api/ALL.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 1
    #
    assert_equal data[0].excluding([ "actId", "actTime", "altLocation" ]),
      { "ID" => '', "actFreq" => "7.09", "actMode" => "AM", "actClass" => "QRP", "actSiteID" => '', "actSpoter" => 'ZL4NVW', "actCallsign" => 'ZL4TEST', "actComments" => "qrp spot; BRIGHTON BEACH", "actLocation" => 'BRIGHTON BEACH'}
   
  end

  test "Can spot QRP via API" do    
    user1=create_test_user(activated: true)

    #  raw JSON treated as URL-encoded key
    malformed_payload = %Q({"actClass":"QRP","actSite":"Brighton Beach","actCallsign":"ZL4TEST","freq":"7.090","mode":"AM","comments":"test","userID":"#{user1.callsign}","APIKey":"#{user1.pin}"})

    # Forcing the form content-type triggers the exact bug
    assert_difference "ConsolidatedSpot.count", 1, "Expected 1 new Consolidated Spot" do
    post "/api/SPOT",
         params: malformed_payload,
         headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
    end

    assert_response :success

    p=Post.last
    puts p.to_json

    cs = ConsolidatedSpot.last
    puts cs.to_json
    assert_equal ['QRP'], cs.spot_type
    assert_equal ['BRIGHTON BEACH'], cs.name
    assert_equal [''], cs.code
    assert_equal true, cs.is_qrp

    #API
    get "/api/ALL.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 1
    #
    assert_equal data[0].excluding([ "actId", "actTime", "altLocation" ]),
      { "ID" => '', "actFreq" => "7.09", "actMode" => "AM", "actClass" => "QRP", "actSiteID" => '', "actSpoter" => user1.callsign, "actCallsign" => 'ZL4TEST', "actComments" => "test; BRIGHTON BEACH", "actLocation" => 'BRIGHTON BEACH'}


  end

  test "Can add QRP to other spots" do
    post sessions_path, params: { session: {email: "zl4nvw", password: "dummy" } }
    assert_redirected_to root_path
    follow_redirect!

    user1=User.find_by(callsign: "ZL4NVW")
    asset1=create_test_asset(location: create_point(173.1, -43))
    asset2=create_test_asset(location: create_point(173.1, -44))

    # create post
    post posts_path, params: { topic_id: SPOT_TOPIC, pnp: "off", post: { callsign: "ZL4TEST", freq: "7.090", mode: "AM", asset_codes: "NZ-0001", is_qrp: true, description: "qrp POTA spot"  } }

    assert_response :success
    post=Post.last
    assert_select ".alert-success", /Posted/, "Success message"
    assert_equal true, post.is_qrp
    assert_equal ["NZ-0001"], post.asset_codes

    puts post.to_json

    cs = ConsolidatedSpot.last
    assert_equal ['POTA'], cs.spot_type
    assert_equal ['NZ-0001 [NZ-0001]'], cs.name
    assert_equal ['NZ-0001'], cs.code
    assert_equal true, cs.is_qrp

    #API
    get "/api/ALL.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 1
    #
    assert_equal data[0].excluding([ "actId", "actTime", "altLocation" ]),
      { "ID" => 'NZ-0001', "POTAID" => 'NZ-0001', "actFreq" => "7.09", "actMode" => "AM", "actClass" => "POTA", "actSiteID" => 'NZ-0001', "actSpoter" => 'ZL4NVW', "actCallsign" => 'ZL4TEST', "actComments" => "qrp POTA spot", "actLocation" => 'NZ-0001 [NZ-0001]'}
  end

end


