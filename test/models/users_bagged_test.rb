# typed: strict
require "test_helper"

class UserBaggedTest < ActiveSupport::TestCase

#BAGGED
  test "user bags asset with one activation or chase" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    
    codes=user1.bagged
    assert_includes codes, asset1.code,  "Activating user has bagged location 1"
    assert_equal codes.count, 1, "Activating user has only 1 bagged location"
    codes=user2.bagged
    assert_includes codes, asset1.code, "Chasing user has bagged location 1"
    assert_equal codes.count, 1, "Chasing user has only 1 bagged location"
  end

  test "Can request specific asset types" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])

    assert_equal user1.bagged(asset_type: 'hut'), [asset1.code], "Activating user has bagged this hut"
    assert_equal user1.bagged(asset_type: 'park'), [], "Activating user has bagged no parks"
    assert_equal user2.bagged(asset_type: 'hut'), [asset1.code], "Chasing user has bagged this hut"
    assert_equal user2.bagged(asset_type: 'park'), [], "Chasing user has bagged no parks"
  end


  test "Can request multiple asset types" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code])

    assert_equal user1.bagged(asset_type: 'hut, park'), [asset1.code, asset2.code], "Activating user has activated hut and park"
    assert_equal user1.bagged(asset_type: 'island, lighthouse'), [], "Activating user has activated no island or lighthouse"
    assert_equal user2.bagged(asset_type: 'hut, park'), [asset1.code, asset2.code], "Chasing user has bagged hut and park"
    assert_equal user2.bagged(asset_type: 'island, lighthouse'), [], "Chasing user has bagged no island or lighthouse"
  end

  test "minor assets not included unless requested" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', minor: true)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code])
    
    assert_equal user1.bagged, [], "Activating user does not list minor asset"
    assert_equal user2.bagged, [], "Chasing user does not list minor asset"

    assert_equal user1.bagged(include_minor: true), [asset1.code], "Activating user has bagged location 1 when minor is requested"
    assert_equal user2.bagged(include_minor: true), [asset1.code], "Chasing user has bagged location 1 when minor is requested"
  end


  test "QRO contacts not included if QRP requested" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code])
    
    assert_equal user1.bagged(qrp: true), [], "Activating user does not list non-QRP contact (all)"
    assert_equal user2.bagged(qrp: true), [], "Chasing user does not list non-QRP contact (all)"
    assert_equal user1.bagged(qrp: true, asset_type: 'hut'), [], "Activating user does not list non-QRP contact (hut)"
    assert_equal user2.bagged(qrp: true, asset_type: 'hut'), [], "Chasing user does not list non-QRP contact (hut)"

    assert_equal user1.bagged(qrp: false), [asset1.code], "Can pass qrp=false as parameter"

    contact.is_qrp1=true
    contact.is_qrp2=true
    contact.save
    user1.reload

    assert_equal user1.bagged(qrp: true), [asset1.code], "Activating user lists QRP (party1) contact (all)"
    assert_equal user2.bagged(qrp: true), [asset1.code], "Chasing user lists QRP (party1) contact (all)"
    assert_equal user1.bagged(qrp: true, asset_type: 'hut'), [asset1.code], "Activating user lists QRP (party1) contact (hut)"
    assert_equal user2.bagged(qrp: true, asset_type: 'hut'), [asset1.code], "Chasing user lists QRP (party1) contact (hut)"


    contact.is_qrp1=false
    contact.is_qrp2=true
    contact.save

    assert_equal user1.bagged(qrp: true), [], "Activating user does not list QRP (party2) contact (all)"
    assert_equal user2.bagged(qrp: true), [asset1.code], "Chasing user lists QRP (party2) contact (all)"
    assert_equal user1.bagged(qrp: true, asset_type: 'hut'), [], "Activating user does not list QRP (party2) contact (hut)"
    assert_equal user2.bagged(qrp: true, asset_type: 'hut'), [asset1.code], "Chasing user lists QRP (party2) contact (hut)"

    contact.is_qrp1=true
    contact.is_qrp2=false
    contact.save

    assert_equal user1.bagged(qrp: true), [asset1.code], "Activating user does list QRP (party2) contact (all)"
    assert_equal user2.bagged(qrp: true), [], "Chasing user does not list QRP (party2) contact (all)"
    assert_equal user1.bagged(qrp: true, asset_type: 'hut'), [asset1.code], "Activating user does list QRP (party2) contact (hut)"
    assert_equal user2.bagged(qrp: true, asset_type: 'hut'), [], "Chasing user does not list QRP (party2) contact (hut)"
  end

  test "Muliple references in an activation are all picked up in bagged" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code, asset2.code])
    
    assert_equal user1.bagged.sort, [asset1.code,asset2.code].sort, "Activating user has bagged both locations"
    assert_equal user2.bagged.sort, [asset1.code,asset2.code].sort, "Activating user has bagged both locations"
  end

  test "Multiple activations of same reference generate only one entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: 400.days.ago)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: 400.days.ago)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: Time.now())
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: Time.now())
    
    assert_equal user1.bagged, [asset1.code], "Activating user sees multiply-activated location only once"
    assert_equal user2.bagged, [asset1.code], "Chasing user sees multiply-activated location only once"
  end

  test "Multiple copies of reference in an activation generate only one entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code, asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code, asset1.code])
    
    assert_equal user1.bagged.sort, [asset1.code,asset2.code].sort, "Activating user has bagged both locations but repeated locn shown only once"
    assert_equal user2.bagged.sort, [asset1.code,asset2.code].sort, "Chasing user has bagged both locations but repeated locn shown only once"
  end

  test "Chaser-log creates bagged" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[],asset2_codes: [asset1.code])
    
    codes=user1.bagged
    assert_includes codes, asset1.code, "Chasing user has bagged location 1"
    assert_equal codes.count, 1, "Chasing user has only 1 bagged location"
    codes=user2.bagged
    assert_includes codes, asset1.code, "Activating user has bagged location 1"
    assert_equal codes.count, 1, "Activating user has only 1 bagged location"

  end

  test "Activation using secondary callsign picked up in bagged" do
    user1=create_test_user
    user2=create_test_user
    uc=create_callsign(user1) #secondary callsign
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code], date:Time.now, callsign1: uc.callsign)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code], callsign1: uc.callsign)

    assert_equal contact.callsign1, uc.callsign, "Secondary call applied to contact"
    assert_equal user1.bagged, [asset1.code], "Activating user has bagged location 1"
    assert_equal user2.bagged, [asset1.code], "Chasing user has bagged location 1"
  end

  test "Activation using secondary callsign outside time not picked up in bagged" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    #expire user1 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user1.callsign)
    uc1.to_date=11.days.ago
    uc1.save 
 
    #add user1's callsign to user3
    uc=create_callsign(user3, callsign: user1.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
    assert_equal uc.callsign, user1.callsign, "User1 callsign applied to user3 as secondary call"

    asset1=create_test_asset
    log=create_test_log(user3,asset_codes: [asset1.code], date: Time.now, callsign1: uc.callsign)
    contact=create_test_contact(user3,user2,log_id: log.id, asset1_codes: [asset1.code], callsign1: uc.callsign)

    assert_equal contact.callsign1, uc.callsign, "Secondary call applied to contact"
    assert_equal user3.bagged, [asset1.code], "Activating call with correct dates has bagged location 1"
    assert_equal user1.bagged, [], "Another user with same call different dates to activator has not bagged location 1"
  end

  test "Chase using secondary callsign outside time not picked up in bagged" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    #expire user2 callsign 11 days ago
    uc2=UserCallsign.find_by(callsign: user2.callsign)
    uc2.to_date=11.days.ago
    uc2.save 
 
    #add user2's callsign to user3
    uc=create_callsign(user3, callsign: user2.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
    assert_equal uc.callsign, user2.callsign, "User2 callsign applied to user3 as secondary call"

    asset1=create_test_asset
    log=create_test_log(user1, asset_codes: [asset1.code], date: Time.now, callsign1: uc.callsign)
    contact=create_test_contact(user1,user3,log_id: log.id, asset1_codes:[asset1.code], callsign2: uc.callsign)

    assert_equal contact.callsign2, uc.callsign, "Secondary call applied to contact"
    assert_equal user3.bagged, [asset1.code], "Chasing call with correct dates has bagged location 1"
    assert_equal user2.bagged, [], "Another user with same call different dates to activator has not bagged location 1"
  end
end

