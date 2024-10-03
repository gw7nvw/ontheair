# typed: false
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
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, is_portable1: true)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-01 00:00'.to_time)

    sign_in users(:zl4nvw)
    get :recent

    #data:
    table=get_table_test(@response.body, 'log_table')

    #Two rows (heading, data)
    assert_equal 2, get_row_count_test(table), "2 rows"
    row1=get_row_test(table,2)

    #our log listed
    assert_match /ZL4NVW/, get_col_test(row1, 2), "Callsign"
    assert_match /2022-01-01/, get_col_test(row1, 3), "Date"
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row1, 4), "Asset name"
    assert_match /No/, get_col_test(row1, 5), "QRP"
    assert_match /Yes/, get_col_test(row1, 6), "Portable"
    assert_match /1/, get_col_test(row1, 7), "Contacts"


 
    log2=create_test_log(user2, asset_codes: [asset2.code], date: '2022-01-02'.to_date, is_portable1: false, is_qrp1: true)
    contact2=create_test_contact(user2, user1, log_id: log2.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code], time: '2022-01-02 00:00'.to_time)
    contact3=create_test_contact(user2, user1, log_id: log2.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code], time: '2022-01-02 00:00'.to_time, mode: 'AM')

    get :recent

    #Three rows (heading, data)
    table=get_table_test(@response.body, 'log_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row1=get_row_test(table,2)
    row2=get_row_test(table,3)

    #our logs listed
    assert_match /ZL4NVW/, get_col_test(row2, 2), "Callsign"
    assert_match /2022-01-01/, get_col_test(row2, 3), "Date"
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row2, 4), "Asset name"
    assert_match /No/, get_col_test(row2, 5), "QRP"
    assert_match /Yes/, get_col_test(row2, 6), "Portable"
    assert_match /1/, get_col_test(row2, 7), "Contacts"

    assert_match /ZL3CC/, get_col_test(row1, 2), "Callsign"
    assert_match /2022-01-02/, get_col_test(row1, 3), "Date"
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row1, 4), "Asset name"
    assert_match /Yes/, get_col_test(row1, 5), "QRP"
    assert_match /No/, get_col_test(row1, 6), "Portable"
    assert_match /2/, get_col_test(row1, 7), "Contacts"

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
    #two rows (heading, data)
    table=get_table_test(@response.body, 'result_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row1=get_row_test(table,2)

    assert_match /1/, get_col_test(row1, 1), "Position"
    assert_match /#{user1.callsign}/, get_col_test(row1, 2), "Callsign"
    assert_match /1/, get_col_test(row1, 4), "Hut"

   
    #Chaser scores
    get :results, {sortby: 'hut', scoreby: 'chased'}

    #data:
    table=get_table_test(@response.body, 'result_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row1=get_row_test(table,2)

    assert_match /1/, get_col_test(row1, 1), "Position"
    assert_match /#{user2.callsign}/, get_col_test(row1, 2), "Callsign"
    assert_match /1/, get_col_test(row1, 4), "Hut"
   
    #Bagged scores
    get :results, {sortby: 'hut', scoreby: 'bagged'}

    #data:
    table=get_table_test(@response.body, 'result_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row1=get_row_test(table,2)
    row2=get_row_test(table,3)

    assert_match /1/, get_col_test(row1, 1), "Position"
    assert_match /#{user1.callsign}/, get_col_test(row1, 2), "Callsign"
    assert_match /1/, get_col_test(row1, 4), "Hut"
    assert_match /1/, get_col_test(row2, 1), "Position"
    assert_match /#{user2.callsign}/, get_col_test(row2, 2), "Callsign"
    assert_match /1/, get_col_test(row2, 4), "Hut"

    #Park scores
    get :results, {sortby: 'park', scoreby: 'activated'}

    #data:
    table=get_table_test(@response.body, 'result_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row1=get_row_test(table,2)

    assert_match /1/, get_col_test(row1, 1), "Position"
    assert_match /#{user3.callsign}/, get_col_test(row1, 2), "Callsign"
    assert_match /1/, get_col_test(row1, 8), "Park"
  end

  test "/spots shows list of internal spots" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    item=create_test_spot(user1, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB")
    spot=item.post

    get :spots
    #data:
    table=get_table_test(@response.body, 'spot_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /ZLOTA/, get_col_test(row,1), "Correct scheme"
    assert_match /#{spot.referenced_time.strftime('%Y-%m-%d')}/, get_col_test(row,2), "Correct date"
    assert_match /#{spot.referenced_time.strftime('%H:%M')}/, get_col_test(row,2), "Correct time"
    assert_match /#{user2.callsign}/, get_col_test(row,3), "Correct activator"
    assert_match /#{asset1.code}/, get_col_test(row,4), "Correct asset"
    assert_match /#{asset2.code}/, get_col_test(row,4), "Correct asset"
    assert_match /#{user1.callsign}/, get_col_test(row,5), "Correct spotter"
    assert_match /New Zealand \(Oceania\)/, get_col_test(row,5), "Correct spotter location"
    assert_match /7.09/, get_col_test(row,6), "Correct frequency"
    assert_match /SSB/, get_col_test(row,6), "Correct mode"
    row2=get_row_test(table,2)
  end

  test "/spots shows list of external spots" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset

    spot=create_test_external_spot(user1, code: asset1.code, activatorCallsign: user2.callsign, frequency: "7.09", mode: "SSB", spot_type: "ZLOTA")

    get :spots
    #data:
    table=get_table_test(@response.body, 'spot_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /ZLOTA/, get_col_test(row,1), "Correct scheme"
    assert_match /#{spot.time.strftime('%Y-%m-%d')}/, get_col_test(row,2), "Correct date"
    assert_match /#{spot.time.strftime('%H:%M')}/, get_col_test(row,2), "Correct time"
    assert_match /#{user2.callsign}/, get_col_test(row,3), "Correct activator"
    assert_match /#{asset1.code}/, get_col_test(row,4), "Correct asset"
    assert_match /#{user1.callsign}/, get_col_test(row,5), "Correct spotter"
    assert_match /New Zealand \(Oceania\)/, get_col_test(row,5), "Correct spotter location"
    assert_match /7.09/, get_col_test(row,6), "Correct frequency"
    assert_match /SSB/, get_col_test(row,6), "Correct mode"
  end

  test "/spots filtering" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    item=create_test_spot(user1, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB", referenced_time: 1.minute.ago)
    spot=item.post
    spot2=create_test_external_spot(user1, code: 'GFF-0001', activatorCallsign: 'MM0FMF', frequency: "7.19", mode: "AM", spot_type: "WWFF", time: 2.minutes.ago)

    #all zones
    get :spots, {zone: 'all'}

    #data:
    table=get_table_test(@response.body, 'spot_table')  
    assert_equal 4, get_row_count_test(table), "4 rows 2 spots x 2 rows each"
    row=get_row_test(table,1)
    assert_match /#{asset1.code}/, get_col_test(row,4), "Correct asset"
    row2=get_row_test(table,3)
    assert_match /GFF-0001/, get_col_test(row2,4), "Correct asset"

    #EU zones
    get :spots, {zone: 'EU'}

    #data:
    table=get_table_test(@response.body, 'spot_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /GFF-0001/, get_col_test(row,4), "Correct asset"

    #AM
    get :spots, {zone: 'all', mode: 'AM'}

    #data:
    table=get_table_test(@response.body, 'spot_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /GFF-0001/, get_col_test(row,4), "Correct asset"

    #ZLOTA
    get :spots, {zone: 'all', class: 'ZLOTA'}
  
    #data:
    table=get_table_test(@response.body, 'spot_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /#{asset1.code}/, get_col_test(row,4), "Correct asset"

  end

  test "/alerts shows list of alerts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    item=create_test_alert(user2, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment")
    spot=item.post

    get :alerts

    #data:
    table=get_table_test(@response.body, 'zlota_alert_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,2)

    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,1), "Correct date"
    assert_match /#{Time.now.strftime("%H:%M")}/, get_col_test(row,2), "Correct time"
    assert_match /1/, get_col_test(row,3), "Correct duration"
    assert_match /#{user2.callsign}/, get_col_test(row,4), "Correct activator"
    assert_match /#{asset1.code}/, get_col_test(row,5), "Correct asset"
    assert_match /7.09/, get_col_test(row,6), "Correct frequency"
    assert_match /SSB/, get_col_test(row,6), "Correct mode"
    assert_match /This is a comment/, get_col_test(row,7), "Correct comment"
  end

end
