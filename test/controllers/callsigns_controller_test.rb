# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class CallsignsControllerTest < ActionController::TestCase

  ##################################################################
  # EDIT
  ##################################################################
  test "Can edit an existing callsign" do
    sign_in users(:zl3cc)
    user=User.find_by(callsign: 'ZL3CC')
    uc=UserCallsign.find_by(user_id: user.id)

    get :edit, {id: uc.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /#{user.callsign}/
    assert_select '#crumbs', /Callsigns/
    assert_select '#crumbs', /#{uc.callsign}/

    #Action control bar
    assert_select '#controls', {count: 1, text: /Cancel/}
    assert_select '#controls', {count: 1, text: /Delete/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    #no admin fields
    assert_select '#user_callsign_id', {count: 0}
    assert_select '#user_callsign_user_id', {count: 0}
    #normal fields
    assert_select '#user_callsign_callsign' do assert_select "[value=?]", uc.callsign end
    assert_select '#user_callsign_from_date' do assert_select "[value=?]", uc.from_date.strftime('%Y-%m-%d') end
    assert_select '#user_callsign_to_date'
    assert_select '#submit'
  end

  test "admin sees admin fields" do
    sign_in users(:zl4nvw)
    user=User.find_by(callsign: 'ZL3CC')
    user.save #force creation of callsign records

    uc=UserCallsign.find_by(user_id: user.id)

    get :edit, {id: uc.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Users/
    assert_select '#crumbs', /#{user.callsign}/
    assert_select '#crumbs', /Callsigns/
    assert_select '#crumbs', /#{uc.callsign}/

    #Action control bar
    assert_select '#controls', {count: 1, text: /Cancel/}
    assert_select '#controls', {count: 1, text: /Delete/}

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    #admin fields
    assert_select '#user_callsign_id' do assert_select "[value=?]", uc.id end
    assert_select '#user_callsign_user_id' do assert_select "[value=?]", uc.user_id end
  end

  test "Another user cannot view edit callsign form" do
    user=User.find_by(callsign: 'ZL4NVW')
    user.save
    uc=UserCallsign.find_by(user_id: user.id)

    sign_in users(:zl3cc)
    get :edit, {id: uc.id}

    assert_response :redirect
    assert_redirected_to /users/

    assert_equal "You do not have permissions to edit this callsign",  flash[:error]
  end

  test "Not logged in cannot view edit callsign form" do
    user=User.find_by(callsign: 'ZL4NVW')
    user.save
    uc=UserCallsign.find_by(user_id: user.id)
    get :edit, {id: uc.id}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Can update a callsign" do
    user=create_test_user
    sign_in user
    uc=UserCallsign.find_by(user_id: user.id)

    patch :update, id: uc.id, user_callsign: {callsign: 'ZL9CBB', from_date: '2022-01-01', to_date: '2025-01-01'}

    assert_response :redirect
    assert_redirected_to "/users/"+user.callsign
    assert_equal "Callsign details updated", flash[:success]

    uc.reload
    assert_equal 'ZL9CBB', uc.callsign
    assert_equal '2022-01-01', uc.from_date.strftime('%Y-%m-%d')
    assert_equal '2025-01-01', uc.to_date.strftime('%Y-%m-%d')
  end

  test "Invalid callsign params rejected" do
    user=create_test_user
    user2=create_test_user
    sign_in user
    uc=UserCallsign.find_by(user_id: user.id)

    #duplicate call in same period
    patch :update, id: uc.id, user_callsign: {callsign: user2.callsign, from_date: '2022-01-01'}

    assert_response :success
    assert_select "#error_explanation", /This callsign is already assigned in this period/
  end

  test "Another user cannot update callsign" do
    user=User.find_by(callsign: 'ZL4NVW')
    user.save
    uc=UserCallsign.find_by(user_id: user.id)

    sign_in users(:zl3cc)
    patch :update, id: uc.id, user_callsign: {callsign: 'ZL9CBB', from_date: '2022-01-01', to_date: '2025-01-01'}

    assert_response :redirect
    assert_redirected_to /users/

    assert_equal "You do not have permissions to edit this callsign",  flash[:error]
  end

  test "Not logged in cannot update callsign" do
    user=User.find_by(callsign: 'ZL4NVW')
    user.save
    uc=UserCallsign.find_by(user_id: user.id)
    patch :update, id: uc.id, user_callsign: {callsign: 'ZL9CBB', from_date: '2022-01-01', to_date: '2025-01-01'}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # DELETE
  ##################################################################
  test "Can delete an existing callsign" do
    user=create_test_user
    sign_in user
    uc=create_callsign(user, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign

    get :delete, {id: uc.id}
    assert_response :redirect
    assert_redirected_to "/users/"+user.callsign

    assert_equal "Deleted callsign!",  flash[:success]

    newucs=UserCallsign.where(callsign: uc.callsign, user_id: user.id)
    assert_equal [], newucs, "No matching callsigns left in db"
  end

  test "Another user cannot delete callsign" do
    user=create_test_user
    uc=create_callsign(user, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
    sign_in users(:zl3cc)
    get :delete, {id: uc.id}
    assert_response :redirect
    assert_redirected_to "/users"

    assert_equal "You do not have permissions to delete this callsign",  flash[:error]
  end

  test "Not logged in cannot delete callsign" do
    user=create_test_user
    uc=create_callsign(user, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign

    get :delete, {id: uc.id}

    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  ##################################################################
  # CREATE
  ##################################################################
  test "Can create a callsign" do
    user=create_test_user
    sign_in user

    post :create, user_callsign: {user_id: user.id, callsign: 'ZL9CBB', from_date: '2022-01-01', to_date: '2025-01-01'}


    assert_response :redirect
    assert_redirected_to "/users/"+user.callsign
    assert_equal "Callsign added", flash[:success]

    uc=UserCallsign.find_by(user_id: user.id, callsign: 'ZL9CBB')
    assert_equal 'ZL9CBB', uc.callsign
    assert_equal '2022-01-01', uc.from_date.strftime('%Y-%m-%d')
    assert_equal '2025-01-01', uc.to_date.strftime('%Y-%m-%d')
  end

  test "Cannot add callsign to another user" do
    user=create_test_user
    sign_in users(:zl3cc)

    post :create, user_callsign: {user_id: user.id, callsign: 'ZL9CBB', from_date: '2022-01-01', to_date: '2025-01-01'}

    assert_response :redirect
    assert_redirected_to "/users/"+users(:zl3cc).callsign, "Overridden with our own username"
    assert_equal "Callsign added", flash[:success]

    uc=UserCallsign.find_by(callsign: 'ZL9CBB')
    assert_equal 'ZL9CBB', uc.callsign
    assert_equal users(:zl3cc).id, uc.user_id, "Own userid used, not one supplied"
    assert_equal '2022-01-01', uc.from_date.strftime('%Y-%m-%d')
    assert_equal '2025-01-01', uc.to_date.strftime('%Y-%m-%d')
  end

  test "Can add callsign to another user if we're admin" do
    user=create_test_user
    sign_in users(:zl4nvw)

    post :create, user_callsign: {user_id: user.id, callsign: 'ZL9CBB', from_date: '2022-01-01', to_date: '2025-01-01'}

    assert_response :redirect
    assert_redirected_to "/users/"+user.callsign, "Allowed to other user page"
    assert_equal "Callsign added", flash[:success]

    uc=UserCallsign.find_by(callsign: 'ZL9CBB')
    assert_equal 'ZL9CBB', uc.callsign
    assert_equal user.id, uc.user_id, "Added to other user"
    assert_equal '2022-01-01', uc.from_date.strftime('%Y-%m-%d')
    assert_equal '2025-01-01', uc.to_date.strftime('%Y-%m-%d')
  end

  test "Not logged in cannot add callsign" do
    user=create_test_user

    post :create, user_callsign: {user_id: user.id, callsign: 'ZL9CBB', from_date: '2022-01-01', to_date: '2025-01-01'}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

end
