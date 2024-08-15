require "test_helper"

class UserTest < ActiveSupport::TestCase
   test "create_user with callsign & password" do
     user=User.new(callsign: "zl1test", password: "testpassword", password_confirmation: "testpassword")
     assert user.save, "User saves OK with just callsign and password"
     user.reload
     assert user.timezonename=="UTC", "User given default UTC timezone"
     assert user.pin.length==4, "User given a PIN"

     uc=UserCallsign.find_by(user_id: user.id)
     assert uc, "UserCallsign record created"
     assert uc.callsign==user.callsign, "UserCallsign with default callsign=username"
     assert uc.from_date.strftime("%Y-%m-%d")=="1900-01-01", "should have default start date"
     assert uc.to_date==nil, "should have no end date"
   end

   test "create_user with no callsign" do
     user=User.new(password: "testpassword", password_confirmation: "testpassword")
     assert_not user.save, "User should not save without callsign"
   end

   test "create_user with no password" do
     user=User.new(callsign: "zl2test")
     assert_not user.save, "User should not save without password"
   end

   test "create_user with no password_confirmation" do
     user=User.new(callsign: "zl3test", password: "testpassword")
     assert_not user.save, "User should not save without password confirmation"
   end

   test "create_user with mismatching password_confirmation" do
     user=User.new(callsign: "zl4test", password: "testpassword", password_confirmation: "badmatch")
     assert_not user.save, "User should not save with mismatching password confirmation"
   end

   test "create_user with duplicate callsign" do
     user=User.new(callsign: "zl5test", password: "testpassword", password_confirmation: "testpassword")
     assert user.save, "First user saves OK with callsign"
     user2=User.new(callsign: "zl5test", password: "testpassword", password_confirmation: "testpassword")
     assert_not user2.save, "Second user refuses to save with same callsign"
   end

   test "phone must be in E.164 format" do
     user=User.new(callsign: "zl6test", password: "testpassword", password_confirmation: "testpassword", acctnumber: "+64278263132")
     assert user.save, "First saves OK with E.164"
     user2=User.new(callsign: "zl7test", password: "testpassword", password_confirmation: "testpassword", acctnumber: "0278263132")
     assert_not user2.save, "Cannot save with non-E.164"
   end

#valid_callsign function
   test "valid callsign accepts major callsign formats" do
     user=User.new
     user.callsign="zl4test"
     assert user.valid_callsign?, "accepts ZL4test"
     user.callsign="K1O"
     assert user.valid_callsign?, "accepts K1O"
     user.callsign="3Y1AB"
     assert user.valid_callsign?, "accepts 3Y1AB"
     user.callsign="spamsource"
     assert_not user.valid_callsign?, "rejects all alpha"
     user.callsign="12345"
     assert_not user.valid_callsign?, "rejects all number"
     user.callsign=" zl4test"
     assert_not user.valid_callsign?, "rejects leading space"
     user.callsign="zl4test "
     assert_not user.valid_callsign?, "rejects trailing space"
     user.callsign="zl4test!"
     assert_not user.valid_callsign?, "rejects non-alphanumeric"
   end

#AWARDS


end
