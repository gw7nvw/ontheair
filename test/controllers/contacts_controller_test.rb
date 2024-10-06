# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class ContactsControllerTest < ActionController::TestCase

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
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Hamilton')

    #chaser log
    log2=create_test_log(user2, date: '2023-01-01'.to_date)
    contact2=create_test_contact(user2, user1, log_id: log2.id, loc_desc1: 'Hamilton', asset2_codes: [asset3.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')
    contact2b=create_test_contact(user2, user3, log_id: log2.id, loc_desc1: 'Hamilton', asset2_codes: [asset3.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #my chaser log
    log3=create_test_log(user1, date: '2023-01-01'.to_date)
    contact3=create_test_contact(user1, user2, log_id: log3.id, loc_desc1: 'Alexandra', asset2_codes: [asset4.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, {user: user1.callsign}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /#{user1.callsign}/

    #Action control bar - non logged in version
    assert_select '#controls', {count: 0, text: /View All/}
    assert_select '#controls', {count: 0, text: /Add/}
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #should get list of contacts
    table=get_table_test(@response.body, 'contact_table')
    assert_equal 4, get_row_count_test(table), "4 rows incl header"

    #My logged activation
    row=get_row_test(table,2)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit contact not logged in"
    assert_match /View/, get_col_test(row,1), "Can view contact"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user2.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /2022-01-01/, get_col_test(row,4), "Correct date"
    assert_match /01:00/, get_col_test(row,5), "Correct time"
    assert_match /7.090/, get_col_test(row,6), "Correct freq"
    assert_match /SSB/, get_col_test(row,7), "Correct mode"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,8), "Correct location1"
    assert_match /#{make_regex_safe(asset2.code)}/, get_col_test(row,8), "Correct location1"
    assert_match /Hamilton/, get_col_test(row,9), "Correct location2"

    #Chasers log of my activation
    row=get_row_test(table,3)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit contact not logged in"
    assert_match /View/, get_col_test(row,1), "Can view contact"
    assert_match /#{user2.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user1.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /2022-01-01/, get_col_test(row,4), "Correct date"
    assert_match /00:00/, get_col_test(row,5), "Correct time"
    assert_match /7.090/, get_col_test(row,6), "Correct freq"
    assert_match /SSB/, get_col_test(row,7), "Correct mode"
    assert_match /Hamilton/, get_col_test(row,8), "Correct location1"
    assert_match /#{make_regex_safe(asset3.code)}/, get_col_test(row,9), "Correct location2"
    assert_match /#{make_regex_safe(asset4.code)}/, get_col_test(row,9), "Correct location2"

    #My chaser log
    row=get_row_test(table,4)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit contact not logged in"
    assert_match /View/, get_col_test(row,1), "Can view contact"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user2.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /2022-01-01/, get_col_test(row,4), "Correct date"
    assert_match /00:00/, get_col_test(row,5), "Correct time"
    assert_match /7.090/, get_col_test(row,6), "Correct freq"
    assert_match /SSB/, get_col_test(row,7), "Correct mode"
    assert_match /Alexandra/, get_col_test(row,8), "Correct location1"
    assert_match /#{make_regex_safe(asset4.code)}/, get_col_test(row,9), "Correct location2"

    #no list of other user's contacts without me
  end

  test "Index for a user - logged in version" do
    user1=create_test_user
    user2=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Hamilton')

    #chaser log
    log2=create_test_log(user2, date: '2023-01-01'.to_date)
    contact2=create_test_contact(user2, user1, log_id: log2.id, loc_desc1: 'Hamilton', asset2_codes: [asset1.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, {user: user1.callsign}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /#{user1.callsign}/

    #Action control bar -logged in version
    assert_select '#controls', {count: 1, text: /Add/}
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #should get list of contacts
    table=get_table_test(@response.body, 'contact_table')
    assert_equal 3, get_row_count_test(table), "3 rows incl header"

    #My logged activation
    row=get_row_test(table,2)
    assert_match /Edit/, get_col_test(row,1), "Can edit own contact"
    assert_match /View/, get_col_test(row,1), "Can view contact"
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user2.callsign}/, get_col_test(row,3), "Correct party2"

    #Chasers log of my activation
    row=get_row_test(table,3)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit contact from another user"
    assert_match /View/, get_col_test(row,1), "Can view contact"
    assert_match /#{user2.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user1.callsign}/, get_col_test(row,3), "Correct party2"
  end

  test "Index for an asset" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))
    asset2=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Hamilton')

    #chaser log
    log2=create_test_log(user2, date: '2023-01-01'.to_date)
    contact2=create_test_contact(user2, user3, log_id: log2.id, loc_desc1: 'Hamilton', asset2_codes: [asset1.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #another activation
    log3=create_test_log(user1, asset_codes: [asset2.code], date: '2023-01-01'.to_date)
    contact2=create_test_contact(user1, user2, log_id: log3.id,  asset1_codes: [asset2.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, {user: 'all', asset: asset1.safecode}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /#{make_regex_safe(asset1.codename)}/

    #should get list of contacts
    table=get_table_test(@response.body, 'contact_table')
    assert_equal 3, get_row_count_test(table), "3 rows incl header"

    #My logged activation
    row=get_row_test(table,2)
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user2.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,8), "Correct location2"

    #Chasers log of an activation
    row=get_row_test(table,3)
    assert_match /#{user2.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user3.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,9), "Correct location2"

    #Other locatrion not listed
  end

  test "Index for an asset class" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))
    asset2=create_test_asset(asset_type: 'park', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-44))

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc2: 'Hamilton')

    #chaser log
    log2=create_test_log(user2, date: '2023-01-01'.to_date)
    contact2=create_test_contact(user2, user1, log_id: log2.id, loc_desc1: 'Hamilton', asset2_codes: [asset1.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    #another activation
    log3=create_test_log(user1, asset_codes: [asset2.code], date: '2023-01-01'.to_date)
    contact2=create_test_contact(user1, user2, log_id: log3.id,  asset1_codes: [asset2.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, {user: user1.callsign, class: 'hut'}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /Huts/

    #should get list of contacts - no chaser logs, no other classes
    table=get_table_test(@response.body, 'contact_table')
    assert_equal 2, get_row_count_test(table), "2 rows incl header"

    #My logged activation
    row=get_row_test(table,2)
    assert_match /#{user1.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user2.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,8), "Correct location2"
  end

  test "Index for orphan contacts" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-43))
    asset2=create_test_asset(asset_type: 'park', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-44))

    #chaser log with me as activator
    log=create_test_log(user2, date: '2022-01-01'.to_date)
    contact1=create_test_contact(user2, user1, log_id: log.id, asset2_codes: [asset1.code], time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', loc_desc1: 'Hamilton')

    #chaser log with me as activator
    log2=create_test_log(user3, date: '2023-01-01'.to_date)
    contact2=create_test_contact(user3, user1, log_id: log2.id, loc_desc1: 'Auckland', asset2_codes: [asset2.code], time: '2022-01-01 00:00'.to_time, frequency: 7.09, mode: 'SSB')

    get :index, {user: user1.callsign, orphans: true}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /#{user1.callsign}/
    assert_select '#crumbs', /Unmatched Contacts/

    #should get list of contacts - no chaser logs, no other classes
    table=get_table_test(@response.body, 'contact_table')
    assert_equal 3, get_row_count_test(table), "3 rows incl header"

    #1st contact
    row=get_row_test(table,2)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit other users contact"
    assert_match /Confirm/, get_col_test(row,1), "Can confirm contact"
    assert_match /Refute/, get_col_test(row,1), "Can refute contact"
    assert_match /#{user2.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user1.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /2022-01-01/, get_col_test(row,4), "Correct date"
    assert_match /01:00/, get_col_test(row,5), "Correct time"
    assert_match /7.090/, get_col_test(row,6), "Correct freq"
    assert_match /SSB/, get_col_test(row,7), "Correct mode"
    assert_match /Hamilton/, get_col_test(row,8), "Correct location1"
    assert_match /#{make_regex_safe(asset1.code)}/, get_col_test(row,9), "Correct location2"

    #2nd contact
    row=get_row_test(table,3)
    assert_no_match /Edit/, get_col_test(row,1), "Can not edit other users contact"
    assert_match /Confirm/, get_col_test(row,1), "Can confirm contact"
    assert_match /Refute/, get_col_test(row,1), "Can refute contact"
    assert_match /#{user3.callsign}/, get_col_test(row,2), "Correct party1"
    assert_match /#{user1.callsign}/, get_col_test(row,3), "Correct party2"
    assert_match /2022-01-01/, get_col_test(row,4), "Correct date"
    assert_match /00:00/, get_col_test(row,5), "Correct time"
    assert_match /7.090/, get_col_test(row,6), "Correct freq"
    assert_match /SSB/, get_col_test(row,7), "Correct mode"
    assert_match /Auckland/, get_col_test(row,8), "Correct location1"
    assert_match /#{make_regex_safe(asset2.code)}/, get_col_test(row,9), "Correct location2"
  end

  ##################################################################
  # SHOW 
  ##################################################################
  test "Can view a contact" do
    user1=create_test_user
    user2=create_test_user

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], is_portable1: true, is_portable2: true, is_qrp1: true, time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', name1: 'Bob', loc_desc1: 'Good spot', signal1: '59', power1: 20, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobette', signal2: '31')

    get :show, {id: contact1.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /#{contact1.id}/

    #Action control bar - non logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #data
    assert_select '#id', /#{contact1.id}/, "Conatct ID"
    assert_select '#log_id', /#{contact1.log_id}/, "Log ID"
    assert_select '#callsign1', /#{contact1.callsign1}/, "Log ID"
    assert_select '#callsign1', /Portable/, "Portable1"
    assert_select '#callsign1', /QRP/, "QRP1"
    assert_select '#callsign2', /#{contact1.callsign2}/, "Callsign2"
    assert_select '#callsign2', /Portable/, "Portable2"
    assert_select '#callsign2', {count: 0, text: /QRP/}, "QRP2"
    assert_select '#date', /2022-01-01/, "Date"
    assert_select '#time', /01:00/, "Time"
    assert_select '#frequency', /7.090/, "Frequency"
    assert_select '#mode', /SSB/, "Mode"

    #party1
    assert_select '#p1_callsign', /#{contact1.callsign1}/, "Callsign1"
    assert_select '#p1_callsign', /Portable/, "Portable1"
    assert_select '#p1_callsign', /QRP/, "QRP1"
    assert_select '#p1_name', /Bob/, "Name1"
    assert_select '#p1_signal', /59/, "Signal1"
    assert_select '#p1_asset_code1', /Hut/, "Asset class1"
    assert_select '#p1_asset_code1', /#{make_regex_safe(asset1.codename)}/, "Asset code1"
    assert_select '#p1_loc_desc', /Good spot/, 'Location descrioption1'
    assert_select '#p1_power', /20/, 'Power1'
    assert_select '#p1_transceiver', /FT818/, 'Transceiver1'
    assert_select '#p1_antenna', /EFHW/, 'Antenna1'
    
    #party2
    assert_select '#p2_callsign', /#{contact1.callsign2}/, "Callsign2"
    assert_select '#p2_callsign', /Portable/, "Portable2"
    assert_select '#p2_callsign', {count: 0, text: /QRP/}, "QRP2"
    assert_select '#p2_name', /Bobette/, "Name2"
    assert_select '#p2_signal', /31/, "Signal2"
    assert_select '#p2_asset_code1', /Park/, "Asset class2"
    assert_select '#p2_asset_code1', /#{make_regex_safe(asset2.codename)}/, "Asset code2"
  end 

  test "Logged in view own contact" do
    user1=create_test_user
    user2=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code])

    get :show, {id: contact1.id}
    assert_response :success

    #Action control bar - logged in version
    assert_select '#controls', /Edit/
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Logged in cannot edit another's contact" do
    user1=create_test_user
    user2=create_test_user
    sign_in user2

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code])

    get :show, {id: contact1.id}
    assert_response :success

    #Action control bar - logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  ##################################################################
  # NEW
  ##################################################################
  test "Can enter new contact from spot" do
    user1=create_test_user
    user2=create_test_user
    sign_in user2

    asset1=create_test_asset(asset_type: 'hut')
    spot=create_test_spot(user1, asset_codes: [asset1.code], freq: 7.090, mode: 'SSB', callsign: 'VK2IO')

    #internal spots pass -ve ID
    get :new, {spot: -spot.post.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', /Cancel/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form
    assert_select '#contact_callsign1' do assert_select "[value=?]", user2.callsign end
    assert_select '#contact_callsign2' do assert_select "[value=?]", 'VK2IO' end
    assert_select '#contact_asset2_codes' do assert_select "[value=?]", asset1.code end
    assert_select '#contact_date' do assert_select "[value=?]", /#{spot.post.created_at.strftime('%Y-%m-%d')}/ end
    assert_select '#contact_time' do assert_select "[value=?]", spot.post.created_at.strftime('%H:%M')+":00.000" end
    assert_select '#contact_frequency' do assert_select "[value=?]", 7.09 end
    assert_select '#contact_mode' do assert_select "[value=?]", 'SSB' end
    assert_select '#contact_is_qrp2'
    assert_select '#contact_is_portable2'
    assert_select '#contact_signal1'
    assert_select '#contact_signal2'
    assert_select '#contact_comments1'
    assert_select '#submit'
  end

  test "Can enter new contact from external spot" do
    user1=create_test_user
    user2=create_test_user
    sign_in user2

    spot=create_test_external_spot(user1, code: 'VKFF-0001', frequency: '7.090', mode: 'SSB', activatorCallsign: 'VK2IO')

    #external spots pass +ve ID
    get :new, {spot: spot.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Contacts/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', /Cancel/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form
    assert_select '#contact_callsign1' do assert_select "[value=?]", user2.callsign end
    assert_select '#contact_callsign2' do assert_select "[value=?]", 'VK2IO' end
    assert_select '#contact_asset2_codes' do assert_select "[value=?]", 'VKFF-0001' end
    assert_select '#contact_date' do assert_select "[value=?]", /#{spot.created_at.strftime('%Y-%m-%d')}/ end
    assert_select '#contact_time' do assert_select "[value=?]", spot.created_at.strftime('%H:%M')+":00.000" end
    assert_select '#contact_frequency' do assert_select "[value=?]", '7.090' end
    assert_select '#contact_mode' do assert_select "[value=?]", 'SSB' end
    assert_select '#contact_is_qrp2'
    assert_select '#contact_is_portable2'
    assert_select '#contact_signal1'
    assert_select '#contact_signal2'
    assert_select '#contact_comments1'
    assert_select '#submit'
  end

  test "Not logged in cannot view New contact form" do
    user1=create_test_user
    spot=create_test_external_spot(user1, code: 'VKFF-0001', frequency: '7.090', mode: 'SSB', activatorCallsign: 'VK2IO')

    get :new, {spot: spot.id}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end


  ##################################################################
  # CREATE
  ##################################################################
  test "Can create a chaser contact (and associated log)" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    sign_in user1

    post :create, contact: {callsign1: user1.callsign, callsign2: user2.callsign, asset2_codes: asset1.code+','+asset2.code, date: '2022-01-01', time: '01:02', frequency: '7.090', mode: 'SSB', is_qrp2: true, is_portable2: true, signal1: '59', signal2: '31', comments1: 'Good DX'}

    assert_response :redirect
    assert_redirected_to /\/spots*/
    assert_equal "Success!", flash[:success]

    contact=Contact.all.order(:created_at).last
    log=Log.all.order(:created_at).last

    #contact
    assert_equal user1.callsign, contact.callsign1, "My call"
    assert_equal user2.callsign, contact.callsign2, "Their call"
    assert_equal [asset1.code, asset2.code].sort, contact.asset2_codes, "Their locn"
    assert_equal '2022-01-01', contact.date.strftime('%Y-%m-%d'), "Date"
    assert_equal '01:02', contact.time.strftime('%H:%M'), "Date"
    assert_equal 7.09, contact.frequency, "Freq"
    assert_equal 'SSB', contact.mode, "Mode"
    assert_equal '59', contact.signal1, "Signal1"
    assert_equal '31', contact.signal2, "Signal2"
    assert_equal 'Good DX', contact.comments1, "Comments"

    #log
    assert_equal user1.callsign, log.callsign1, "My call"
    assert_equal '2022-01-01', log.date.strftime('%Y-%m-%d'), "Date"
  end

  test "Cannot create contact for another user" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    sign_in user3

    contacts=Contact.count

    post :create, contact: {callsign1: user1.callsign, callsign2: user2.callsign, asset2_codes: asset1.code+','+asset2.code, date: '2022-01-01', time: '01:02', frequency: '7.090', mode: 'SSB', is_qrp2: true, is_portable2: true, signal1: '59', signal2: '31', comments1: 'Good DX'}
    assert_equal contacts, Contact.count, "No contact created"
    assert_response :success
    assert_select "#error_explanation", /You do not have permission to use this callsign on this date/, "Error shown"
  end

  test "Not logged in cannot submit New contact form" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')

    contacts=Contact.count

    post :create, contact: {callsign1: user1.callsign, callsign2: user2.callsign, asset2_codes: asset1.code+','+asset2.code, date: '2022-01-01', time: '01:02', frequency: '7.090', mode: 'SSB', is_qrp2: true, is_portable2: true, signal1: '59', signal2: '31', comments1: 'Good DX'}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
    assert_equal Contact.count, contacts, "No new contact created"
  end

  ##################################################################
  # REFUTE
  ##################################################################
  test "User can refute contact with them" do
    user1=create_test_user
    user2=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user2, date: '2022-01-01'.to_date)
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code],time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', name1: 'Bob', loc_desc1: 'Good spot', signal1: '59', power1: 20, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobette', signal2: '31')

    get :refute, {id: contact1.id}
    assert_response :redirect
    assert_redirected_to /contacts/

    assert_equal 'Your location details for this contact have been updated', flash[:success]

    contact1.reload
    assert_equal [], contact1.asset2_codes, "Codes for me deleted"
    assert_match "Removed", contact1.loc_desc2, "Chaser location descruption updated"
  end 

  test "User cannot refute contact not with them" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    sign_in user3

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user2, date: '2022-01-01'.to_date)
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code],time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', name1: 'Bob', loc_desc1: 'Good spot', signal1: '59', power1: 20, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobette', signal2: '31')

    get :refute, {id: contact1.id}
    assert_response :redirect
    assert_redirected_to /contacts/

    assert_equal 'You do not have permissions to refute this contact', flash[:error]

    contact1.reload
    assert_equal [asset1.code], contact1.asset2_codes, "Codes unchanged"
  end 

  test "Not logged in cannot refute contact" do
    user1=create_test_user
    user2=create_test_user

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user2, date: '2022-01-01'.to_date)
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code],time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', name1: 'Bob', loc_desc1: 'Good spot', signal1: '59', power1: 20, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobette', signal2: '31')

    get :refute, {id: contact1.id}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # CONFIRM
  ##################################################################
  test "User can confirm contact with them" do
    user1=create_test_user
    user2=create_test_user
    sign_in user1

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user2, date: '2022-01-01'.to_date)
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code],time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', name1: 'Bob', loc_desc1: 'Good spot', signal1: '59', power1: 20, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobette', signal2: '31')

    get :confirm, {id: contact1.id}
    assert_response :redirect
    assert_redirected_to /contacts/

    assert_equal 'New activator log entry added for this contact', flash[:success]

    new_contact=Contact.last

    assert_equal contact1.date, new_contact.date, " New reverse contact correct"
    assert_equal contact1.callsign1, new_contact.callsign2, " New reverse contact correct"
    assert_equal contact1.asset1_codes, new_contact.asset2_codes, " New reverse contact correct"
    assert_equal contact1.callsign2, new_contact.callsign1, " New reverse contact correct"
    assert_equal contact1.asset2_codes, new_contact.asset1_codes, "New reverse contact correct"

    #new log created
    new_log=new_contact.log
    assert_equal contact1.date, new_log.date, " New reverse contact correct"
    assert_equal contact1.callsign2, new_log.callsign1, " New reverse contact correct"
    assert_equal contact1.asset2_codes, new_log.asset_codes, " New reverse contact correct"
  end 

  test "User cannot confirm contact not with them" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    sign_in user3

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user2, date: '2022-01-01'.to_date)
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code],time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', name1: 'Bob', loc_desc1: 'Good spot', signal1: '59', power1: 20, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobette', signal2: '31')

    get :confirm, {id: contact1.id}
    assert_response :redirect
    assert_redirected_to /contacts/

    assert_equal 'You do not have permissions to confirm this contact', flash[:error]

    contact1.reload
    assert_equal [asset1.code], contact1.asset2_codes, "Codes unchanged"
  end 

  test "Not logged in cannot confirm contact" do
    user1=create_test_user
    user2=create_test_user

    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    #activator log
    log=create_test_log(user2, date: '2022-01-01'.to_date)
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset2.code], asset2_codes: [asset1.code],time: '2022-01-01 01:00'.to_time, frequency: 7.09, mode: 'SSB', name1: 'Bob', loc_desc1: 'Good spot', signal1: '59', power1: 20, transceiver1: 'FT818', antenna1: 'EFHW', comments1: 'Tnx for contact', name2: 'Bobette', signal2: '31')

    get :confirm, {id: contact1.id}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

end


