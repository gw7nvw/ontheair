# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class HemaLogsControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX
  ##################################################################
  test "Should get index page" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')
    asset2=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    log2=create_test_log(user1,asset_codes: [asset2.code], date: '2022-01-01'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user1

    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /HEMA Logs/

    #Action control bar
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #table
    table=get_table_test(@response.body, 'logs_table')

    assert_equal 3, get_row_count_test(table), '3 rows incl header'
    row=get_row_test(table,2)
    assert_match /#{asset1.name}/, get_col_test(row,1), "Correct summit"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,2), "Correct code"
    assert_match /2022-01-02/, get_col_test(row,3), "Correct date"
    assert_match /2/, get_col_test(row,4), "Correct count"
    assert_match /Submit/, get_col_test(row,5), "Correct submit / resubmit"
    row=get_row_test(table,3)
    assert_match /#{asset2.name}/, get_col_test(row,1), "Correct summit"
    assert_match /#{make_regex_safe(asset2.code)}/, get_col_test(row,2), "Correct code"
    assert_match /2022-01-01/, get_col_test(row,3), "Correct date"
    assert_match /1/, get_col_test(row,4), "Correct count"
    assert_match /Submit/, get_col_test(row,5), "Correct submit / resubmit"
  end

  test "Normal user cannot get another users index page" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')
    asset2=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user2

    get :index, {user: user1.callsign}
    assert_response :redirect
    assert_redirected_to "/"

    assert_equal 'You do not have permissions to view HEMA logs for this user', flash[:error]
  end

  test "Cannot view HEMA logs if not logged in" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')
    asset2=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    get :index, {user: user1.callsign}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Submit / resubmit shown correctly" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')
    asset2=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, submitted_to_hema: true)

    log2=create_test_log(user1,asset_codes: [asset2.code], date: '2022-01-01'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, submitted_to_hema: true)
    sign_in user1

    get :index
    assert_response :success

    #table
    table=get_table_test(@response.body, 'logs_table')

    assert_equal 3, get_row_count_test(table), '3 rows incl header'
    row=get_row_test(table,2)
    assert_match /#{asset1.name}/, get_col_test(row,1), "Correct summit"
    assert_match /Submit/, get_col_test(row,5), "Correct submit / resubmit - 1 of 2 contacts submitted"

    row=get_row_test(table,3)
    assert_match /#{asset2.name}/, get_col_test(row,1), "Correct summit"
    assert_match /Resend/, get_col_test(row,5), "Correct resubmit - single contact already submitted"
  end

  ##################################################################
  # SHOW
  ##################################################################
  test "Should get show log page" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')
    asset2=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, loc_desc2: 'Hamilton')
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:01:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    log2=create_test_log(user1,asset_codes: [asset2.code], date: '2022-01-02'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user1

    get :show, {id: log.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /HEMA Logs/
    assert_select '#crumbs', /#{log.id}/

    #Action control bar
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    assert_select '#hema_user'
    assert_select '#hema_pass'
    assert_select '#submit'
 
    #Log table
    #table
    table=get_table_test(@response.body, 'log_table')
    assert_equal 2, get_row_count_test(table), '2 rows'
    row=get_row_test(table,1)
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct activator"
    assert_match /2022-01-01/, get_col_test(row,4), "Correct date"
    assert_match /No/, get_col_test(row,6), "Correct QRP"
    row=get_row_test(table,2)
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,4), "Correct location"


    #Contacts table
    table=get_table_test(@response.body, 'contacts_table')
    assert_equal 3, get_row_count_test(table), '3 rows incl header'
    row=get_row_test(table,2)
    assert_match /00:00/, get_col_test(row,1), "Correct time"
    assert_match /#{user2.callsign}/, get_col_test(row,2), "Correct callsign"
    assert_match /SSB/, get_col_test(row,3), "Correct mode"
    assert_match /14.310/, get_col_test(row,4), "Correct frequency"
    assert_match /Hamilton/, get_col_test(row,5), "Correct location"
    assert_match /31/, get_col_test(row,6), "Correct signal2"
    assert_match /59/, get_col_test(row,7), "Correct signal1"

    row=get_row_test(table,3)
    assert_match /00:01/, get_col_test(row,1), "Correct time"
    assert_match /#{user3.callsign}/, get_col_test(row,2), "Correct callsign"
  end  

  test "Normal user cannot get another users log page" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')
    asset2=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user2

    get :show, {id: log.id}
    assert_response :redirect
    assert_redirected_to "/"

    assert_equal 'You do not have permissions to view HEMA logs for this user', flash[:error]
  end

  test "Cannot view HEMA log if not logged in" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')
    asset2=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HCB-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    get :show, {id: log.id}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end
 
  ###############################################################################
  # SUBMIT, etc
  ############################################################################### 
  #
  # Remaining functions all interract with HEMA website, so not currently tested.
  # Could potentially write an auto-test that cleans up after itself ...

end
