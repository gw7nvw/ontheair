require 'test_helper'

class TestTest < ActionDispatch::IntegrationTest

  test "can see the welcome page" do
    get "/"
    assert_response :success
    assert_select "h1", "ZL ... On The Air"
  end

end
