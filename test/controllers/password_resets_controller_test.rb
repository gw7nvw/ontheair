# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class PasswordResetsControllerTest < ActionController::TestCase
  test "Can get password reset form" do
    get :new

    assert_response :success

    assert_select '#password_reset_email' 
    assert_select '#submit' 
  end

  test "Can request password reset" do
    user=create_test_user(email: "reset_test@test.com")

    post :create, password_reset: {email: "reset_test@test.com"}
    assert_response :redirect

    assert_equal "Email sent with password reset instructions", flash[:info]
    token=session[:token]

    get :edit, {id: token, email: user.email}
    assert_response :success
    assert_select '#email' do assert_select "[value=?]", user.email end

    assert_select '#user_password'
    assert_select '#user_password_confirmation' 
    
    patch :update, id: token, email: "reset_test@test.com", user: {password: 'dummy', password_confirmation: 'dummy'}

    assert_response :redirect
    assert_redirected_to '/users/'+URI.escape(user.callsign)

    assert_equal "Password has been reset.", flash[:success]
  end

  # TODO: this behaviour is not good as it allows emails to be hacked by force
  test "request reset for wrong email" do
    user=create_test_user(email: "reset_test@test.com")

    post :create, password_reset: {email: "bad@email.com"}
    assert_response :success
    assert_match "Email address not found", @response.body
  end

  test "Can't reset to blank password or mismatch" do
    user=create_test_user(email: "reset_test@test.com")

    post :create, password_reset: {email: "reset_test@test.com"}
    assert_response :redirect

    assert_equal "Email sent with password reset instructions", flash[:info]
    token=session[:token]

    get :edit, {id: token, email: user.email}
    assert_response :success
    assert_select '#email' do assert_select "[value=?]", user.email end

    assert_select '#user_password'
    assert_select '#user_password_confirmation' 
   
    #blank passwords 
    patch :update, id: token, email: "reset_test@test.com", user: {password: '', password_confirmation: ''}
    assert_response :success
    assert_match "Password/confirmation can&#39;t be blank", @response.body

    #mismatching passwords
    patch :update, id: token, email: "reset_test@test.com", user: {password: 'test1', password_confirmation: 'test2'}
    assert_response :success
    assert_select '#error_explanation', /Password confirmation doesn&#39;t match Password/
  end

end
