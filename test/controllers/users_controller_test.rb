require "test_helper"
include ApplicationHelper
include SessionsHelper
class UsersControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX / FIND
  ##################################################################
  test "Should get index page" do
    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', {count: 0, text: /Add/}
    assert_select '#controls', {count: 0, text: /Download/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #search
    assert_select '#searchtext'
    assert_select '#find', {value: 'Find'}

    #should get list of users
    table=get_table_test(@response.body, 'user_table')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_match /ZL3CC/, get_col_test(row,1), "Correct callsign"
    assert_match /Bob/, get_col_test(row,2), "Name"
    assert_match /checked=\"checked\"/, get_col_test(row,4), "Registered"
    assert_no_match /bob@bob.net/, get_col_test(row,5), "No email for not admin"
    assert_no_match /checked=\"checked\"/, get_col_test(row,5), "Not editor"
    assert_match /checked=\"checked\"/, get_col_test(row,6), "Active"
    row=get_row_test(table,3)
    assert_match /ZL4DIS/, get_col_test(row,1), "Correct callsign"
    row=get_row_test(table,4)
    assert_match /ZL4NVW/, get_col_test(row,1), "Correct callsign"
    assert_match /checked=\"checked\"/, get_col_test(row,5), "editor"
  end

  test "Logged in user Should get index page" do
    sign_in users(:zl3cc)
    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/

    #Action control bar
    #show logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', {count: 0, text: /Add/}
    assert_select '#controls', {count: 0, text: /Download/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #search
    assert_select '#searchtext'
    assert_select '#find', {value: 'Find'}

    #should get list of users
    table=get_table_test(@response.body, 'user_table')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_match /ZL3CC/, get_col_test(row,1), "Correct callsign"
    assert_match /Bob/, get_col_test(row,2), "Name"
    assert_match /checked=\"checked\"/, get_col_test(row,4), "Registered"
    assert_no_match /bob@bob.net/, get_col_test(row,5), "No email for not admin"
    assert_no_match /checked=\"checked\"/, get_col_test(row,5), "Not editor"
    assert_match /checked=\"checked\"/, get_col_test(row,6), "Active"
    row=get_row_test(table,3)
    assert_match /ZL4DIS/, get_col_test(row,1), "Correct callsign"
    row=get_row_test(table,4)
    assert_match /ZL4NVW/, get_col_test(row,1), "Correct callsign"
    assert_match /checked=\"checked\"/, get_col_test(row,5), "editor"
  end

  test "Logged in admin user Should get index page" do
    sign_in users(:zl4nvw)
    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/

    #Action control bar
    #show logged in version
    assert_select '#controls', /Edit/
    assert_select '#controls', /Add/
    assert_select '#controls', /Download/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #search
    assert_select '#searchtext'
    assert_select '#find', {value: 'Find'}

    #should get list of users
    table=get_table_test(@response.body, 'user_table')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_match /ZL3CC/, get_col_test(row,1), "Correct callsign"
    assert_match /Bob/, get_col_test(row,2), "Name"
    assert_match /checked=\"checked\"/, get_col_test(row,4), "Registered"
    assert_match /bob@bob.net/, get_col_test(row,5), "email for admin"
    assert_no_match /checked=\"checked\"/, get_col_test(row,6), "Not admin"
    assert_no_match /checked=\"checked\"/, get_col_test(row,7), "Not editor"
    assert_match /checked=\"checked\"/, get_col_test(row,8), "Active"
    row=get_row_test(table,3)
    assert_match /ZL4DIS/, get_col_test(row,1), "Correct callsign"
    row=get_row_test(table,4)
    assert_match /ZL4NVW/, get_col_test(row,1), "Correct callsign"
    assert_match /checked=\"checked\"/, get_col_test(row,6), "admin"
    assert_match /checked=\"checked\"/, get_col_test(row,7), "editor"
  end

  test "non logged in can view user" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    uc=create_callsign(user1, from_date: '2020-01-01'.to_date, to_date: '2023-01-01'.to_date) #add secondary callsign
    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    #2 activations and 2 chases on successive days
    log=create_test_log(user1, asset_codes: [asset1.code], date: Time.now)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: Time.now)

    log2=create_test_log(user2, asset_codes: [asset2.code], date: Time.now)
    contact2=create_test_contact(user2, user1, log_id: log2.id, asset1_codes: [asset2.code], time: Time.now)

    log3=create_test_log(user1, asset_codes: [asset1.code], date: 1.day.ago)
    contact3=create_test_contact(user1, user2, log_id: log3.id, asset1_codes: [asset1.code], time: 1.day.ago)

    log4=create_test_log(user2, asset_codes: [asset2.code], date: 1.day.ago)
    contact4=create_test_contact(user2, user1, log_id: log4.id, asset1_codes: [asset2.code], time: 1.day.ago)

    user1.update_score
    user2.update_score

    get :show, {id: 'ZL4NVW'}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /ZL4NVW/

    #Action control bar
    #show non logged in version
    assert_select '#controls', {count: 0, text: /Edit/}

    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#page_title', /ZL4NVW/
    assert_select '#user_status', /Registered user/
    assert_select '#user_status', /authorised to edit hut and park data/
    assert_select '#realname', /Matt Briggs/
    assert_select '#PIN', {count: 0, text: /1234/}
    assert_select '#acctnumber', {count: 0, text: /\+64271234567/}
    assert_select '#email', {count: 0, text: /mattbriggs@yahoo.com/}
    assert_select '#home_qth', /Alexandra/
    assert_select '#timezonename', /#{Timezone.find(1).name}/
    assert_select '#logs_pota', /Yes/
    assert_select '#logs_wwff', /Yes/

    #callsigns
    table=get_table_test(@response.body, 'callsign_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /ZL4NVW/, get_col_test(row,1), "Correct callsign"
    assert_match /1900-01-01/, get_col_test(row,2), "Correct start date"
    assert_match /present/, get_col_test(row,3), "Correct end date"
    row=get_row_test(table,3)
    assert_match /#{uc.callsign}/, get_col_test(row,1), "Correct callsign"
    assert_match /2020-01-01/, get_col_test(row,2), "Correct start date"
    assert_match /2023-01-01/, get_col_test(row,3), "Correct end date"
  
    #mail
    assert_select '#mail_table', {count: 0},"No mail table for someone else"

    #awards
    assert_select '#awards_link'

    #Stats
    assert_select '#parks_bagged', /Bagged: 2 unique/
    #activations are by year so 1 (1)
    assert_select '#parks_activated', /Activated: 1 unique/ 
    assert_select '#parks_activated', /1 total/ 
    assert_select '#parks_qualified', /Qualified: 0 unique/
    assert_select '#parks_qualified', /0 total/
    #chases are by day so 1 (2)
    assert_select '#parks_chased', /Chased: 1 unique/
    assert_select '#parks_chased', /2 total/

    #logs and contacts
    assert_select '#contacts', /4 \(view\)/
    assert_select '#logs', /2 \(view\)/
  end

  test "logged in can view another user" do
    sign_in users(:zl3cc)
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    uc=create_callsign(user1, from_date: '2020-01-01'.to_date, to_date: '2023-01-01'.to_date) #add secondary callsign
    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    #2 activations and 2 chases on successive days
    log=create_test_log(user1, asset_codes: [asset1.code], date: Time.now)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: Time.now)

    log2=create_test_log(user2, asset_codes: [asset2.code], date: Time.now)
    contact2=create_test_contact(user2, user1, log_id: log2.id, asset1_codes: [asset2.code], time: Time.now)

    log3=create_test_log(user1, asset_codes: [asset1.code], date: 1.day.ago)
    contact3=create_test_contact(user1, user2, log_id: log3.id, asset1_codes: [asset1.code], time: 1.day.ago)

    log4=create_test_log(user2, asset_codes: [asset2.code], date: 1.day.ago)
    contact4=create_test_contact(user2, user1, log_id: log4.id, asset1_codes: [asset2.code], time: 1.day.ago)

    user1.update_score
    user2.update_score

    get :show, {id: 'ZL4NVW'}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /ZL4NVW/

    #Action control bar
    #show non logged in version
    assert_select '#controls', {count: 0, text: /Edit/}

    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#page_title', /ZL4NVW/
    assert_select '#user_status', /Registered user/
    assert_select '#user_status', /authorised to edit hut and park data/
    assert_select '#realname', /Matt Briggs/
    assert_select '#PIN', {count: 0, text: /1234/}
    assert_select '#acctnumber', {count: 0, text: /\+64271234567/}
    assert_select '#email', {count: 0, text: /mattbriggs@yahoo.com/}
    assert_select '#home_qth', /Alexandra/
    assert_select '#timezonename', /#{Timezone.find(1).name}/
    assert_select '#logs_pota', /Yes/
    assert_select '#logs_wwff', /Yes/

    #callsigns (read-only version)
    table=get_table_test(@response.body, 'callsign_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /ZL4NVW/, get_col_test(row,1), "Correct callsign"
    assert_match /1900-01-01/, get_col_test(row,2), "Correct start date"
    assert_match /present/, get_col_test(row,3), "Correct end date"
    assert_no_match /Edit/, get_col_test(row,4), "Edit"
    assert_no_match /Delete/, get_col_test(row,4), "Delete"
    row=get_row_test(table,3)
    assert_match /#{uc.callsign}/, get_col_test(row,1), "Correct callsign"
    assert_match /2020-01-01/, get_col_test(row,2), "Correct start date"
    assert_match /2023-01-01/, get_col_test(row,3), "Correct end date"
    assert_no_match /Edit/, get_col_test(row,4), "Edit"
    assert_no_match /Delete/, get_col_test(row,4), "Delete"
  
    #mail
    assert_select '#mail_table', {count: 0},"No mail table for someone else"

    #awards
    assert_select '#awards_link'

    #Stats
    assert_select '#parks_bagged', /Bagged: 2 unique/
    #activations are by year so 1 (1)
    assert_select '#parks_activated', /Activated: 1 unique/ 
    assert_select '#parks_activated', /1 total/ 
    assert_select '#parks_qualified', /Qualified: 0 unique/
    assert_select '#parks_qualified', /0 total/
    #chases are by day so 1 (2)
    assert_select '#parks_chased', /Chased: 1 unique/
    assert_select '#parks_chased', /2 total/

    #logs and contacts
    assert_select '#contacts', /4 \(view\)/
    assert_select '#logs', /2 \(view\)/
  end

  test "logged in can view / edit self" do
    sign_in users(:zl3cc)
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    user2.add_callsigns
    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    #2 activations and 2 chases on successive days
    log=create_test_log(user1, asset_codes: [asset1.code], date: Time.now)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: Time.now)

    log2=create_test_log(user2, asset_codes: [asset2.code], date: Time.now)
    contact2=create_test_contact(user2, user1, log_id: log2.id, asset1_codes: [asset2.code], time: Time.now)

    log3=create_test_log(user1, asset_codes: [asset1.code], date: 1.day.ago)
    contact3=create_test_contact(user1, user2, log_id: log3.id, asset1_codes: [asset1.code], time: 1.day.ago)

    log4=create_test_log(user2, asset_codes: [asset2.code], date: 1.day.ago)
    contact4=create_test_contact(user2, user1, log_id: log4.id, asset1_codes: [asset2.code], time: 1.day.ago)

    #Add zl3cc to alert mail list
    UserTopicLink.create(user_id: user2.id, topic_id: ALERT_TOPIC, mail: true)

    user1.update_score
    user2.update_score

    get :show, {id: 'ZL3CC'}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /ZL3CC/

    #Action control bar
    #show logged in version
    assert_select '#controls', /Edit/

    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#page_title', /ZL3CC/
    assert_select '#user_status', /Registered user/
    assert_select '#user_status', /not authorised to edit hut and park data/
    assert_select '#realname', /Bob/
    assert_select '#PIN', /1234/
    assert_select '#acctnumber', /\+64271234567/
    assert_select '#email', /bob@bob.net/
    assert_select '#home_qth', /Christchurch/
    assert_select '#timezonename', /#{Timezone.find(3).name}/
    assert_select '#logs_pota', /No/
    assert_select '#logs_wwff', /Yes/

    #callsigns
    table=get_table_test(@response.body, 'callsign_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /ZL3CC/, get_col_test(row,1), "Correct callsign"
    assert_match /1900-01-01/, get_col_test(row,2), "Correct start date"
    assert_match /present/, get_col_test(row,3), "Correct end date"
    assert_match /Edit/, get_col_test(row,4), "Edit"
    assert_match /Delete/, get_col_test(row,4), "Delete"
    #add callsign section present
    row=get_row_test(table,3)
    assert_select "#user_callsign_user_id"
    assert_select "#user_callsign_callsign"
    assert_select "#user_callsign_from_date"
    assert_select "#user_callsign_to_date"
    assert_select "#user_callsign_submit"
  
    #mail
    assert_select '#mail_table'
    table=get_table_test(@response.body, 'mail_table')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_match /SPOTS/, get_col_test(row,1), "Spots"
    assert_match /No/, get_col_test(row,2), "No mail"
    assert_match /Add/, get_col_test(row,3), "Add button"
    row=get_row_test(table,3)
    assert_match /ALERTS/, get_col_test(row,1), "Alerts"
    assert_match /Yes/, get_col_test(row,2), "mail"
    assert_match /Delete/, get_col_test(row,3), "Delete button"
    row=get_row_test(table,4)
    assert_match /NEWS/, get_col_test(row,1), "News"
    assert_match /No/, get_col_test(row,2), "No mail"
    assert_match /Add/, get_col_test(row,3), "Add button"
 
    #awards
    assert_select '#awards_link'

    #Stats
    assert_select '#parks_bagged', /Bagged: 2 unique/
    #activations are by year so 1 (1)
    assert_select '#parks_activated', /Activated: 1 unique/ 
    assert_select '#parks_activated', /1 total/ 
    assert_select '#parks_qualified', /Qualified: 0 unique/
    assert_select '#parks_qualified', /0 total/
    #chases are by day so 1 (2)
    assert_select '#parks_chased', /Chased: 1 unique/
    assert_select '#parks_chased', /2 total/

    #logs and contacts
    assert_select '#contacts', /4 \(view\)/
    assert_select '#logs', /2 \(view\)/
  end

  test "qrp and p2p stats" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user2=User.find_by(callsign: 'ZL3CC')
    user1.add_callsigns
    user2.add_callsigns
    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    #2 activations and 2 chases on successive days one QRP and one not
    log=create_test_log(user1, asset_codes: [asset1.code], date: Time.now, is_qrp1: true)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: Time.now, is_qrp1: true, is_qrp2: true)

    log3=create_test_log(user1, asset_codes: [asset1.code], date: 1.day.ago)
    contact3=create_test_contact(user1, user2, log_id: log3.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: 1.day.ago)

    user1.update_score
    user2.update_score

    get :show, {id: 'ZL4NVW'}
    assert_response :success

    #Stats
    assert_select '#qrps_bagged', /Bagged: 2 unique/
    #activations are by year so 1 (1)
    assert_select '#qrps_activated', /Activated: 1 unique/ 
    assert_select '#qrps_activated', /1 total/ 
    assert_select '#qrps_qualified', /Qualified: 0 unique/
    assert_select '#qrps_qualified', /0 total/
    #chases are by day so 1 (2)
    assert_select '#qrps_chased', /Chased: 1 unique/
    assert_select '#qrps_chased', /1 total/

    assert_select '#p2p_count', /Contacts: 2/
  end

  test "admin in can view user admin details" do
    sign_in users(:zl4nvw)
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    user2.add_callsigns

    #Add zl3cc to alert mail list
    UserTopicLink.create(user_id: user2.id, topic_id: ALERT_TOPIC, mail: true)

    user1.update_score
    user2.update_score

    get :show, {id: 'ZL3CC'}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /ZL3CC/

    #Action control bar
    #show logged in version
    assert_select '#controls', /Edit/

    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#page_title', /ZL3CC/
    assert_select '#user_status', /Registered user/
    assert_select '#user_status', /not authorised to edit hut and park data/
    assert_select '#realname', /Bob/
    assert_select '#PIN', /1234/
    assert_select '#acctnumber', /\+64271234567/
    assert_select '#email', /bob@bob.net/
    assert_select '#home_qth', /Christchurch/
    assert_select '#timezonename', /#{Timezone.find(3).name}/
    assert_select '#logs_pota', /No/
    assert_select '#logs_wwff', /Yes/

    #callsigns
    table=get_table_test(@response.body, 'callsign_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /ZL3CC/, get_col_test(row,1), "Correct callsign"
    assert_match /1900-01-01/, get_col_test(row,2), "Correct start date"
    assert_match /present/, get_col_test(row,3), "Correct end date"
    assert_match /Edit/, get_col_test(row,4), "Edit"
    assert_match /Delete/, get_col_test(row,4), "Delete"
    #add callsign section present
    row=get_row_test(table,3)
    assert_select "#user_callsign_user_id"
    assert_select "#user_callsign_callsign"
    assert_select "#user_callsign_from_date"
    assert_select "#user_callsign_to_date"
    assert_select "#user_callsign_submit"
  
    #mail
    assert_select '#mail_table'
    table=get_table_test(@response.body, 'mail_table')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_match /SPOTS/, get_col_test(row,1), "Spots"
    assert_match /No/, get_col_test(row,2), "No mail"
    assert_match /Add/, get_col_test(row,3), "Add button"
    row=get_row_test(table,3)
    assert_match /ALERTS/, get_col_test(row,1), "Alerts"
    assert_match /Yes/, get_col_test(row,2), "mail"
    assert_match /Delete/, get_col_test(row,3), "Delete button"
    row=get_row_test(table,4)
    assert_match /NEWS/, get_col_test(row,1), "News"
    assert_match /No/, get_col_test(row,2), "No mail"
    assert_match /Add/, get_col_test(row,3), "Add button"
  end 

####################################################################
# USER ASSETS
####################################################################
  test "can view user's bagged assets" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    user2.add_callsigns
    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    #2 activations and 2 chases on successive days
    log=create_test_log(user1, asset_codes: [asset1.code], date: Time.now)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: Time.now)

    log3=create_test_log(user1, asset_codes: [asset1.code], date: 1.day.ago)
    contact3=create_test_contact(user1, user2, log_id: log3.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: 1.day.ago)

    user1.update_score
    user2.update_score




    #bagged
    get 'assets', {id: 'ZL4NVW', asset_type: 'park', count_type: 'bagged'}
    #assert_select  "#valid_count", /2/  #cannot check as filled in by js
    assert_select  "#total_count", /2/

    #list of assets - 2 unique assets bagged
    table=get_table_test(@response.body, 'place_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,1), "Correct place"
    row=get_row_test(table,2)
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,1), "Correct place"





    #chased
    get 'assets', {id: 'ZL4NVW', asset_type: 'park', count_type: 'chased'}
    #assert_select  "#valid_count", /1/  #cannot check as filled in by js
    assert_select  "#total_count", /2/
    assert_select  "#nq_count", /1/

    #list of assets - 1 unique asset chased
    table=get_table_test(@response.body, 'place_table')
    assert_equal 1, get_row_count_test(table), "1 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,1), "Correct place"




    #activated and qualified
    get 'assets', {id: 'ZL4NVW', asset_type: 'park', count_type: 'activated'}
    #activated
    #assert_select  "#act_valid_count", /1/  #cannot check as filled in by js
    assert_select  "#act_total_count", /1/
    assert_select  "#act_nq_count", /1/
    #qualified - none as not enough contacts
    #assert_select  "#valid_count", /0/  #cannot check as filled in by js
    assert_select  "#total_count", /0/

    #list of assets - 1 unique asset activated
    table=get_table_test(@response.body, 'place_table')
    assert_equal 1, get_row_count_test(table), "1 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,1), "Correct place"
    assert_match /insufficient contacts/, get_col_test(row,1), "Not qualified"
  end

  #########################################################################
  # USER AWARDS
  #########################################################################

  test "can view user's threshold awards" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    user2.add_callsigns

    #10 contact with a hut
    count=0
    asset=[]
    log=[]
    contact=[]
    while count<10 do
      asset[count]=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut')
      log[count]=create_test_log(user1,asset_codes: [asset[count].code])
      contact[count]=create_test_contact(user1,user2,log_id: log[count].id, asset1_codes: [asset[count].code], time: '2022-01-01 00:00:00'.to_time)
      count+=1
    end
    #call manually as these callbacks are disabled in test
    user1.update_score
    user2.update_score
    user1.check_awards
    user2.check_awards

    get 'awards', {id: 'ZL3CC'}

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /ZL3CC/
    assert_select '#crumbs', /Awards/

    #Action control bar
    #show logged in version
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    table=get_table_test(@response.body, 'award_table')

    #assuming first rows are Hut (activator, chaser, uniques)
    row=get_row_test(table,2)
    assert_match /Hut Activator/, get_col_test(row,1), "Correct award"
    assert_match /0/, get_col_test(row,2), "None qualified"
    assert_no_match /Bronze/, get_col_test(row,3), "No award"
    assert_match /Bronze/, get_col_test(row,4), "Next award"
    
    row=get_row_test(table,3)
    assert_match /Hut Chaser/, get_col_test(row,1), "Correct award"
    assert_match /10/, get_col_test(row,2), "10 chased"
    assert_match /Bronze/, get_col_test(row,3), "award"
    assert_match /Silver/, get_col_test(row,4), "Next award"
    
    row=get_row_test(table,4)
    assert_match /Hut Uniques/, get_col_test(row,1), "Correct award"
    assert_match /10/, get_col_test(row,2), "10 bagged"
    assert_match /Bronze/, get_col_test(row,3), "award"
    assert_match /Silver/, get_col_test(row,4), "Next award"
  end

  test "can view user's region awards" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    user2.add_callsigns
    region=Region.find_by(sota_code: 'CB')
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')

    #no award when none of 1 parks activated
    user2.check_completion_awards('region')
    get 'awards', {id: 'ZL3CC'}
    table=get_table_test(@response.body, 'region_award_table')
    assert_equal 1, get_row_count_test(table), "1 rows - just header"


    #award issues when 1 / 1 parks activated
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user2.check_completion_awards('region')

    get 'awards', {id: 'ZL3CC'}

    table=get_table_test(@response.body, 'region_award_table')
    assert_equal 2, get_row_count_test(table), "2 rows - header and award"
    row=get_row_test(table,2)
    assert_match /Canterbury/, get_col_test(row,1), "Correct region"
    assert_match /Chaser/, get_col_test(row,2), "Correct class"
    assert_match /Park/, get_col_test(row,3), "Correct type"
    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,4), "Correct date"
    assert_no_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,5), "No expiry"
 

    #add another park to region, check award is revoked
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    user2.check_completion_awards('region')

    get 'awards', {id: 'ZL3CC'}

    table=get_table_test(@response.body, 'region_award_table')
    assert_equal 2, get_row_count_test(table), "2 rows - header and award"
    row=get_row_test(table,2)
    assert_match /Canterbury/, get_col_test(row,1), "Correct region"
    assert_match /Chaser/, get_col_test(row,2), "Correct class"
    assert_match /Park/, get_col_test(row,3), "Correct activity"
    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,4), "Correct date"
    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,5), "Correct expiry"
  end

  test "can view user's district awards" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user1.add_callsigns
    user2=User.find_by(callsign: 'ZL3CC')
    user2.add_callsigns
    region=Region.find_by(sota_code: 'CB')
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')

    #no award when none of 1 parks activated
    user1.check_completion_awards('district')
    get 'awards', {id: 'ZL4NVW'}
    table=get_table_test(@response.body, 'district_award_table')
    assert_equal 1, get_row_count_test(table), "1 rows - just header"


    #award issues when 1 / 1 parks activated
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user1.check_completion_awards('district')

    get 'awards', {id: 'ZL4NVW'}

    table=get_table_test(@response.body, 'district_award_table')
    assert_equal 2, get_row_count_test(table), "2 rows - header and award"
    row=get_row_test(table,2)
    assert_match /Christchurch/, get_col_test(row,1), "Correct region"
    assert_match /Activator/, get_col_test(row,2), "Correct class"
    assert_match /Park/, get_col_test(row,3), "Correct type"
    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,4), "Correct date"
    assert_no_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,5), "No expiry"
 

    #add another park to region, check award is revoked
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    user1.check_completion_awards('district')

    get 'awards', {id: 'ZL4NVW'}

    table=get_table_test(@response.body, 'district_award_table')
    assert_equal 2, get_row_count_test(table), "2 rows - header and award"
    row=get_row_test(table,2)
    assert_match /Christchurch/, get_col_test(row,1), "Correct region"
    assert_match /Activator/, get_col_test(row,2), "Correct class"
    assert_match /Park/, get_col_test(row,3), "Correct activity"
    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,4), "Correct date"
    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,5), "Correct expiry"
  end

  #####################################################################
  # REGION PROGRESS
  #####################################################################
  test "can view user's progress towards region awards" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)

    #show progress towards all of canterbury chased
    user2.update_score
    user2.check_completion_awards('region')
    user1.update_score
    user1.check_completion_awards('region')

    get 'region_progress', {id: user2.callsign}
    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /#{user2.callsign}/
    assert_select '#crumbs', /Awards/
    assert_select '#crumbs', /Regions/

    #Action control bar
    #show logged in version
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    table=get_table_test(@response.body, 'region_chased_table')
    assert_equal 3, get_row_count_test(table), "3 rows - header and 2 regions"

    #Relies on park being 7th column. Will need updating if new classes added
    row=get_row_test(table,2)
    assert_match /Canterbury/, get_col_test(row,1), "Correct region"
    assert_match /1\/2/, get_col_test(row,7), "Correct progress"

    #Now check activated
    get 'region_progress', {id: user1.callsign}
    assert_select '#crumbs', /#{user1.callsign}/

    table=get_table_test(@response.body, 'region_activated_table')
    assert_equal 3, get_row_count_test(table), "3 rows - header and 2 regions"

    #Relies on park being 7th column. Will need updating if new classes added
    row=get_row_test(table,2)
    assert_match /Canterbury/, get_col_test(row,1), "Correct region"
    assert_match /1\/2/, get_col_test(row,7), "Correct progress"

  end

  test "can view user's progress towards district awards" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)

    #show progress towards all of canterbury chased
    user2.update_score
    user2.check_completion_awards('district')
    user1.update_score
    user1.check_completion_awards('district')

    get 'district_progress', {id: user2.callsign}
    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /#{user2.callsign}/
    assert_select '#crumbs', /Awards/
    assert_select '#crumbs', /Districts/

    #Action control bar
    #show logged in version
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    table=get_table_test(@response.body, 'district_chased_table')
    assert_equal 5, get_row_count_test(table), "5 rows - header and 4 districts"

    #Relies on park being 7th column. Will need updating if new classes added
    row=get_row_test(table,2)
    assert_match /Canterbury/, get_col_test(row,1), "Correct region"
    assert_match /Christchurch/, get_col_test(row,2), "Correct district"
    assert_match /1\/2/, get_col_test(row,7), "Correct progress"

    #Now check activated
    get 'district_progress', {id: user1.callsign}
    assert_select '#crumbs', /#{user1.callsign}/

    table=get_table_test(@response.body, 'district_activated_table')
    assert_equal 5, get_row_count_test(table), "5 rows - header and 4 districts"

    #Relies on park being 7th column. Will need updating if new classes added
    row=get_row_test(table,2)
    assert_match /Canterbury/, get_col_test(row,1), "Correct region"
    assert_match /Christchurch/, get_col_test(row,2), "Correct district"
    assert_match /1\/2/, get_col_test(row,7), "Correct progress"

  end

  ######################################################################
  # P2P
  ######################################################################

  test "Can get user's P2P details" do
    user1=User.find_by(callsign: 'ZL4NVW')
    user2=User.find_by(callsign: 'ZL3CC')
    user1.add_callsigns
    user2.add_callsigns
    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    asset3=create_test_vkasset(award: 'WWFF', code_prefix: 'VKFF-0')
    #3 activations and 3 chases on successive days
    log=create_test_log(user1, asset_codes: [asset1.code], date: Time.now)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: Time.now)

    log2=create_test_log(user1, asset_codes: [asset1.code], date: 1.day.ago)
    contact=create_test_contact(user1, user2, log_id: log2.id, asset1_codes: [asset1.code], asset2_codes: [asset3.code], time: 1.day.ago)

    log3=create_test_log(user1, asset_codes: [asset1.code], date: 2.days.ago)
    contact3=create_test_contact(user1, user2, log_id: log3.id, asset1_codes: [asset1.code], asset2_codes: ['GFF-0001'], time: 2.days.ago)

    user1.update_score
    user2.update_score

    get :p2p, {id: 'ZL4NVW'}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /#{user1.callsign}/
    assert_select '#crumbs', /Portable 2 Portable/

    #Action control bar
    #show logged in version
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    table=get_table_test(@response.body, 'p2p_table')
    assert_equal 4, get_row_count_test(table), "4 rows - header and 3 entries"

    row=get_row_test(table,2)
    assert_match /#{2.days.ago.strftime("%Y-%m-%d")}/, get_col_test(row,1), "Correct date"
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,2), "Correct from"
    assert_match /GFF-0001/, get_col_test(row,3), "Correct to"

    row=get_row_test(table,3)
    assert_match /#{1.day.ago.strftime("%Y-%m-%d")}/, get_col_test(row,1), "Correct date"
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,2), "Correct from"
    assert_match /#{make_regex_safe(asset3.codename)}/, get_col_test(row,3), "Correct to"

    row=get_row_test(table,4)
    assert_match /#{Time.now.strftime("%Y-%m-%d")}/, get_col_test(row,1), "Correct date"
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,2), "Correct from"
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,3), "Correct to"
  end

  #TODO: Create user

  #TODO: Edit user
end
