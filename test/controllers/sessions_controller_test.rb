# typed: false
require "test_helper"
class SessionsControllerTest < ActionController::TestCase

  test "Should get sign in page" do
    get :new
    assert_response :success
    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Sign In/

    #Action control bar
    assert_select '#controls', /Forgotten Password/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #fields
    assert_select '#session_email'
    assert_select '#session_password'
    assert_select "#submit", {value: "Sign In"}
  end

  test "Unsuccessful signin should get login page and error" do
    post :create, session: { email: users(:zl4nvw).callsign, password: 'badpassword' } 
    assert_response :success
    assert_select '.alert', "Invalid user/password combination"
    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Sign In/
  end

  test "Inactive account refused login" do
    post :create, session: { email: users(:zl4dis).callsign, password: 'dummy' } 
    assert_response :success
    assert_select '.alert', /Account not registered/

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Sign In/
  end

  test "Successful signin should get home page" do

    post :create, session: { email: users(:zl4nvw).callsign, password: 'dummy' }
    assert_redirected_to root_path
  end
end
