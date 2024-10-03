# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class PostsControllerTest < ActionController::TestCase
  test "Can create new spot" do
    sign_in users(:zl4nvw)
    user1=User.find_by(callsign: 'ZL4NVW')
    asset1=create_test_asset
    asset2=create_test_asset

    get :new, {topic_id: SPOT_TOPIC}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Spots/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #fields
    assert_select '#post_callsign'
    assert_select '#post_freq'
    assert_select '#post_mode'
    assert_select '#post_asset_codes'
    assert_select '#pnp'
    assert_select "#submit", {value: "Create Post"}

    #This user uses non-UTC so display will be in localtime
    thedate=Time.now
    tz=Timezone.find_by_id(user1.timezone)
    userdate=thedate.in_time_zone(tz.name)

    #create post
    post :create, topic_id: SPOT_TOPIC, pnp: 'off', post: {callsign: 'ZL4TEST', freq: '7.090', mode: 'AM', asset_codes: asset1.code+", "+asset2.code}
    assert_response :success
    post=Post.last
    assert_select ".alert-success", /Posted/, "Success message"

    #record created
    assert_equal "ZL4TEST", post.callsign, "Activator callsign"
    assert_equal user1.id, post.created_by_id, "Spotter callsign"
    assert_equal '7.090', post.freq, "Freq"
    assert_equal 'AM', post.mode, "Mode"
    assert_equal thedate.strftime('%Y-%m-%d'), post.referenced_date.strftime('%Y-%m-%d'), "eDate"
    assert_equal thedate.strftime('%Y-%m-%d %H:%M'), post.referenced_time.strftime('%Y-%m-%d %H:%M'), "Time"
    assert_equal [asset1.code, asset2.code].sort, post.asset_codes, "Codes"

    #show post page
    assert_select ".box_header", /ZL4NVW/, "Spotter Callsign"
    assert_select ".box_header", /ZL4TEST/, "Activator Callsign"
    assert_select ".box_header", /Spotted Portable/, "topic"
    assert_select ".box_header", /#{userdate.strftime("%Y-%m-%d")}/, "date"
    assert_select ".box_header", /#{make_regex_safe(asset1.codename)}/, "location"
    assert_select ".box_header", /#{make_regex_safe(asset2.codename)}/, "location"
  end

  test "Can spot from asset" do
    sign_in users(:zl4nvw)
    user1=User.find_by(callsign: 'ZL4NVW')
    asset1=create_test_asset

    get :new, {topic_id: SPOT_TOPIC, code: asset1.safecode}
    assert_response :success
    #fields
    assert_select '#post_callsign'
    assert_select '#post_freq'
    assert_select '#post_mode'
    assert_select '#post_asset_codes' do |temp|
      assert_match /"value"=>"#{asset1.code}"/, temp.to_s, "Default code applied"
    end
    assert_select '#pnp'
    assert_select "#submit", {value: "Create Post"}
  end

  test "Can respot from spot" do
    sign_in users(:zl4nvw)
    user1=User.find_by(callsign: 'ZL4NVW')
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    item=create_test_spot(user1, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB")
    spot=item.post

    get :new, {topic_id: SPOT_TOPIC, spot: -spot.id}

    assert_response :success
    #fields
    assert_select '#post_callsign' do |temp|
      assert_match /"value"=>"#{user2.callsign}"/, temp.to_s, "Activator callsign applied"
    end
    assert_select '#post_freq' do |temp|
      assert_match /"value"=>"7.09"/, temp.to_s, "Freq applied"
    end
    assert_select '#post_mode' do |temp|
      assert_match /"value"=>"SSB"/, temp.to_s, "Mode applied"
    end
    assert_select '#post_asset_codes' do |temp|
      assert_match /"value"=>"#{asset1.code},#{asset2.code}"/, temp.to_s, "Default codes applied"
    end
    assert_select '#pnp'
    assert_select "#submit", {value: "Create Post"}
  end

  test "Can create new alert" do
    sign_in users(:zl4nvw)
    user1=User.find_by(callsign: 'ZL4NVW')
    asset1=create_test_asset
    asset2=create_test_asset

    get :new, {topic_id: ALERT_TOPIC}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Alerts/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #fields
    assert_select '#post_referenced_date'
    assert_select '#post_referenced_time'
    assert_select '#post_duration'
    assert_select '#post_freq'
    assert_select '#post_mode'
    assert_select '#post_asset_codes'
    assert_select '#pnp'
    assert_select "#submit", {value: "Create Post"}

    thedate=Time.now
    tz=Timezone.find_by_id(user1.timezone) 
    userdate=thedate.in_time_zone(tz.name)

    #create post
    post :create, topic_id: ALERT_TOPIC, pnp: 'off', post: {referenced_date: thedate, referenced_time: thedate,freq: '7.090', mode: 'AM', asset_codes: asset1.code+", "+asset2.code, duration: 1}
    assert_response :success
    post=Post.last
    assert_select ".alert-success", /Posted/, "Success message"

    #record created
    assert_equal "ZL4NVW", post.callsign, "Activator callsign"
    assert_equal user1.id, post.created_by_id, "Poster callsign"
    assert_equal '7.090', post.freq, "Freq"
    assert_equal 'AM', post.mode, "Mode"
    assert_equal 1, post.duration, "duration"
    assert_equal thedate.strftime('%Y-%m-%d'), post.referenced_date.strftime('%Y-%m-%d'), "eDate"
    assert_equal thedate.strftime('%Y-%m-%d %H:%M'), post.referenced_time.strftime('%Y-%m-%d %H:%M'), "Time"
    assert_equal [asset1.code, asset2.code].sort, post.asset_codes, "Codes"

    #show post page
    assert_select ".box_header", /ZL4NVW/, "Spotter Callsign"
    assert_select ".box_header", /Going Portable/, "topic"
    assert_select ".box_header", /#{userdate.strftime("%Y-%m-%d")}/, "date"
    assert_select ".box_header", /#{make_regex_safe(asset1.codename)}/, "location"
    assert_select ".box_header", /#{make_regex_safe(asset2.codename)}/, "location"
  end

  #TODO: edit spot, alert
  #TODO: delete spot, alert


end
