# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class PotaLogsControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX
  ##################################################################
  test "Should get index page" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

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
    assert_select '#crumbs', /POTA Logs/

    #Action control bar
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #table
    table=get_table_test(@response.body, 'logs_table')

    assert_equal 3, get_row_count_test(table), '3 rows incl header'
    row=get_row_test(table,2)
    assert_match /#{asset1.name}/, get_col_test(row,1), "Correct park"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,2), "Correct code"
    assert_match /2022-01-02/, get_col_test(row,3), "Correct date"
    assert_match /2/, get_col_test(row,4), "Correct count"
    assert_match /Submit/, get_col_test(row,5), "Correct submit / resubmit"
    row=get_row_test(table,3)
    assert_match /#{asset2.name}/, get_col_test(row,1), "Correct park"
    assert_match /#{make_regex_safe(asset2.code)}/, get_col_test(row,2), "Correct code"
    assert_match /2022-01-01/, get_col_test(row,3), "Correct date"
    assert_match /1/, get_col_test(row,4), "Correct count"
    assert_match /Submit/, get_col_test(row,5), "Correct submit / resubmit"
  end

  test "Normal user cannot get another users index page" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user2

    get :index, {user: user1.callsign}
    assert_response :redirect
    assert_redirected_to "/"

    assert_equal 'You do not have permissions to view POTA logs for this user', flash[:error]
  end

  test "Cannot view POTA logs if not logged in" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

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
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, submitted_to_pota: true)

    log2=create_test_log(user1,asset_codes: [asset2.code], date: '2022-01-01'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, submitted_to_pota: true)
    sign_in user1

    get :index
    assert_response :success

    #table
    table=get_table_test(@response.body, 'logs_table')

    assert_equal 3, get_row_count_test(table), '3 rows incl header'
    row=get_row_test(table,2)
    assert_match /#{asset1.name}/, get_col_test(row,1), "Correct park"
    assert_match /Submit/, get_col_test(row,5), "Correct submit / resubmit - 1 of 2 contacts submitted"

    row=get_row_test(table,3)
    assert_match /#{asset2.name}/, get_col_test(row,1), "Correct park"
    assert_match /Resend/, get_col_test(row,5), "Correct resubmit - single contact already submitted"
  end

  ##################################################################
  # SHOW
  ##################################################################
  test "Should get show log page" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, loc_desc2: 'Hamilton')
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:01:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    log2=create_test_log(user1,asset_codes: [asset2.code], date: '2022-01-02'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user1

    get :show, {id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /POTA Logs/
    assert_select '#crumbs', /#{user1.callsign}/
    assert_select '#crumbs', /#{asset1.code}/

    #Action control bar
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #Log table
    assert_match "Contacts accepted: 2", @response.body
    assert_match "Duplicate contacts rejected: 0", @response.body
    assert_match "Invalid contacts rejected: 0", @response.body
  end  

  test "Normal user cannot get another users log page" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user2

    get :show, {id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign}
    assert_response :redirect
    assert_redirected_to "/"

    assert_equal 'You do not have permissions to view POTA logs for this user', flash[:error]
  end

  test "Cannot view POTA log if not logged in" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    get :show, {id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end
 
  ###############################################################################
  # SUBMIT, etc
  ############################################################################### 

  test "Can download a POTA log" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, loc_desc2: 'Hamilton')
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset3.code], time: '2022-01-01 00:01:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    log2=create_test_log(user1,asset_codes: [asset2.code], date: '2022-01-02'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    sign_in user1

    get :download, id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign, :format => :adi
    assert_response :success

    filestr=@response.body.gsub("\n",'')
    lines=get_adif_lines(filestr)
    assert_equal 2, lines.count
    line=lines[0]
    assert_equal user2.callsign, get_adif_param(line,'call')
    assert_equal user1.callsign, get_adif_param(line,'station_callsign')
    assert_equal '20m', get_adif_param(line,'band')
    assert_equal 'SSB', get_adif_param(line,'mode')
    assert_equal '20220101', get_adif_param(line,'qso_date')
    assert_equal '0000', get_adif_param(line,'time_on')
    assert_equal asset1.code, get_adif_param(line,'my_sig_info')
    line=lines[1]
    assert_equal user3.callsign, get_adif_param(line,'call')
    assert_equal user1.callsign, get_adif_param(line,'station_callsign')
    assert_equal '20m', get_adif_param(line,'band')
    assert_equal 'SSB', get_adif_param(line,'mode')
    assert_equal '20220101', get_adif_param(line,'qso_date')
    assert_equal '0001', get_adif_param(line,'time_on')
    assert_equal asset1.code, get_adif_param(line,'my_sig_info')
    assert_equal asset3.code, get_adif_param(line,'sig_info')
  end

  test "cannot download someone elses POTA log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user2

    get :download, id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign, :format => :adi
    assert_response :redirect
    assert_redirected_to "/"

    assert_equal 'You do not have permissions to view POTA logs for this user', flash[:error]
  end

  test "Cannot download POTA log if not logged in" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    get :download, id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign, :format => :adi

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ###############################################################################
  # SEND EMAIL
  ############################################################################### 

  test "Can send a POTA log" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310, loc_desc2: 'Hamilton')
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset3.code], time: '2022-01-01 00:01:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    log2=create_test_log(user1,asset_codes: [asset2.code], date: '2022-01-02'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-02 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    sign_in user1

    get :send_email, id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign, :format => :adi
    assert_response :redirect
    assert_equal 'Your log has been sent', flash[:success]
  end

  test "cannot send someone elses POTA log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)
    sign_in user2

    get :send_email, id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign, :format => :adi
    assert_response :redirect
    assert_redirected_to "/"

    assert_equal 'You do not have permissions to send POTA logs for this user', flash[:error]
  end

  test "Cannot send_email POTA log if not logged in" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time, signal1: '59', signal2: '31', mode: 'SSB', frequency: 14.310)

    get :download, id: asset1.code, date: log.date.strftime('%Y%m%d'), user: user1.callsign, :format => :adi

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end
end
