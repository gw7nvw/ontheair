require 'test_helper'

class CrawlerHandlingTest < ActionDispatch::IntegrationTest

  test "log source IP for get to monitored page" do
    self.remote_addr = "122.56.0.1" # Standard Telecom NZ IP address


    assert_difference 'UserAgent.count', 1, "New user agent entry created" do
      get "/"
    end

    assert_response :success
    assert_select '#crumbs', /Home/, "Expected to get home page"

    ua=UserAgent.last
    assert_equal "122.56.0.1", ua.user_ip, "Expected correct IP" 
    assert_equal 1, ua.html_count, "Expected 1 html request"
    assert_equal 0, ua.js_count, "Expected no js request"
    assert_equal 0, ua.suspicious_access_count, "Expected no suspiscious access"
    assert_not_equal true, ua.confirmed_bot, "Should not be marked as bot"
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as suspect bot"

    assert_difference 'UserAgent.count', 0, "No new user agent entry created" do
      get '/', xhr: true, params: { format: :js }
get "/"
    end

    assert_response :success
    assert_select '#crumbs', /Home/, "Expected to get home page"

    ua=UserAgent.last
    assert_equal "122.56.0.1", ua.user_ip, "Expected correct IP"
    assert_equal 2, ua.html_count, "Expected 2 html request"
    assert_equal 1, ua.js_count, "Expected 1 js request"
    assert_equal 0, ua.suspicious_access_count, "Expected no suspiscious access"
    assert_not_equal true, ua.confirmed_bot, "Should not be marked as bot"
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as suspect bot"
  end

  test "do not log source IP for unmonitored pages" do
    user1 = create_test_user()
    user1.update_column(:acctnumber, '+61407833843')
    asset1=create_test_asset(asset_type: 'summit', region: 'OT', location: create_point(169.1,-45.2), code_prefix: 'ZL3/OT-')
    sota_prefix=asset1.code[0..2]
    sota_suffix=asset1.code[4..-1].gsub('-','')


    self.remote_addr = "122.56.0.2" # Standard Telecom NZ IP address
    assert_difference 'UserAgent.count', 0, "No new user agent entry created" do
      get "/api/VK.json"
    end
    assert_response :success


    assert_difference 'UserAgent.count', 0, "No new user agent entry created" do
      sms_payload = {
        from: "+61407833843",
        text: "SPOT #{user1.callsign} #{sota_prefix} #{sota_suffix} 7.085 SSB SOTA *[iPnP]",
        sentStamp: 1788041858000,
        receivedStamp: 1788041859090,
        sim: "sim1"
      }

      res = post "/posts/sms",
           params: sms_payload,
           as: :json # Automatically sets the HTTP headers to application/json
    end
  end

  test "track redirects and trigger suspect" do
    self.remote_addr = "122.56.0.3" # Standard Telecom NZ IP address
    assert_difference 'UserAgent.count', 1, "new user agent entry created" do
      get "/users"
    end
    assert_response :redirect

    ua=UserAgent.last
    assert_equal "122.56.0.3", ua.user_ip, "Expected correct IP"
    assert_equal 1, ua.html_count, "Expected 1 html request"
    assert_equal 0, ua.js_count, "Expected no js request"
    assert_equal 1, ua.suspicious_access_count, "Expected no suspiscious access"
    assert_not_equal true, ua.confirmed_bot, "Should not be marked as bot"
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as suspect bot"

    #5 redirects allowed
    4.times do
      get "/users"
      assert_response :redirect
    end
    ua.reload
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"

    #then get challenged
    get "/users"
    assert_response :redirect
    assert_redirected_to "/challenge?referring_url=%2Fusers"
     
    ua.reload
    assert_equal "122.56.0.3", ua.user_ip, "Expected correct IP"
    assert_equal 5, ua.html_count, "Expected 5 html request"
    assert_equal 0, ua.js_count, "Expected no js request"
    assert_equal 5, ua.suspicious_access_count, "Expected no suspiscious access"
    assert_not_equal true, ua.confirmed_bot, "Should not be marked as bot"
    assert_equal true, ua.suspected_bot, "Should be marked as suspect bot"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as suspect bot"
  end

  test "track js ratio and trigger suspect after 10 requests if stats poor" do
    self.remote_addr = "122.56.0.4" # Standard Telecom NZ IP address
    #10 gets allowed
    10.times do
      get "/"
      assert_response :success
    end
    ua=UserAgent.last
    assert_equal "122.56.0.4", ua.user_ip, "Expected correct IP"
    assert_equal 10, ua.html_count, "Expected 10 html request"
    assert_equal 0, ua.js_count, "Expected no js request"
    assert_equal 0, ua.suspicious_access_count, "Expected no suspiscious access"
    assert_not_equal true, ua.confirmed_bot, "Should not be marked as bot"
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as suspect bot"

    get "/"
    ua.reload
    assert_response :redirect
    assert_redirected_to "/challenge?referring_url=%2F"

    ua.reload
    assert_equal "122.56.0.4", ua.user_ip, "Expected correct IP"
    assert_equal 10, ua.html_count, "Expected 10 html request"
    assert_equal 0, ua.js_count, "Expected no js request"
    assert_equal 0, ua.suspicious_access_count, "Expected no suspiscious access"
    assert_not_equal true, ua.confirmed_bot, "Should not be marked as bot"
    assert_equal true, ua.suspected_bot, "Should be marked as suspect bot"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as suspect bot"

    #suspect can still get signin page
    get "/signin"
    assert_response :success

    #suspect can still get api
    get "/api/VK.json"
    assert_response :success

  end

  test "Verify human works ok" do
    self.remote_addr = "122.56.0.5" # Standard Telecom NZ IP address
    get '/challenge?referring_url=%2F'
    assert_response :success
    assert_select '#crumbs', /Confirmation/, "Expected to get challenge page"

    human_challenge_token = session[:human_challenge_token]
    assert_not_nil human_challenge_token, "The challenge token was not injected into the session"

    # Step 3: Simulate the browser submitting the correct token via a form POST.
    # The session cookie automatically tags along on this second request!
    get "/challenge/verify", params: { id: human_challenge_token }

    # Step 4: Verify it passes the challenge successfully
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select '#crumbs', /Home/, "Expected to get home page"

    ua=UserAgent.last
    assert_equal "122.56.0.5", ua.user_ip, "Expected correct IP"
    assert_not_equal true, ua.confirmed_bot, "Should not be marked as bot"
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"
    assert_equal true, ua.confirmed_human, "Should not be marked as suspect bot"
  end

  test "Verify override bot works ok" do
    self.remote_addr = "122.56.0.6" # Standard Telecom NZ IP address
    get "/"
    assert_response :success
    #mark us as a bot
    ua=UserAgent.last
    ua.confirmed_bot = true
    ua.save

    get '/challenge?referring_url=%2F'
    assert_response :success
    assert_select '#crumbs', /Confirmation/, "Expected to get challenge page"

    human_challenge_token = session[:human_challenge_token]
    assert_not_nil human_challenge_token, "The challenge token was not injected into the session"

    # Step 3: Simulate the browser submitting the correct token via a form POST.
    # The session cookie automatically tags along on this second request!
    get "/challenge/verify", params: { id: human_challenge_token }

    # Step 4: Verify it passes the challenge successfully and bot status is cleared
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select '#crumbs', /Home/, "Expected to get home page"

    ua=UserAgent.last
    assert_equal "122.56.0.6", ua.user_ip, "Expected correct IP"
    assert_not_equal true, ua.confirmed_bot, "Should no longer be marked as bot"
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"
    assert_equal true, ua.confirmed_human, "Should not be marked as suspect bot"
  end

  test "Verify bad or missing token rejected" do
    self.remote_addr = "122.56.0.7" # Standard Telecom NZ IP address
    get '/challenge?referring_url=%2F'
    assert_response :success
    assert_select '#crumbs', /Confirmation/, "Expected to get challenge page"

    human_challenge_token = session[:human_challenge_token]
    assert_not_nil human_challenge_token, "The challenge token was not injected into the session"

    # Step 3: Simulate the browser submitting the correct token via a form POST.
    # The session cookie automatically tags along on this second request!
    get "/challenge/verify", params: { id: "bad token" }

    # Step 4: Verify it passes the challenge successfully and bot status is cleared
    assert_response :success
    assert_select '#crumbs', /Confirmation/, "Expected to get challenge page again"

    ua=UserAgent.last
    assert_equal "122.56.0.7", ua.user_ip, "Expected correct IP"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as human"

    # try with no token
    get "/challenge/verify"

    # Step 4: Verify it passes the challenge successfully and bot status is cleared
    assert_response :success
    assert_select '#crumbs', /Confirmation/, "Expected to get challenge page again"

    ua=UserAgent.last
    assert_equal "122.56.0.7", ua.user_ip, "Expected correct IP"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as human"
  end

  test "Trap spprings successfully" do
    self.remote_addr = "122.56.0.8" # Standard Telecom NZ IP address
    get '/challenge/node/1234'
    assert_response :forbidden

    ua=UserAgent.last
    assert_equal "122.56.0.8", ua.user_ip, "Expected correct IP"
    assert_equal true, ua.confirmed_bot, "Should be marked as bot"
    assert_not_equal true, ua.suspected_bot, "Should not be marked as suspect bot"
    assert_not_equal true, ua.confirmed_human, "Should not be marked as suspect bot"
  end

  test "Marked bot cannot access any controlled" do
    self.remote_addr = "122.56.0.9" # Standard Telecom NZ IP address
    get '/challenge/node/1234'
    assert_response :forbidden

    get '/assets'
    assert_response :forbidden

    get '/spots'
    assert_response :forbidden

    #but can get /signin
    get '/signin'
    assert_response :success
    #but can get /challenge
    get '/challenge'
    assert_response :success
  end
end

