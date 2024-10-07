# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class LogsControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX 
  ##################################################################
  test "Index for a user" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))
    asset2=create_test_asset(asset_type: 'park', region: 'CB', district: 'CC', location: create_point(173,-43), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', location: create_point(173,-45), code_prefix: 'ZL3/CB-')
    asset4=create_test_asset(asset_type: 'park', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173.01,-45), test_radius: 0.1)

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-02'.to_date, is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Hamilton')
    contact1b=create_test_contact(user1, user3, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset3.code], time: '2022-01-02 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #another user's chaser log
    log2=create_test_log(user2, date: '2023-01-01'.to_date)
    contact2=create_test_contact(user2, user1, log_id: log2.id, loc_desc1: 'Hamilton', asset2_codes: [asset3.code], time: '2023-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #my chaser log
    log3=create_test_log(user1, date: '2022-01-01'.to_date, loc_desc1: 'Alexandra', is_qrp1: false, is_portable1: false)
    contact3=create_test_contact(user1, user2, log_id: log3.id, loc_desc1: 'Alexandra', asset2_codes: [asset4.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, {user: user1.callsign}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{user1.callsign}/

    #Action control bar - non logged in version
    assert_select '#controls', {count: 0, text: /View All/}
    assert_select '#controls', {count: 0, text: /Add/}
    assert_select '#controls', {count: 0, text: /Upload/}
    assert_select '#controls', {count: 0, text: /Download/}
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #filters
    assert_select '#asset'
    assert_select '#user' do assert_select '[value=?]', user1.callsign end
    assert_select '#find'

    #should get list of logs I submitted
    table=get_table_test(@response.body, 'log_table')
    assert_equal 3, get_row_count_test(table), "3 rows incl header"

    #My logged activation
    row=get_row_test(table,2)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit log not logged in"
    assert_match /View/, get_col_test(row,1), "Can view log"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /2022-01-02/, get_col_test(row,3), "Correct date"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,4), "Correct location1"
    assert_match /#{make_regex_safe(asset2.code)}/, get_col_test(row,4), "Correct location1"
    assert_match /Yes/, get_col_test(row,5), "Correct QRP"
    assert_match /Yes/, get_col_test(row,6), "Correct Portable"
    assert_match /2/, get_col_test(row,7), "Correct count"

    #My logged chase
    row=get_row_test(table,3)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit log not logged in"
    assert_match /View/, get_col_test(row,1), "Can view log"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /2022-01-01/, get_col_test(row,3), "Correct date"
    assert_match /Alexandra/, get_col_test(row,4), "Correct location1"
    assert_match /No/, get_col_test(row,5), "Correct QRP"
    assert_match /No/, get_col_test(row,6), "Correct Portable"
    assert_match /1/, get_col_test(row,7), "Correct count"

  end

  test "Index for a user - logged in version" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user

    sign_in user1

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))
    asset2=create_test_asset(asset_type: 'park', region: 'CB', district: 'CC', location: create_point(173,-43), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', location: create_point(173,-45), code_prefix: 'ZL3/CB-')
    asset4=create_test_asset(asset_type: 'park', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173.01,-45), test_radius: 0.1)

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-02'.to_date, is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Hamilton')
    contact1b=create_test_contact(user1, user3, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset3.code], time: '2022-01-02 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #my chaser log
    log3=create_test_log(user1, date: '2022-01-01'.to_date, loc_desc1: 'Alexandra', is_qrp1: false, is_portable1: false)
    contact3=create_test_contact(user1, user2, log_id: log3.id, loc_desc1: 'Alexandra', asset2_codes: [asset4.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, {user: user1.callsign}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{user1.callsign}/

    #Action control bar - logged in non-admin version
    assert_select '#controls', {count: 0, text: /View All/}
    assert_select '#controls', {count: 1, text: /Add/}
    assert_select '#controls', {count: 1, text: /Upload/}
    assert_select '#controls', {count: 1, text: /Download/}
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #filters
    assert_select '#asset'
    assert_select '#user' do assert_select '[value=?]', user1.callsign end
    assert_select '#find'

    #should get list of logs I submitted
    table=get_table_test(@response.body, 'log_table')
    assert_equal 3, get_row_count_test(table), "3 rows incl header"

    #My logged activation
    row=get_row_test(table,2)
    assert_match /Edit/, get_col_test(row,1), "Can edit log logged in"
    assert_match /View/, get_col_test(row,1), "Can view log"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /2022-01-02/, get_col_test(row,3), "Correct date"

    #My logged chase
    row=get_row_test(table,3)
    assert_match /Edit/, get_col_test(row,1), "Can edit log logged in"
    assert_match /View/, get_col_test(row,1), "Can view log"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /2022-01-01/, get_col_test(row,3), "Correct date"
  end

  test "Index for an asset" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))
    asset2=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-03'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-03 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Hamilton')
    contact1b=create_test_contact(user2, user1, log_id: log.id, loc_desc2: 'Ward', asset1_codes: [asset1.code], time: '2022-01-03 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #chaser log
    log2=create_test_log(user2, date: '2022-01-02'.to_date)
    contact2=create_test_contact(user2, user3, log_id: log2.id, loc_desc1: 'Hamilton', asset2_codes: [asset1.code], time: '2022-01-02 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #another activation
    log3=create_test_log(user1, asset_codes: [asset2.code], date: '2023-01-01'.to_date)
    contact2=create_test_contact(user1, user2, log_id: log3.id,  asset1_codes: [asset2.code], time: '2023-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, user: 'all', asset: asset1.safecode
    assert_response :success
    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{make_regex_safe(asset1.codename)}/

    #should get list of logs
    table=get_table_test(@response.body, 'log_table')
    assert_equal 2, get_row_count_test(table), "2 rows incl header"

    #logged activation
    row=get_row_test(table,2)
    assert_match /Edit/, get_col_test(row,1), "Can edit log ogged in"
    assert_match /View/, get_col_test(row,1), "Can view log"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /2022-01-03/, get_col_test(row,3), "Correct date"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,4), "Correct location1"
    assert_match /No/, get_col_test(row,5), "Correct QRP"
    assert_match /No/, get_col_test(row,6), "Correct Portable"
    assert_match /2/, get_col_test(row,7), "Correct count"

    #Chase and activaton of another location not listed
  end

 
  ##################################################################
  # SHOW 
  ##################################################################
  test "Can view a log" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    asset3=create_test_asset(asset_type: 'hut')
    asset4=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code, asset2.code], asset2_codes: [asset3.code, asset4.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    contact2=create_test_contact(user1, user3, log_id: log.id, asset1_codes: [asset1.code, asset2.code], is_portable1: true, is_portable2: false, is_qrp2: false, time: '2022-01-01 01:01'.to_time, frequency: 14.310, mode: 'AM', name1: 'Bobette', loc_desc2: 'Good spot', signal1: '58', power1: 20, transceiver1: 'TS440', antenna1: 'RW', comments1: 'Tnx for park', name2: 'Bobette', signal2: '42')

    get :show, {id: log.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{log.id}/

    #Action control bar - non logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', {count: 0, text: /Download/}
    assert_select '#controls', {count: 0, text: /Markdown/}
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #my details
    table=get_table_test(@response.body, 'your_details_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,1)
    assert_match user1.callsign, get_col_test(row,2), "Activator callsign"
    assert_match '2022-01-01', get_col_test(row,4), "Activation date"
    assert_match 'Yes', get_col_test(row,6), "QRP"
    row=get_row_test(table,2)
    assert_match 'UTC', get_col_test(row,2), "UTC for non logeed in"
    assert_match '10', get_col_test(row,4), "Activation power"
    assert_match 'Yes', get_col_test(row,6), "portable"
    row=get_row_test(table,3)
    assert_match 'roadside spot', get_col_test(row,2), "Location"
    assert_match asset1.codename, get_col_test(row,4), "Activation asset"
    assert_match asset2.codename, get_col_test(row,4), "Activation asset"

    #contact details
    table=get_table_test(@response.body, 'contacts_table')
    assert_equal 3, get_row_count_test(table), "3 rows including header"

    row=get_row_test(table,2)
    assert_match 'View', get_col_test(row,1), "View shown"
    assert_no_match 'Edit', get_col_test(row,1), "Edit not shown for not logged in"
    assert_match '01:00', get_col_test(row,2), "Activation time"
    assert_match 'UTC', get_col_test(row,2), "Show UTC for non logged in"
    assert_match user2.callsign, get_col_test(row,3), "Callsign2"
    assert_match 'Yes', get_col_test(row,4), "QRP2"
    assert_match 'Yes', get_col_test(row,5), "Portable2"
    assert_match 'SSB', get_col_test(row,6), "mode"
    assert_match '7.090', get_col_test(row,7), "frequency"
    assert_match 'Bobby', get_col_test(row,8), "name2"
    assert_match asset3.codename, get_col_test(row,9), "location2 - from assets"
    assert_match asset4.codename, get_col_test(row,9), "location2 - from assets"
    assert_match '31', get_col_test(row,10), "signal1"
    assert_match '59', get_col_test(row,11), "signal2"

    row=get_row_test(table,3)
    assert_match 'View', get_col_test(row,1), "View shown"
    assert_no_match 'Edit', get_col_test(row,1), "Edit not shown for not logged in"
    assert_match '01:01', get_col_test(row,2), "Activation time"
    assert_match 'UTC', get_col_test(row,2), "Show UTC for non logged in"
    assert_match user3.callsign, get_col_test(row,3), "Callsign2"
    assert_match 'No', get_col_test(row,4), "QRP2"
    assert_match 'No', get_col_test(row,5), "Portable2"
    assert_match 'AM', get_col_test(row,6), "mode"
    assert_match '14.310', get_col_test(row,7), "frequency"
    assert_match 'Bobette', get_col_test(row,8), "name2"
    assert_match 'Good spot', get_col_test(row,9), "location2 - from text as no assets"
    assert_match '42', get_col_test(row,10), "signal1"
    assert_match '58', get_col_test(row,11), "signal2"
  end 

  test "Logged in view own log" do
    user1=create_test_user
    user2=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :show, {id: log.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{log.id}/

    #Action control bar - logged in version
    assert_select '#controls', {count: 1, text: /Edit/}
    assert_select '#controls', {count: 1, text: /Download/}
    assert_select '#controls', {count: 1, text: /Markdown/}
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Logged in cannot edit another's log" do
    user1=create_test_user
    user2=create_test_user
    sign_in user2

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :show, {id: log.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{log.id}/

    #Action control bar - another user's logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', {count: 0, text: /Download/}
    assert_select '#controls', {count: 0, text: /Markdown/}
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  ##################################################################
  # NEW
  ##################################################################
  test "Can view new log form" do
    user1=create_test_user
    sign_in user1

    get :new
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', /Cancel/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form
    assert_select '#log_callsign1' do assert_select "[value=?]", user1.callsign end
    assert_select '#log_date'
    assert_select '#log_power1' 
    assert_select '#log_loc_desc1'
    assert_select '#log_is_qrp1'
    assert_select '#log_is_portable1'
    assert_select '#log_asset_codes'
    assert_select '#submit_button'
  end

  test "Non logged in cannot view new log form" do
    get :new

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # CREATE
  ##################################################################
  test "Can create a log" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    sign_in user1

    post :create, log: {callsign1: user1.callsign, asset_codes: asset1.code+','+asset2.code, date: '2022-01-01', is_qrp1: true, is_portable1: true, loc_desc1: 'Good spot', power1: '10'}
    assert_response :redirect
    log=Log.all.order(:created_at).last

    assert_redirected_to "/logs/"+log.id.to_s+"/edit"


    #log
    assert_equal user1.callsign, log.callsign1, "My call"
    assert_equal [asset1.code, asset2.code].sort, log.asset_codes, "My locn"
    assert_equal '2022-01-01', log.date.strftime('%Y-%m-%d'), "Date"
    assert_equal true, log.is_qrp1, "QRP"
    assert_equal true, log.is_portable1, "Portable"
    assert_equal 'Good spot', log.loc_desc1, "Location description"
    assert_equal 10, log.power1, "Power"
  end

  test "Cannot create log for another user" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    logs=Log.count
    sign_in user2

    post :create, log: {callsign1: user1.callsign, asset_codes: asset1.code+','+asset2.code, date: '2022-01-01', is_qrp1: true, is_portable1: true, loc_desc1: 'Good spot', power1: '10'}
    assert_response :success
    log=Log.all.order(:created_at).last

    assert_equal logs, Log.count, "No log created"
    assert_select "#error_explanation", /You do not have permission to use this callsign on this date/, "Error shown"
  end

  test "Not logged in cannot submit new log form" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    logs=Log.count

    post :create, log: {callsign1: user1.callsign, asset_codes: asset1.code+','+asset2.code, date: '2022-01-01', is_qrp1: true, is_portable1: true, loc_desc1: 'Good spot', power1: '10'}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
    assert_equal Log.count, logs, "No new log created"
  end

  ##################################################################
  # EDIT
  ##################################################################
  test "Can view edit log form" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    sign_in user1

    get :edit, id: log.id

    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{log.id}/
    assert_select '#crumbs', /Edit/

    #Action control bar
    assert_select '#controls', /Cancel/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form
    assert_select '#log_callsign1' do assert_select "[value=?]", user1.callsign end
    assert_select '#log_date' do assert_select "[value=?]", '2022-01-01' end
    assert_select '#log_power1' do assert_select "[value=?]", '10' end
    assert_select '#log_loc_desc1'do assert_select "[value=?]", 'roadside spot' end
    assert_select '#log_is_qrp1' do assert_select "[checked=?]", "checked" end
    assert_select '#log_is_portable1' do assert_select "[checked=?]", "checked" end
    assert_select '#log_asset_codes'do assert_select "[value=?]", '{'+asset1.code+'}' end
    assert_select '#submit_button'
  end

  test "Can view edit log form via edit_contact" do
    user1=create_test_user
    user2=create_test_user
    sign_in user1
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :editcontact, id: contact1.id

    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /#{log.id}/
    assert_select '#crumbs', /Edit/

    #Action control bar
    assert_select '#controls', /Cancel/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form
    assert_select '#log_callsign1' do assert_select "[value=?]", user1.callsign end
    assert_select '#log_date' do assert_select "[value=?]", '2022-01-01' end
    assert_select '#log_power1' do assert_select "[value=?]", '10' end
    assert_select '#log_loc_desc1'do assert_select "[value=?]", 'roadside spot' end
    assert_select '#log_is_qrp1' do assert_select "[checked=?]", "checked" end
    assert_select '#log_is_portable1' do assert_select "[checked=?]", "checked" end
    assert_select '#log_asset_codes'do assert_select "[value=?]", '{'+asset1.code+'}' end
    assert_select '#submit_button'
  end

  test "Another user cannot view edit log form" do
    user1=create_test_user
    user2=create_test_user
    sign_in user2
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :edit, id: log.id

    assert_response :redirect
    assert_match /You do not have permission to use this callsign on this date/, flash[:error], "Error shown"
  end

  test "Non logged in cannot view edit log form" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :editcontact, id: contact1.id

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Another user cannot view editcontact log form" do
    user1=create_test_user
    user2=create_test_user
    sign_in user2
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :editcontact, id: contact1.id

    assert_response :redirect
    assert_match /You do not have permission to use this callsign on this date/, flash[:error], "Error shown"
  end

  test "Non logged in cannot view editcontact log form" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :edit, id: log.id

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # UPDATE
  ##################################################################

  test "Can update a log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    asset3=create_test_asset(asset_type: 'hut')
    asset4=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    sign_in user1

    post :update, id: log.id, log: {callsign1: user1.callsign, asset_codes: asset3.code+','+asset4.code, date: '2022-01-02', is_qrp1: false, is_portable1: false, loc_desc1: 'Bad spot', power1: '20'}
    assert_response :redirect
    log.reload

    assert_redirected_to "/logs/"+log.id.to_s+"/edit"
    
    #log
    assert_equal user1.callsign, log.callsign1, "My call"
    assert_equal [asset3.code, asset4.code].sort, log.asset_codes, "My locn"
    assert_equal '2022-01-02', log.date.strftime('%Y-%m-%d'), "Date"
    assert_equal false, log.is_qrp1, "QRP"
    assert_equal false, log.is_portable1, "Portable"
    assert_equal 'Bad spot', log.loc_desc1, "Location description"
    assert_equal 20, log.power1, "Power"
  end

  test "Cannot update log for another user" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    asset3=create_test_asset(asset_type: 'hut')
    asset4=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    sign_in user2

    post :update, id: log.id, log: {callsign1: user1.callsign, asset_codes: asset3.code+','+asset4.code, date: '2022-01-02', is_qrp1: false, is_portable1: false, loc_desc1: 'Bad spot', power1: '20'}
    assert_response :success
    assert_select "#error_explanation", /You do not have permission to use this callsign on this date/, "Error shown"
  end

  test "Not logged in cannot submit update log form" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    asset3=create_test_asset(asset_type: 'hut')
    asset4=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    post :update, id: log.id, log: {callsign1: user1.callsign, asset_codes: asset3.code+','+asset4.code, date: '2022-01-02', is_qrp1: false, is_portable1: false, loc_desc1: 'Bad spot', power1: '20'}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # DELETE
  ##################################################################

  test "Can delete a log and associated contacts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    contact2=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 02:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    sign_in user1

    get :delete, id: log.id

    assert_response :redirect
    assert_redirected_to /logs/
  
    assert_equal 'Log deleted', flash[:success]

    assert_not Log.exists?(log.id)
    assert_not Contact.exists?(contact2.id)
    assert_not Contact.exists?(contact2.id)
  end

  test "cannot delete someone elses log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    contact2=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 02:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    sign_in user2

    get :delete, id: log.id

    assert_response :redirect
    assert_redirected_to /logs/
  
    assert_equal 'You do not have permission to use this callsign on this date', flash[:error]

    assert Log.exists?(log.id)
    assert Contact.exists?(contact2.id)
    assert Contact.exists?(contact2.id)

  end


  test "Cannot delete log not signed in" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date, power1: '10w', loc_desc1: "roadside spot", is_qrp1: true, is_portable1: true)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')
    contact2=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp2: true, time: '2022-01-01 02:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Good spot', signal1: '59', power1: 10, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobby', signal2: '31')

    get :delete, id: log.id

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # UPLOAD / SAVEFILE 
  ##################################################################
  test "Can view log upload form" do
    user1=create_test_user
    sign_in user1

    get :upload

    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Logs/
    assert_select '#crumbs', /Upload/

    #Action control bar
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select "#upload_doc_callsign"
    assert_select "#upload_doc_location"
    assert_select "#upload_doc_no_create"
    assert_select "#upload_doc_ignore_error"
    assert_select "#upload_doc_do_not_lookup"
    assert_select "#upload_doc"
  end

  test "Cannot view log upload form if not logged in" do
    user1=create_test_user

    get :upload
    
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Can submit a hamrs log" do
    user1=create_test_user
    sign_in user1

    #upload log
    upload_file = fixture_file_upload("files/logs/hamrs.adi",'text/plain')
    post :savefile, upload: {doc_callsign: user1.callsign, doc_location: '', doc_no_create: false, doc_ignore_error: false, doc_do_not_lookup: false, doc: upload_file}
    assert_response :redirect
    log=Log.order(:created_at).last

    #log created
    assert_equal user1.id, log.user1_id, "User ID"
    assert_equal ['ZL-0147'], log.asset_codes, "Asset codes"
    assert_equal ['pota park'], log.asset_classes, "Asset classes"
    assert_equal 100, log.power1, "Power"
    assert_equal user1.callsign, log.callsign1, "Callsign"
    assert_equal true, log.is_portable1, "Portable"

    #contacts created
    assert_equal 10, log.contacts.count, "Correct # contacts"
    contacts=log.contacts.order(:time)
   
    #1st entry correct 
    assert_equal "40m", contacts[0].band, "Band"
    assert_equal 7.09, contacts[0].frequency, "Freq"
    assert_equal "Rick Jackson", contacts[0].name2, "Name"
    assert_equal "ZL3RIK", contacts[0].callsign2, "Callsign"
    assert_equal "2023-02-03", contacts[0].date.strftime("%Y-%m-%d"), "Date"
    assert_equal "02:18", contacts[0].time.strftime("%H:%M"), "Time"
    assert_equal "Christchurch, New Zealand", contacts[0].loc_desc2, "Location2"
    assert_equal "57", contacts[0].signal1, "Signal1"
    assert_equal "59", contacts[0].signal2, "Signal2"
    #loc2=Asset.maidenhead_to_lat_lon('RE66gk') 
    assert_equal "POINT (172.5 -43.583333333333336)", contacts[0].location2.as_text, "Location2"

    #rest of entries exist
    assert_equal "ZL3GIG", contacts[1].callsign2, "Callsign"
    assert_equal "ZL3ABY", contacts[2].callsign2, "Callsign"
    assert_equal "ZL3QR", contacts[3].callsign2, "Callsign"
    assert_equal "ZL3AWB", contacts[4].callsign2, "Callsign"
    assert_equal "ZL3OCT", contacts[5].callsign2, "Callsign"
    assert_equal "ZL4KD", contacts[6].callsign2, "Callsign"
    assert_equal "ZL4LO", contacts[7].callsign2, "Callsign"
    assert_equal "ZL3YF", contacts[8].callsign2, "Callsign"
    assert_equal "ZL3ABY", contacts[9].callsign2, "Callsign"
  end

  test "Can submit a eqsl log" do
    user1=create_test_user
    asset1=create_test_asset
    sign_in user1

    #upload log
    upload_file = fixture_file_upload("files/logs/eqsl.adi",'text/plain')
    post :savefile, upload: {doc_callsign: user1.callsign, doc_location: asset1.code, doc_no_create: false, doc_ignore_error: false, doc_do_not_lookup: false, doc: upload_file}
    assert_response :redirect
    log=Log.order(:created_at).last

    #log created
    assert_equal user1.id, log.user1_id, "User ID"
    assert_equal [asset1.code], log.asset_codes, "Asset codes"
    assert_equal ['hut'], log.asset_classes, "Asset classes"
    assert_equal user1.callsign, log.callsign1, "Callsign"

    #contacts created
    assert_equal 12, log.contacts.count, "Correct # contacts"
    contacts=log.contacts.order(:time)
   
    #1st entry correct 
    assert_equal "10m", contacts[0].band, "Band"
    assert_equal 28, contacts[0].frequency, "Freq"
    assert_equal 'SSB', contacts[0].mode, "Mode"
    assert_equal "JA7MYQ", contacts[0].callsign2, "Callsign"
    assert_equal "1983-04-23", contacts[0].date.strftime("%Y-%m-%d"), "Date"
    assert_equal "00:01", contacts[0].time.strftime("%H:%M"), "Time"
    assert_equal "59", contacts[0].signal2, "Signal2"

    #rest of entries exist
    assert_equal "EA1ABT", contacts[1].callsign2, "Callsign"
    assert_equal "EA1AKS", contacts[2].callsign2, "Callsign"
    assert_equal "HA8ZB", contacts[3].callsign2, "Callsign"
    assert_equal "AD8I", contacts[4].callsign2, "Callsign"
    assert_equal "EA8AKN", contacts[5].callsign2, "Callsign"
    assert_equal "JR2UJT", contacts[6].callsign2, "Callsign"
    assert_equal "YO7ARZ", contacts[7].callsign2, "Callsign"
    assert_equal "I0MWI", contacts[8].callsign2, "Callsign"
    assert_equal "OE3OKS", contacts[9].callsign2, "Callsign"
    assert_equal "KA2CC", contacts[10].callsign2, "Callsign"
    assert_equal "EA3BOX", contacts[11].callsign2, "Callsign"
  end

  test "Can submit a zldr-logger log" do
    user1=create_test_user
    sign_in user1

    #upload log
    upload_file = fixture_file_upload("files/logs/zl2dr.adi",'text/plain')
    post :savefile, upload: {doc_callsign: user1.callsign, doc_location: '', doc_no_create: false, doc_ignore_error: false, doc_do_not_lookup: false, doc: upload_file}
    assert_response :redirect
    log=Log.order(:created_at).last

    #log created
    assert_equal user1.id, log.user1_id, "User ID"
    assert_equal ['NZ-0001', 'ZL3/CB-001'].sort, log.asset_codes.sort, "Asset codes"
    assert_equal ['pota park', 'summit'].sort, log.asset_classes.sort, "Asset classes"
    assert_equal user1.callsign, log.callsign1, "Callsign"
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
    assert_equal ['NZ-0001', 'ZL3/CB-001'], contacts[0].asset1_codes, "Asset1_codes"
    assert_equal "ESTIMATED RSTS BY EAR-OMETER ON G90", contacts[0].comments1, "Comment1"

    #rest of entries exist
    assert_equal "VK4MWL", contacts[1].callsign2, "Callsign"
  end

  test "non logged in cannot submit log" do
    user1=create_test_user

    #upload log
    upload_file = fixture_file_upload("files/logs/zl2dr.adi",'text/plain')
    post :savefile, upload: {doc_callsign: user1.callsign, doc_location: '', doc_no_create: false, doc_ignore_error: false, doc_do_not_lookup: false, doc: upload_file}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "cannot submit log ofr another users callsign" do
    user1=create_test_user
    user2=create_test_user
    sign_in user2

    #upload log
    upload_file = fixture_file_upload("files/logs/zl2dr.adi",'text/plain')
    post :savefile, upload: {doc_callsign: user1.callsign, doc_location: '', doc_no_create: false, doc_ignore_error: false, doc_do_not_lookup: false, doc: upload_file}
    assert_response :success

    assert_select '#file_errors', /Create log 0 failed: you cannot create a log for a callsign not registered to your account/
  end

  test "can specify do not lookup on log upload" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1)
    user1=create_test_user
    sign_in user1

    upload_file = fixture_file_upload("files/logs/single.adi",'text/plain')
    post :savefile, upload: {doc_callsign: user1.callsign, doc_location: asset1.code, doc_no_create: false, doc_ignore_error: false, doc_do_not_lookup: true, doc: upload_file}
    assert_response :redirect

    log=Log.order(:created_at).last

    #log created
    assert_equal [asset1.code].sort, log.asset_codes.sort, "Asset codes"
    assert_equal ['hut'].sort, log.asset_classes.sort, "Asset classes"

    #contacts created
    contacts=log.contacts.order(:time)

    #1st entry correct 
    assert_equal [asset1.code].sort, contacts[0].asset1_codes.sort, "Asset codes"
  end

  test "can specify lookup on log upload" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1)
    user1=create_test_user
    sign_in user1

    upload_file = fixture_file_upload("files/logs/single.adi",'text/plain')
    post :savefile, upload: {doc_callsign: user1.callsign, doc_location: asset1.code, doc_no_create: false, doc_ignore_error: false, doc_do_not_lookup: false, doc: upload_file}
    assert_response :redirect

    log=Log.order(:created_at).last

    #log created
    assert_equal [asset1.code, asset2.code].sort, log.asset_codes.sort, "Asset codes"
    assert_equal ['hut', 'park'].sort, log.asset_classes.sort, "Asset classes"

    #contacts created
    contacts=log.contacts.order(:time)

    #1st entry correct 
    assert_equal [asset1.code, asset2.code].sort, contacts[0].asset1_codes.sort, "Asset codes"
  end

  #TODO: Only known contacts
  #TODO: Ignore errors and continue
  #
  ##################################################################
  # LOAD / SAVE spreadsheet
  ##################################################################


end
