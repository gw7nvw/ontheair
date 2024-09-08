require "test_helper"
include ApplicationHelper
include SessionsHelper
class StaticPagesControllerTest < ActionController::TestCase
  test "Should get home page" do
    get :home
    assert_response :success
    #Menus does not includes User menu
    assert_select '#menus', {count: 0, text: /Profile/}
    assert_select '#menus', {count: 0, text: /My Logs/}

    #Breadcrumbs
    assert_select '#crumbs', /Home/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Add Spot/}
    assert_select '#controls', {count: 0, text: /Add Alert/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

  end

  test "Signed in user should get home page" do
    sign_in users(:zl4nvw)

    get :home
    assert_response :success

    #Menus includes User menu
    assert_select '#menus', {count: 1, text: /ZL4NVW/}
    assert_select '#menus', {count: 1, text: /My Logs/}
    assert_select '#menus', /Profile/

    #Breadcrumbs
    assert_select '#crumbs', /Home/

    #Action control bar
    #show logged in version
    assert_select '#controls', {count: 1, text: /Add Spot/}
    assert_select '#controls', {count: 1, text: /Add Alert/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #Spots
    assert_select '.heading2', /Spots/

    #Recent
    assert_select '.heading2', /Recent/
  
    #Top Ten
    assert_select '.heading2', /Top Ten/
  end

  test "Signed in user should see news" do
    create_test_post(NEWS_TOPIC,"the title","the contents",1.day.ago)

    sign_in users(:zl4nvw)
    get :home

    #News is now shown
    assert_select '.heading2', /What.*s New/
    assert_select '.sectiontitle', /the title/
    assert_select '.sectiontext', /the contents/

    #Acknowledge the news
    get :ack_news
    assert_redirected_to root_path

    #Now check news no longer shown
    get :home

    #News is not shown
    assert_select '.heading2', {count: 0, text: /What.*s New/}
  end

  test "Recent lists recent logs" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user2=User.find_by(callsign: 'ZL3CC')
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-01 00:00'.to_time)

    sign_in users(:zl4nvw)
    get :recent

    #data:
    assert_select '.places' do
      #Two rows (heading, data)
      assert_select 'tr', count: 2
      #our log listed
      assert_select '#user', 'ZL4NVW'
      assert_select 'td', '2022-01-01'
      assert_select '#link', asset1.codename
    end

 
    log2=create_test_log(user2, asset_codes: [asset2.code], date: '2022-01-02'.to_date)
    contact2=create_test_contact(user2, user1, log_id: log2.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code], time: '2022-01-02 00:00'.to_time)

    get :recent

    #data:
    assert_select '.places' do
      #Three rows (heading, data)
      assert_select 'tr', count: 3
      #our log listed
      assert_select '#user', 'ZL4NVW'
      assert_select 'td', '2022-01-01'
      assert_select '#link', asset1.codename
      assert_select '#user', 'ZL3CC'
      assert_select 'td', '2022-01-02'
      assert_select '#link', asset2.codename
    end
  end

  test "Results" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    #Hut activation
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    #Park activation
    log2=create_test_log(user3,asset_codes: [asset2.code])
    contact2=create_test_contact(user3,user4,log_id: log2.id, asset1_codes: [asset2.code])
    user1.update_score
    user2.update_score
    user3.update_score
    user4.update_score

    sign_in users(:zl4nvw)
   
    #Hut Activator scores
    get :results, {sortby: 'hut', scoreby: 'activated'}
    #data:
    assert_select '.photo-bar' do
      #user1 score shown, user 2 not in activator list
      assert_select '#user_link_'+user1.id.to_s, user1.callsign, "Activator listed"
      assert_select '#user_link_'+user2.id.to_s, count: 0
      assert_select '#user_link_'+user3.id.to_s, count: 0
      assert_select '#user_link_'+user4.id.to_s, count: 0
      assert_select 'td', '1'
    end

   
    #Chaser scores
    get :results, {sortby: 'hut', scoreby: 'chased'}
    #data:
    assert_select '.photo-bar' do
      #user2 score shown, user 1 not in chaser list
      assert_select '#user_link_'+user2.id.to_s, user2.callsign, "Chaser listed"
      assert_select '#user_link_'+user1.id.to_s, count: 0
      assert_select 'td', '1'
    end

   
    #Bagged scores
    get :results, {sortby: 'hut', scoreby: 'bagged'}
    #data:
    assert_select '.photo-bar' do
      #user2 score shown, user 1 not in chaser list
      assert_select '#user_link_'+user2.id.to_s, user2.callsign, "Chaser listed"
      assert_select '#user_link_'+user1.id.to_s, user1.callsign, "Activator listed"
    end


    #Park scores
    get :results, {sortby: 'park', scoreby: 'activated'}
    #data:
    assert_select '.photo-bar' do
      #user1 score shown, user 2 not in activator list
      assert_select '#user_link_'+user3.id.to_s, user3.callsign, "Park Activator listed"
      assert_select '#user_link_'+user1.id.to_s, count: 0
      assert_select '#user_link_'+user2.id.to_s, count: 0
      assert_select '#user_link_'+user4.id.to_s, count: 0
      assert_select 'td', '1'
    end
  end

  test "/spots shows list of internal spots" do
    raise "TODO - write /spots test"
  end

  test "/spots shows list of external spots" do
    raise "TODO - write /spots test"
  end

  test "/alerts shows list of alerts" do
    raise "TODO - write /alerts test"
  end

end
