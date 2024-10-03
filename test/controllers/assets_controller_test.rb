# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class AssetsControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX / FIND
  ##################################################################
  test "Should get index page" do
    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Places/
    assert_select '#crumbs', /All/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Add/}
    assert_select '#controls', {count: 0, text: /CSV/}
    assert_select '#controls', {count: 0, text: /GPX/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Logged in user should get index page" do
    sign_in users(:zl3cc)

    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Places/
    assert_select '#crumbs', /All/

    #Action control bar
    #does not show admin version
    assert_select '#controls', {count: 0, text: /Add/}

    #does show logged in version
    assert_select '#controls', /CSV/
    assert_select '#controls', /GPX/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Admin user should get index page" do
    sign_in users(:zl4nvw)

    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Places/
    assert_select '#crumbs', /All/

    #Action control bar
    #does show logged in version
    assert_select '#controls', /Add/
    assert_select '#controls', /CSV/
    assert_select '#controls', /GPX/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Shows all assets by default" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1)

    get :index
    assert_response :success
    assert_match 'option selected="selected" value="all"', @response.body

    #data:
    table=get_table_test(@response.body, 'place_table')
    assert_equal 3, get_row_count_test(table), "3 rows"
    row=get_row_test(table,2)
    assert_match /Hut/, get_col_test(row,1), "Correct programme"
    assert_match /#{asset1.code}/, get_col_test(row,2), "Correct code"
    assert_match /#{asset1.name}/, get_col_test(row,3), "Correct name"
    assert_match /#{asset1.region}/, get_col_test(row,4), "Correct region"
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,5), "Correct related place"
    assert_match /#{asset1.description}/, get_col_test(row,6), "Correct description"

    row=get_row_test(table,3)
    assert_match /Park/, get_col_test(row,1), "Correct programme"
    assert_match /#{asset2.code}/, get_col_test(row,2), "Correct code"
    assert_match /#{asset2.name}/, get_col_test(row,3), "Correct name"
    assert_match /#{asset2.region}/, get_col_test(row,4), "Correct region"
    assert_no_match /ZL/, get_col_test(row,5), "No related place"
    assert_match /#{asset2.description}/, get_col_test(row,6), "Correct description"
  end

  test "Can filter by asset type" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1, name: 'test park')

    get :index, type: 'hut'
    assert_response :success
    assert_match 'option selected="selected" value="hut"', @response.body

    #data:
    table=get_table_test(@response.body, 'place_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,2)
    assert_match /Hut/, get_col_test(row,1), "Correct programme"
    assert_match /#{asset1.code}/, get_col_test(row,2), "Correct code"
    assert_match /#{asset1.name}/, get_col_test(row,3), "Correct name"
    assert_match /#{asset1.region}/, get_col_test(row,4), "Correct region"
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,5), "Correct related place"
    assert_match /#{asset1.description}/, get_col_test(row,6), "Correct description"
  end

  test "Can search by name" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1, name: 'test park')

    get :index, asset_type: {name: 'all'}, minor: 'on', searchtext: 'park'
    assert_response :success
    assert_match 'option selected="selected" value="all"', @response.body
    assert_select "#searchtext" do |temp|
      assert_match 'park', temp.to_s, "Search text shown"
    end

    #data:
    table=get_table_test(@response.body, 'place_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,2)
    assert_match /Park/, get_col_test(row,1), "Correct programme"
    assert_match /#{asset2.code}/, get_col_test(row,2), "Correct code"
    assert_match /#{asset2.name}/, get_col_test(row,3), "Correct name"
    assert_match /#{asset2.region}/, get_col_test(row,4), "Correct region"
  end

  test "Active toggle" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1, name: 'test park', is_active: false)

    #include inactive assets
    get :index, asset_type: {name: 'all'}, minor: 'on', active: 0
    assert_response :success

    #data:
    table=get_table_test(@response.body, 'place_table')
    assert_equal 3, get_row_count_test(table), "3 rows - inactive record included"

    #exclude inactive assets
    get :index, asset_type: {name: 'all'}, minor: 'on'
    assert_response :success

    #data:
    table=get_table_test(@response.body, 'place_table')
    assert_equal 2, get_row_count_test(table), "2 rows - only active shown"
  end

  test "Minor toggle" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1, name: 'test park', minor: true)

    #include minor assets
    get :index, asset_type: {name: 'all'}
    assert_response :success

    #data:
    table=get_table_test(@response.body, 'place_table')
    assert_equal 3, get_row_count_test(table), "3 rows - minor record included"

    #Now exclude minor assets
    get :index, asset_type: {name: 'all'}, minor: 'on'
    assert_response :success

    #data:
    table=get_table_test(@response.body, 'place_table')
    assert_equal 2, get_row_count_test(table), "2 rows - only non minor shown"
  end

  ##################################################################
  # SHOW 
  ##################################################################
  test "View asset" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(173,-45), test_radius: 0.1, name: 'test park', minor: true)

    get :show, {id: asset1.safecode}
    assert_response :success
    #Breadcrumbs
    assert_select '#crumbs', /Places/
    assert_select '#crumbs', /#{asset1.name}/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Associate/}
    assert_select '#controls', {count: 0, text: /Edit/}

    assert_select '#controls', /Index/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#id', /#{asset1.code}/, "Code"
    assert_select '#name', /#{asset1.name}/, "Name"
    assert_select '#class', /Hut/, "Class"
    assert_select '#description', /#{asset1.description}/, "Description"
    assert_select '#lies_within', /#{make_regex_safe(asset2.codename)}/, "Contained by"
    assert_select '#region', /Canterbury/, "Region"
    assert_select '#district', /Christchurch/, "District"
    assert_select '#trad_owner', /Ngāi Tahu/, "Iwi"
    assert_select '#location', /NZTM2000: 1600000, 5017050/, "location"
    assert_select '#maidenhead', /RE65ma/, "maidenhead"
    assert_select '#active', /Yes/, "active"
  end

  test "View asset shows activators, chasers" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user

    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut')

    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)
    contact2=create_test_contact(user1, user3, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00'.to_time)

    log2=create_test_log(user4, date: '2023-01-01'.to_date)
    contact3=create_test_contact(user5, user4, log_id: log2.id, asset2_codes: [asset1.code], time: '2022-01-01 00:00'.to_time)

    get :show, {id: asset1.safecode}
    assert_response :success
    assert_select '#activated_by', /#{user1.callsign}/, "activated by"
    assert_select '#activated_by', /#{user4.callsign}/, "activated by"
    assert_select '#chased_by', /#{user2.callsign}/, "chased by"
    assert_select '#chased_by', /#{user3.callsign}/, "chased by"
    assert_select '#chased_by', /#{user5.callsign}/, "chased by"
    assert_select '#first_activation', /#{user1.callsign} -&gt; #{user3.callsign}/, "first activation"
  end

  test "View asset shows external activators, chasers" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user

    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-')

    activation=create_test_external_activation(user1,asset1, date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01 02:00'.to_time)
    chase2=create_test_external_chase(activation,user3,asset1,time: '2022-01-01 01:00'.to_time)

    activation2=create_test_external_activation(user4,asset1, date: '2023-01-01'.to_date)
    chase3=create_test_external_chase(activation2,user5,asset1,time: '2023-01-01 00:00'.to_time)

    get :show, {id: asset1.safecode}
    assert_response :success
    assert_select '#activated_by', /#{user1.callsign}/, "activated by"
    assert_select '#activated_by', /#{user4.callsign}/, "activated by"
    assert_select '#chased_by', /#{user2.callsign}/, "chased by"
    assert_select '#chased_by', /#{user3.callsign}/, "chased by"
    assert_select '#chased_by', /#{user5.callsign}/, "chased by"
    assert_select '#first_activation', /#{user1.callsign} -&gt; #{user3.callsign}/, "first activation"
  end
  
  #links
  test "View asset shows web links" do
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-')
    weblink=create_test_web_link(asset1, 'https://hutbagger.nz/1', 'hutbagger')

    get :show, {id: asset1.safecode}
    assert_response :success
    assert_select '#showlinks', /https:\/\/hutbagger.nz\/1/, "hutbagger link"
  end

  #photos
  test "View asset shows photo" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-')
    photo=create_test_photo(user1, asset1,  'photo title', 'This is a description')

    get :show, {id: asset1.safecode}
    assert_response :success
    assert_match /href="\/photos\/#{photo.id}"/, @response.body
  end


  #comments
  test "View asset shows comments" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-')
    comment=create_test_comment(user1, asset1,  'This is a comment')

    get :show, {id: asset1.safecode}
    assert_response :success
    assert_select '#comment_box', /This is a comment/, "comment"
    assert_select '#comment_box', /#{user1.callsign}/, "comment author"
    assert_select '#comment_box', /commented/, "comment"
    assert_select '#comment_box', /#{comment.updated_at.strftime('%Y-%m-%d')}/, "comment date"
  end


  ##################################################################
  # CREATE 
  ##################################################################
  test "Can view New Asset form" do
    sign_in users(:zl4nvw)

    get :new
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Places/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', {count: 1, text: /Cancel/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    assert_select '#asset_id'
    assert_select '#asset_code'
    assert_select '#asset_asset_type'
    assert_select '#asset_region'
    assert_select '#asset_district'
    assert_select '#asset_name'
    assert_select '#asset_az_radius'
    assert_select '#asset_points'
    assert_select '#asset_location'
    assert_select '#asset_x'
    assert_select '#asset_y'
    assert_select '#asset_altitude'
    assert_select '#asset_valid_from'
    assert_select '#asset_valid_to'
    assert_select '#asset_is_active'
    assert_select '#asset_is_nzart'
    assert_select '#asset_minor'
    assert_select '#submit'
  end

  test "Non editor cannot view New Asset form" do
    sign_in users(:zl3cc)
    get :new
    assert_response :redirect
    assert_redirected_to /assets/

    assert_equal "You do not have permissions to create a new asset",  flash[:error]
  end

  test "Not logged in cannot view New Asset form" do
    get :new
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Can create an asset" do
    sign_in users(:zl4nvw)

    post :create, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "Test Hut", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :redirect
    assert_redirected_to /\/assets\/[0-9]*/
    assert_equal "Success!", flash[:success]
    asset=Asset.last
    assert_equal "ZLP/XX-9999", asset.code
    assert_equal "Hut", asset.asset_type
    assert_equal "CB", asset.region
    assert_equal "CC", asset.district
    assert_equal "Test Hut", asset.name
    assert_equal 172, asset.location.x.to_i
    assert_equal -43, asset.location.y.to_i
    assert_equal 100, asset.altitude
    assert_equal "2020-01-01", asset.valid_from.strftime("%Y-%m-%d")
    assert_equal "2024-12-31", asset.valid_to.strftime("%Y-%m-%d")
    assert_equal true, asset.is_active
    assert_equal true, asset.is_nzart
    assert_equal false, asset.minor
    assert_equal 0.1, asset.az_radius
    assert_equal 5, asset.points
  end

  test "Non editor cannot post New Asset form" do
    sign_in users(:zl3cc)
    post :create, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "Test Hut", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :redirect
    assert_redirected_to /assets/

    assert_equal "You do not have permissions to create a new asset",  flash[:error]
  end

  test "Non logged in cannot post New Asset form" do
    post :create, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "Test Hut", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "invalid asset params rejected correctly" do
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-')
    sign_in users(:zl4nvw)
    #no name
    post :create, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :success
    assert_select "#error_explanation", /Name/

    #duplicate code
    post :create, asset: {code: asset1.code, asset_type: "Hut", region: "CB", district: "CC", name: "name", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :success
    assert_select "#error_explanation", /Code/
  end


  ##################################################################
  # EDIT 
  ##################################################################
  test "Can view Edit Asset form" do
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-', az_radius: 0.1, points: 5, altitude: 100, is_nzart: true, minor: false)
    sign_in users(:zl4nvw)

    get :edit, {id: asset1.safecode}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Places/
    assert_select '#crumbs', /test hut/

    #Action control bar
    assert_select '#controls', {count: 1, text: /Cancel/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    assert_select '#asset_id' do assert_select "[value=?]", asset1.id end
    assert_select '#asset_code' do assert_select "[value=?]", asset1.code end
    assert_select '#asset_asset_type' do assert_select "[value=?]", 'hut' end
    assert_select '#asset_region' do assert_select "[value=?]", 'CB'  end
    assert_select '#asset_district' do assert_select "[value=?]", 'CC' end
    assert_select '#asset_name' do assert_select "[value=?]", 'test hut' end
    assert_select '#asset_az_radius' do assert_select "[value=?]", 0.1 end
    assert_select '#asset_points' do assert_select "[value=?]", 5 end
    assert_select '#asset_location' 
    assert_select '#asset_x' do assert_select "[value=?]", asset1.x end
    assert_select '#asset_y' do assert_select "[value=?]", asset1.y end
    assert_select '#asset_altitude' do assert_select "[value=?]", 100 end
    assert_select '#asset_valid_from' do assert_select "[value=?]", "1900-01-01" end
    assert_select '#asset_valid_to' 
    assert_select '#asset_is_active' do assert_select "[checked=?]", "checked" end
    assert_select '#asset_is_nzart' do assert_select "[checked=?]", "checked" end
    assert_select '#asset_minor' do assert_select "[checked=?]", "checked", {count: 0} end
    assert_select '#submit'
  end

  test "Non editor cannot view Edit Asset form" do
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-', az_radius: 0.1, points: 5, altitude: 100, is_nzart: true, minor: false)
    sign_in users(:zl3cc)
    get :edit, {id: asset1.safecode}
    assert_response :redirect
    assert_redirected_to /assets/

    assert_equal "You do not have permissions to create a new asset",  flash[:error]
  end

  test "Not logged in cannot view edit Asset form" do
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-', az_radius: 0.1, points: 5, altitude: 100, is_nzart: true, minor: false)
    get :edit, {id: asset1.safecode}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Edit non existant asset handled correctly" do
    sign_in users(:zl4nvw)
    get :edit, {id: 'ZLP/XX-9999'}
    assert_response :redirect
    assert_redirected_to /assets/

    assert_equal "Asset not found",  flash[:error]
  end

  test "Can update an asset" do
    asset=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-', az_radius: 0.1, points: 5, altitude: 100, is_nzart: true, minor: false)
    sign_in users(:zl4nvw)

    patch :update, id: asset.id, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "Test Hut", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :redirect
    assert_redirected_to /\/assets\/[0-9]*/
    assert_equal "Asset details updated", flash[:success]
    asset.reload
    assert_equal "ZLP/XX-9999", asset.code
    assert_equal "Hut", asset.asset_type
    assert_equal "CB", asset.region
    assert_equal "CC", asset.district
    assert_equal "Test Hut", asset.name
    assert_equal 172, asset.location.x.to_i
    assert_equal -43, asset.location.y.to_i
    assert_equal 100, asset.altitude
    assert_equal "2020-01-01", asset.valid_from.strftime("%Y-%m-%d")
    assert_equal "2024-12-31", asset.valid_to.strftime("%Y-%m-%d")
    assert_equal true, asset.is_active
    assert_equal true, asset.is_nzart
    assert_equal false, asset.minor
    assert_equal 0.1, asset.az_radius
    assert_equal 5, asset.points
  end

  test "Non editor cannot update Edit Asset form" do
    sign_in users(:zl3cc)
    asset=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-', az_radius: 0.1, points: 5, altitude: 100, is_nzart: true, minor: false)

    patch :update, id: asset.id, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "Test Hut", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :redirect
    assert_redirected_to /assets/

    assert_equal "You do not have permissions to update an asset",  flash[:error]

    #not updated
    asset.reload
    assert_not_equal "ZLP/XX-9999", asset.code
  end

  test "Not logged in cannot update edit Asset form" do
    asset=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-', az_radius: 0.1, points: 5, altitude: 100, is_nzart: true, minor: false)

    patch :update, id: asset.id, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "Test Hut", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Update non existant asset handled correctly" do
    sign_in users(:zl4nvw)
    patch :update, id: 99999, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "Test Hut", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :redirect
    assert_redirected_to /assets/
    
    assert_match /Asset not found/,  flash[:error]
  end

  test "invalid asset params rejected correctly in edit" do
    asset1=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-')
    asset2=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-')
    sign_in users(:zl4nvw)
    #no name
    patch :update, id: asset1.id, asset: {code: "ZLP/XX-9999", asset_type: "Hut", region: "CB", district: "CC", name: "", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :success
    assert_select "#error_explanation", /Name/

    #duplicate code
    patch :update, id: asset1.id, asset: {code: asset2.code, asset_type: "Hut", region: "CB", district: "CC", name: "", x: 1580000, y: 5180000, altitude: 100, valid_from: "2020-01-01", valid_to: "2024-12-31", is_active: true, is_nzart: true, minor: false, az_radius: 0.1, points: 5}
    assert_response :success
    assert_select "#error_explanation", /Code/
  end

  ##################################################################
  # DELETE 
  ##################################################################
  test "Can delete an asset" do
    asset=create_test_asset(asset_type: 'summit', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut', code_prefix: 'ZL3/CB-', az_radius: 0.1, points: 5, altitude: 100, is_nzart: true, minor: false)
    assets=Asset.count
    sign_in users(:zl4nvw)

    patch :update, {delete: true, id: asset.id}
    assert_response :redirect
    assert_no_match /Failed/, flash[:error]
    assert_match /Asset deleted/, flash[:success]
  
    assert_equal assets-1, Asset.count  
  end

end
