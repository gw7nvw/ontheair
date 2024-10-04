# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class AwardsControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX
  ##################################################################
  test "Should get index page" do
    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Awards/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Add/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Logged in user should get index page" do
    sign_in users(:zl3cc)

    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Awards/

    #Action control bar
    #does not show admin version
    assert_select '#controls', {count: 0, text: /Add/}

    #does show logged in version
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Admin user should get index page" do
    sign_in users(:zl4nvw)

    get :index
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Awards/

    #Action control bar
    #does show logged in version
    assert_select '#controls', /Add/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Shows all awards by default" do
    get :index
    assert_response :success

    #data:
    table=get_table_test(@response.body, 'award_table')
    
    assert_equal Award.count, get_row_count_test(table), Award.count.to_s+" rows"
    assert_match 'Activated all district', @response.body, "District awards listed"
    assert_match 'Activated all region', @response.body, "Region awards listed"
    assert_match 'Hut Chaser', @response.body, "Threshold awards listed"
  end

  test "Shows stats for district / region award" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', district: 'CC', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', district: 'CC', location: create_point(173,-45), test_radius: 0.1, name: 'test park')

    #award issues when 1 / 1 parks activated
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user1.check_completion_awards('district')

    get :index
    assert_response :success

    #data:
    table=get_table_test(@response.body, 'award_table')
    row=get_row_test(table,1)
    assert_match /Activated all district \(huts\)/, get_col_test(row,1), "Correct award"
    assert_match /Christchurch/, get_col_test(row,2), "District completion listed"
    assert_match /1/, get_col_test(row,2), "Correct count"
  end

  ##################################################################
  # SHOW
  ##################################################################
  test "Should get show page" do
    award=Award.first
    get :show, {id: award.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Awards/
    assert_select '#crumbs', /#{make_regex_safe(award.name)}/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', /Index/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#name', /#{make_regex_safe(award.name)}/, "Name"
    assert_select '#description', /#{make_regex_safe(award.description)}/, "Description"

    assert_select '#id', {count: 0}
  end

  test "Admin should get full show page" do
    sign_in users(:zl4nvw)

    award=Award.first
    get :show, {id: award.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Awards/
    assert_select '#crumbs', /#{make_regex_safe(award.name)}/

    #Action control bar
    #does show logged in version
    assert_select '#controls', /Edit/
    assert_select '#controls', /Index/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #data
    assert_select '#name', /#{make_regex_safe(award.name)}/, "Name"
    assert_select '#description', /#{make_regex_safe(award.description)}/, "Description"
    assert_select '#id', /#{award.id}/, "ID"
    assert_select '#programme', /#{award.programme}/, "Progaramme"
    assert_select '#threshold_based', /#{award.count_based ? "Yes" : "No"}/, "Count Based?"
    assert_select '#district', /#{award.all_district ? "Yes" : "No"}/, "All of district?"
    assert_select '#region', /#{award.all_region ? "Yes" : "No"}/, "All of region?"
    assert_select '#programme', /#{award.all_programme ? "Yes" : "No"}/, "All of programme?"
    assert_select '#activations', /#{award.activated ? "Yes" : "No"}/, "For activations?"
    assert_select '#chases', /#{award.chased ? "Yes" : "No"}/, "For chases?"
    assert_select '#p2p', /#{award.p2p ? "Yes" : "No"}/, "For p2p?"
    assert_select '#active', /#{award.is_active ? "Yes" : "No"}/, "Is active?"

    #no-one has this award
    assert_select '#no_award', /No-one has achieved this award yet. Be the first!/, "Not awarded text"
    
  end

  test "Awardees listed - threshold" do
    user1=create_test_user
    award=Award.find_by(count_based: true, activated: true, programme: 'hut')
    user1.issue_award(award.id,10)

    get :show, {id: award.id}
    assert_response :success

    #no not awarded text
    assert_select '#no_award', {count: 0}, "No award text not shown"
   
    #award table
    table=get_table_test(@response.body, 'award_table')
    assert_equal 1, get_row_count_test(table), "1 awardee listed"

    row=get_row_test(table,1)
    assert_match /#{user1.callsign}/, get_col_test(row,1), "Correct callsign"
    assert_match /bronze/, get_col_test(row,2), "Correct award"
    assert_match /#{Time.now.in_time_zone('UTC').strftime('%Y-%m-%d')}/, get_col_test(row,3), "Correct awarded date"
    assert_no_match /Expired/, get_col_test(row,4), "Not expired"
  end

  test "Awardees listed - district" do
    #Use localtime to check timezone handling
    tz=Timezone.find_by(name: 'Pacific/Auckland')
    user1=create_test_user(timezone: tz.id)
    sign_in user1
    award=Award.find_by(all_district: true, chased: true, activated: false, programme: 'park')
    district=District.find_by(district_code: 'CC')
    user1.issue_completion_award('district',district.id,'chaser','park')
    user1.retire_completion_award('district',district.id,'chaser','park')

    get :show, {id: award.id}
    assert_response :success

    #no not awarded text
    assert_select '#no_award', {count: 0}, "No award text not shown"
   
    #award table
    table=get_table_test(@response.body, 'award_table')
    assert_equal 1, get_row_count_test(table), "1 awardee listed"

    row=get_row_test(table,1)
    assert_match /#{user1.callsign}/, get_col_test(row,1), "Correct callsign"
    assert_match /Christchurch/, get_col_test(row,2), "Correct district"
    assert_match /park chaser/, get_col_test(row,2), "Correct award"
    assert_match /#{Time.now.in_time_zone('Pacific/Auckland').strftime('%Y-%m-%d')}/, get_col_test(row,3), "Correct awarded date"
    assert_match /Expired/, get_col_test(row,4), "Expired"
  end

  test "View non existant award handled correctly" do
    sign_in users(:zl4nvw)
    get :show, {id: 999999}
    assert_response :redirect
    assert_redirected_to /awards/

    assert_equal "Award not found",  flash[:error]
  end


  ##################################################################
  # ADD
  ##################################################################
  test "Can view New Award form" do
    sign_in users(:zl4nvw)

    get :new
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Awards/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', {count: 1, text: /Cancel/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    assert_select '#award_id'
    assert_select '#award_name'
    assert_select '#award_description'
    assert_select '#award_programme'
    assert_select '#award_count_based'
    assert_select '#award_all_district'
    assert_select '#award_all_region'
    assert_select '#award_all_programme'
    assert_select '#award_p2p'
    assert_select '#award_activated'
    assert_select '#award_chased'
    assert_select '#award_user_qrp'
    assert_select '#award_contact_qrp'
    assert_select '#award_allow_repeat_visits'
    assert_select '#award_is_active'
    assert_select '#submit'
  end

  test "Non editor cannot view New award form" do
    sign_in users(:zl3cc)
    get :new
    assert_response :redirect
    assert_redirected_to /awards/

    assert_equal "You do not have permissions to create a new award",  flash[:error]
  end

  test "Not logged in cannot view New award form" do
    get :new
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Can create an award" do
    sign_in users(:zl4nvw)

    post :create, award: {name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: true, all_district: false, all_region: false, all_programme: false, p2p: false, user_qrp: false, contact_qrp: false, allow_repeat_visits: true, activated: true, chased: true, programme: 'hut', is_active: true}
    assert_response :redirect
    assert_redirected_to /\/awards\/[0-9]*/
    assert_equal "Success!", flash[:success]
    award=Award.all.order(:created_at).last
    assert_equal 'new award', award.name
    assert_equal 'award description', award.description
    assert_equal 'You have earned an award', award.email_text
    assert_equal true, award.count_based
    assert_equal false, award.all_district
    assert_equal false, award.all_region
    assert_equal false, award.all_programme
    assert_equal false, award.p2p
    assert_equal false, award.user_qrp
    assert_equal false, award.contact_qrp
    assert_equal true, award.allow_repeat_visits
    assert_equal true, award.activated
    assert_equal true, award.chased
    assert_equal true, award.is_active
    assert_equal 'hut', award.programme
  end

  test "Can create a completion award" do
    sign_in users(:zl4nvw)

    post :create, award: {name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: false, all_district: true, all_region: true, all_programme: true, p2p: true, user_qrp: true, contact_qrp: true, allow_repeat_visits: false, activated: false, chased: false, programme: 'hut', is_active: false}
    assert_response :redirect
    assert_redirected_to /\/awards\/[0-9]*/
    assert_equal "Success!", flash[:success]
    award=Award.all.order(:created_at).last
    assert_equal 'new award', award.name
    assert_equal 'award description', award.description
    assert_equal 'You have earned an award', award.email_text
    assert_equal false, award.count_based
    assert_equal true, award.all_district
    assert_equal true, award.all_region
    assert_equal true, award.all_programme
    assert_equal true, award.p2p
    assert_equal true, award.user_qrp
    assert_equal true, award.contact_qrp
    assert_equal false, award.allow_repeat_visits
    assert_equal false, award.activated
    assert_equal false, award.chased
    assert_equal false, award.is_active
    assert_equal 'hut', award.programme
  end
  test "Non editor cannot post New award form" do
    sign_in users(:zl3cc)

    post :create, award: {name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: false, all_district: true, all_region: true, all_programme: true, p2p: true, user_qrp: true, contact_qrp: true, allow_repeat_visits: false, activated: false, chased: false, programme: 'hut', is_active: false}
    assert_response :redirect
    assert_redirected_to /awards/

    assert_equal "You do not have permissions to create a new award",  flash[:error]
  end

  test "Non logged in cannot post New award form" do
    post :create, award: {name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: false, all_district: true, all_region: true, all_programme: true, p2p: true, user_qrp: true, contact_qrp: true, allow_repeat_visits: false, activated: false, chased: false, programme: 'hut', is_active: false}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # EDIT
  ##################################################################
  test "Can view Edit award form" do
    award=Award.first
    sign_in users(:zl4nvw)

    get :edit, {id: award.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Awards/
    assert_select '#crumbs', /#{make_regex_safe(award.name)}/
    assert_select '#crumbs', /Edit/

    #Action control bar
    assert_select '#controls', {count: 1, text: /Cancel/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    assert_select '#award_id' do assert_select "[value=?]", award.id end
    assert_select '#award_name' do assert_select "[value=?]", award.name end
    assert_select '#award_description' do assert_select "textarea", /#{award.description}/ end
    assert_select '#award_programme' do assert_select "[value=?]", award.programme end
    assert_select '#award_count_based' do assert_select "[checked=?]", "checked", {count: award.count_based ? 1 : 0} end
    assert_select '#award_all_district' do assert_select "[checked=?]", "checked", {count: award.all_district ? 1 : 0} end
    assert_select '#award_all_region' do assert_select "[checked=?]", "checked", {count: award.all_region ? 1 : 0} end
    assert_select '#award_all_programme' do assert_select "[checked=?]", "checked", {count: award.all_programme ? 1 : 0} end
    assert_select '#award_p2p' do assert_select "[checked=?]", "checked", {count: award.p2p ? 1 : 0} end
    assert_select '#award_activated' do assert_select "[checked=?]", "checked", {count: award.activated ? 1 : 0} end
    assert_select '#award_chased' do assert_select "[checked=?]", "checked", {count: award.chased ? 1 : 0} end
    assert_select '#award_user_qrp' do assert_select "[checked=?]", "checked", {count: award.user_qrp ? 1 : 0} end
    assert_select '#award_contact_qrp' do assert_select "[checked=?]", "checked", {count: award.contact_qrp ? 1 : 0} end
    assert_select '#award_allow_repeat_visits' do assert_select "[checked=?]", "checked", {count: award.allow_repeat_visits ? 1 : 0} end
    assert_select '#award_is_active' do assert_select "[checked=?]", "checked", {count: award.is_active ? 1 : 0} end
  end

  test "Non editor cannot view edit award form" do
    award=Award.first
    sign_in users(:zl3cc)
    get :edit, {id: award.id}

    assert_response :redirect
    assert_redirected_to /awards/

    assert_equal "You do not have permissions to edit an award",  flash[:error]
  end

  test "Not logged in cannot view edit award form" do
    award=Award.first
    get :edit, {id: award.id}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Can update an award" do
    award=Award.create(name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: true, all_district: false, all_region: false, all_programme: false, p2p: false, user_qrp: false, contact_qrp: false, allow_repeat_visits: true, activated: true, chased: true, programme: 'hut', is_active: true)
    sign_in users(:zl4nvw)

    patch :update, id: award.id, award: {name: 'updated award', description: 'updated description', email_text: 'You have earned an award', count_based: false, all_district: true, all_region: true, all_programme: true, p2p: true, user_qrp: true, contact_qrp: true, allow_repeat_visits: false, activated: false, chased: false, programme: 'hut', is_active: false}

    assert_response :redirect
    assert_redirected_to /\/awards\/[0-9]*/
    assert_equal "Award details updated", flash[:success]

    award.reload
    assert_equal 'updated award', award.name
    assert_equal 'updated description', award.description
    assert_equal 'You have earned an award', award.email_text
    assert_equal false, award.count_based
    assert_equal true, award.all_district
    assert_equal true, award.all_region
    assert_equal true, award.all_programme
    assert_equal true, award.p2p
    assert_equal true, award.user_qrp
    assert_equal true, award.contact_qrp
    assert_equal false, award.allow_repeat_visits
    assert_equal false, award.activated
    assert_equal false, award.chased
    assert_equal false, award.is_active
    assert_equal 'hut', award.programme
  end

  test "Non editor cannot update award" do
    sign_in users(:zl3cc)
    award=Award.create(name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: true, all_district: false, all_region: false, all_programme: false, p2p: false, user_qrp: false, contact_qrp: false, allow_repeat_visits: true, activated: true, chased: true, programme: 'hut', is_active: true)

    patch :update, id: award.id, award: {name: 'updated award', description: 'updated description', email_text: 'You have earned an award', count_based: false, all_district: true, all_region: true, all_programme: true, p2p: true, user_qrp: true, contact_qrp: true, allow_repeat_visits: false, activated: false, chased: false, programme: 'hut', is_active: false}
    assert_response :redirect
    assert_redirected_to /awards/

    assert_equal "You do not have permissions to edit an award",  flash[:error]

    #not updated
    award.reload
    assert_not_equal "updated award", award.name
  end

  test "Not logged in cannot update award" do
    award=Award.create(name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: true, all_district: false, all_region: false, all_programme: false, p2p: false, user_qrp: false, contact_qrp: false, allow_repeat_visits: true, activated: true, chased: true, programme: 'hut', is_active: true)

    patch :update, id: award.id, award: {name: 'updated award', description: 'updated description', email_text: 'You have earned an award', count_based: false, all_district: true, all_region: true, all_programme: true, p2p: true, user_qrp: true, contact_qrp: true, allow_repeat_visits: false, activated: false, chased: false, programme: 'hut', is_active: false}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # DELETE 
  ##################################################################
  test "Can delete an award" do
    award=Award.create(name: 'new award', description: 'award description', email_text: 'You have earned an award', count_based: true, all_district: false, all_region: false, all_programme: false, p2p: false, user_qrp: false, contact_qrp: false, allow_repeat_visits: true, activated: true, chased: true, programme: 'hut', is_active: true)
    awards=Award.count
    sign_in users(:zl4nvw)

    patch :update, {delete: true, id: award.id}
    assert_response :redirect
    assert_no_match /Failed/, flash[:error]
    assert_match /Award deleted/, flash[:success]

    assert_equal awards-1, Award.count
  end

end
