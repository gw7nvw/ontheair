require "test_helper"
include ApplicationHelper
include SessionsHelper
class RegionsControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX / FIND
  ##################################################################
  test "Should get index page" do
    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Regions/

    #Action control bar
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #should get list of regions
    table=get_table_test(@response.body, 'region_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /CB/, get_col_test(row,1), "Correct code"
    assert_match /Canterbury/, get_col_test(row,2), "Correct region"
    row=get_row_test(table,3)
    assert_match /OT/, get_col_test(row,1), "Correct code"
    assert_match /Otago/, get_col_test(row,2), "Correct region"

    
  end

  test "should get show page" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-43))
    asset2=create_test_asset(asset_type: 'park', region: 'CB', location: create_point(173,-43), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1)

    get :show, {id: 'CB'}
    assert_response :success
    assert_select '#code', /CB/
    assert_select '#name', /Canterbury/
    assert_select '#callsign', {value: '*'}
    assert_select '#submit', {value: 'Show'}

    #districts table
    table=get_table_test(@response.body, 'district_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /CC/, get_col_test(row,1), "Correct code"
    assert_match /Christchurch/, get_col_test(row,2), "Correct name"
    row=get_row_test(table,3)
    assert_match /WA/, get_col_test(row,1), "Correct code"
    assert_match /Waimate/, get_col_test(row,2), "Correct name"

    #Places
    table=get_table_test(@response.body, 'hut')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /#{asset1.name}/, get_col_test(row,1), "Correct name"
    assert_match /#{asset1.code}/, get_col_test(row,2), "Correct code"
 
    table=get_table_test(@response.body, 'park')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /#{asset2.name}/, get_col_test(row,1), "Correct name"
    assert_match /#{asset2.code}/, get_col_test(row,2), "Correct code"
  end

  test "should show activaity" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-43))
    asset4=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173.1,-43))
    asset2=create_test_asset(asset_type: 'park', region: 'CB', location: create_point(173,-43), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'summit', region: 'CB', location: create_point(173,-45), code_prefix: 'ZL3/CB-')

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)
    contact2=create_test_contact(user1, user3, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00'.to_time)

    
    #chaser log
    log2=create_test_log(user2, date: '2023-01-01'.to_date)
    contact3=create_test_contact(user2, user1, log_id: log2.id, asset2_codes: [asset2.code], time: '2022-01-01 00:00'.to_time)

    #external log
    activation=create_test_external_activation(user1,asset3, date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset3,time: '2022-01-01 02:00'.to_time)

    get :show, {id: 'CB'}
    assert_response :success
    assert_select '#callsign', {value: '*'}

    #Places
    #activated hut
    table=get_table_test(@response.body, 'hut')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_match /YES/, get_col_test(row,3), "Activated by all=yes"
    assert_match /YES/, get_col_test(row,4), "Chased by all=yes"
    #unactivated hut
    row=get_row_test(table,3)
    assert_no_match /YES/, get_col_test(row,3), "Activated by all!=yes"
    assert_no_match /YES/, get_col_test(row,4), "Chased by all!=yes"

    #chaser logged activation 
    table=get_table_test(@response.body, 'park')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /YES/, get_col_test(row,3), "Activated by all=yes"
    assert_match /YES/, get_col_test(row,4), "Chased by all=yes"

    #externally logged activation
    table=get_table_test(@response.body, 'summit')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /YES/, get_col_test(row,3), "Activated by all=yes"
    assert_match /YES/, get_col_test(row,4), "Chased by all=yes"

    #now filter by user1
    get :show, {id: 'CB', callsign: user1.callsign}
    assert_response :success
    assert_select '#callsign', {value: user1.callsign}

    #Places
    #activated hut
    table=get_table_test(@response.body, 'hut')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_match /YES/, get_col_test(row,3), "Activated by user1=yes"
    assert_no_match /YES/, get_col_test(row,4), "Not Chased by user1"
    #unactivated hut
    row=get_row_test(table,3)
    assert_no_match /YES/, get_col_test(row,3), "Activated by user1!=yes"
    assert_no_match /YES/, get_col_test(row,4), "Chased by user1!=yes"

    #chaser logged activation 
    table=get_table_test(@response.body, 'park')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /YES/, get_col_test(row,3), "Activated by user1=yes"
    assert_no_match /YES/, get_col_test(row,4), "Chased by user1!=yes"

    #externally logged activation
    table=get_table_test(@response.body, 'summit')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /YES/, get_col_test(row,3), "Activated by user1 =yes"
    assert_no_match /YES/, get_col_test(row,4), "Chased by user1!=yes"

    #now filter by user2
    get :show, {id: 'CB', callsign: user2.callsign}
    assert_response :success
    assert_select '#callsign', {value: user2.callsign}

    #Places
    #activated hut
    table=get_table_test(@response.body, 'hut')
    assert_equal 4, get_row_count_test(table), "4 rows"
    row=get_row_test(table,2)
    assert_no_match /YES/, get_col_test(row,3), "Not Activated by user2"
    assert_match /YES/, get_col_test(row,4), "Chased by user2"
    #unactivated hut
    row=get_row_test(table,3)
    assert_no_match /YES/, get_col_test(row,3), "Not Activated by user2"
    assert_no_match /YES/, get_col_test(row,4), "Not Chased by user2"

    #chaser logged activation 
    table=get_table_test(@response.body, 'park')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_no_match /YES/, get_col_test(row,3), "Not Activated by user2"
    assert_match /YES/, get_col_test(row,4), "Chased by user2"

    #externally logged activation
    table=get_table_test(@response.body, 'summit')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_no_match /YES/, get_col_test(row,3), "Not Activated by user2"
    assert_match /YES/, get_col_test(row,4), "Chased by user2"
  end

  test "logged in user sees their own data by default" do
    sign_in users(:zl4nvw)

    user1=User.find_by(callsign: 'ZL4NVW')
    user2=create_test_user

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-43))

    #activator log
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)

    get :show, {id: 'CB'}
    assert_response :success
    assert_select '#callsign', {value: 'ZL4NVW'}

    #Places
    #activated hut
    table=get_table_test(@response.body, 'hut')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /YES/, get_col_test(row,3), "Activated by ZL4NVW=yes"
    assert_no_match /YES/, get_col_test(row,4), "Chased by ZL4NVW=no"
  end
end
