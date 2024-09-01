require "test_helper"

class UserUsercallsignTest < ActiveSupport::TestCase

  test "can extract callsign from a call with prefix and suffix" do
    #Always extract valid call
    assert User.remove_call_suffix("VK/ZL1C/P")=='ZL1C', 
        "Correct callsign extracted ZL1C"
    assert User.remove_call_suffix("ZL1C/QRP")=='ZL1C', 
        "Correct callsign extracted ZL1C"
    assert User.remove_call_suffix("VK3/ZL1C/P")=='ZL1C', 
        "Correct callsign extracted ZL1C"
    assert User.remove_call_suffix("VK3/N1C/QRP")=='N1C', 
        "Correct callsign extracted N1C"
    assert User.remove_call_suffix("N1C/VK3")=='N1C', 
        "Correct callsign extracted N1C"
    assert User.remove_call_suffix("/N1C")=='N1C', 
        "Correct callsign extracted N1C"
    assert User.remove_call_suffix("N1C/")=='N1C', 
        "Correct callsign extracted N1C"
    #if no valid call, choose longest
    assert User.remove_call_suffix("VK/DAFTCALL/P")=='DAFTCALL', 
        "Correct callsign extracted DAFTCALL"
  
  end

  test "can search for user by callsign / date" do
    user1=create_test_user
    assert User.find_by_callsign_date(user1.callsign, Time.now())==user1,
       "User returned as soon as created"

    assert User.find_by_callsign_date('badcallsign', Time.now())==nil,
       "Non existant user not found nor created"

    newuser=User.find_by_callsign_date('uc1user', Time.now(), true)
    assert newuser.callsign=='UC1USER',   "Non existant user created"
    assert newuser.activated==false, "New user cannot login"
  
    uc=create_callsign(user1, callsign: 'UC2USER', from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign

    assert User.find_by_callsign_date('UC2USER', 2.days.ago)==user1,
       "Can find by secondary call within timeframe"


    assert User.find_by_callsign_date('UC2USER', Time.now())==nil
       "Does not return by secondary call outside timeframe"
  end

  test "Adding secondary call reassigns userids for contacts using call" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: 12.days.ago)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: 12.days.ago)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: 8.days.ago)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: 8.days.ago)
    log3=create_test_log(user1,asset_codes: [asset1.code], date: Time.now())
    contact3=create_test_contact(user1,user2,log_id: log3.id, asset1_codes: [asset1.code], time: Time.now())
  
    #expire user1 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user1.callsign)
    uc1.to_date=11.days.ago
    uc1.save
  
    #add user1's callsign to user3
    uc=create_callsign(user3, callsign: user1.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
 
    User.reassign_userids_used_by_callsign(user1.callsign)
 
    contact1.reload
    assert contact1.user1_id==user1.id, "Contact prior to change not affected"
    contact2.reload
    assert contact2.user1_id==user3.id, "Contact during change assinged to user3"
    contact3.reload
    assert contact3.user1_id==user1.id, "Contact after change period not affected (who would we assign it to?)"

    log1.reload
    assert log1.user1_id==user1.id, "Log prior to change not affected"
    log2.reload
    assert log2.user1_id==user3.id, "Log during change assinged to user3"
    log3.reload
    assert log3.user1_id==user1.id, "Log after change period not affected (who would we assign it to?)"
  end


  test "Adding secondary call reassigns userids for contacts using chaser call" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: 12.days.ago)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: 12.days.ago)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: 8.days.ago)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: 8.days.ago)
    log3=create_test_log(user1,asset_codes: [asset1.code], date: Time.now())
    contact3=create_test_contact(user1,user2,log_id: log3.id, asset1_codes: [asset1.code], time: Time.now())
  
    #expire user2 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user2.callsign)
    uc1.to_date=11.days.ago
    uc1.save
  
    #add user1's callsign to user3
    uc=create_callsign(user3, callsign: user2.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
 
    User.reassign_userids_used_by_callsign(user2.callsign)
 
    contact1.reload
    assert contact1.user2_id==user2.id, "Contact prior to change not affected"
    contact2.reload
    assert contact2.user2_id==user3.id, "Contact during change assinged to user3"
    contact3.reload
    assert contact3.user2_id==user2.id, "Contact after change period not affected (who would we assign it to?)"

    log1.reload
    assert log1.user1_id==user1.id, "Log not affected"
    log2.reload
    assert log2.user1_id==user1.id, "Log not affected"
    log3.reload
    assert log3.user1_id==user1.id, "Log not affected"
  end

  test "Adding secondary call reassigns userids for external activations using call" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
   
    activation1=create_test_external_activation(user1,asset1,date: 12.days.ago)
    chase1=create_test_external_chase(activation1,user2,asset1, time: 12.days.ago)
    activation2=create_test_external_activation(user1,asset1,date: 8.days.ago)
    chase2=create_test_external_chase(activation2,user2,asset1, time: 8.days.ago)
    activation3=create_test_external_activation(user1,asset1,date: Time.now())
    chase3=create_test_external_chase(activation3,user2,asset1, time: Time.now())

    #expire user1 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user1.callsign)
    uc1.to_date=11.days.ago
    uc1.save
  
    #add user1's callsign to user3
    uc=create_callsign(user3, callsign: user1.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
 
    User.reassign_userids_used_by_callsign(user1.callsign)
 
    activation1.reload
    assert activation1.user_id==user1.id, "Activation prior to change not affected"
    activation2.reload
    assert activation2.user_id==user3.id, "Activation during change assinged to user3"
    activation3.reload
    assert activation3.user_id==user1.id, "Activation after change period not affected (who would we assign it to?)"
  end


  test "Adding secondary call reassigns userids for external chase using call" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
   
    activation1=create_test_external_activation(user1,asset1,date: 12.days.ago)
    chase1=create_test_external_chase(activation1,user2,asset1, time: 12.days.ago)
    activation2=create_test_external_activation(user1,asset1,date: 8.days.ago)
    chase2=create_test_external_chase(activation2,user2,asset1, time: 8.days.ago)
    activation3=create_test_external_activation(user1,asset1,date: Time.now())
    chase3=create_test_external_chase(activation3,user2,asset1, time: Time.now())

    #expire user2 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user2.callsign)
    uc1.to_date=11.days.ago
    uc1.save
  
    #add user2's callsign to user3
    uc=create_callsign(user3, callsign: user2.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
 
    User.reassign_userids_used_by_callsign(user2.callsign)
 
    chase1.reload
    assert chase1.user_id==user2.id, "Chase prior to change not affected"
    chase2.reload
    assert chase2.user_id==user3.id, "Chase during change assinged to user3"
    chase3.reload
    assert chase3.user_id==user2.id, "Chase after change period not affected (who would we assign it to?)"
  end
end
