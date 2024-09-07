require "test_helper"

class UserActivatedTest < ActiveSupport::TestCase

  test "user activates asset with one activation but not chase" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    
    codes=user1.activations
    assert_equal codes, [asset1.code], "Activating user has activated location 1"
    codes=user2.activations
    assert_equal codes, [], "Chasing user has not activated location 1"
  end

  test "chaser log triggers activation for other party" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code])
    
    codes=user1.activations
    assert_equal codes, [], "Chasing user has not activated location 1"
    codes=user2.activations
    assert_equal codes, [asset1.code], "Activating user has activated location 1"
  end

  test "single activation listed if both patrys log the contact" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1, asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code])
    log2=create_test_log(user2)
    contact2=create_test_contact(user2,user1,log_id: log2.id, asset2_codes: [asset1.code])
    
    codes=user1.activations
    assert_equal codes, [asset1.code], "Activating user has activated location 1 only once"
    codes=user2.activations
    assert_equal codes, [], "Chasing user has not activated location 1"
  end

  test "Can request specific asset types" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])

    assert_equal user1.activations(asset_type: 'hut'), [asset1.code], "Activating user has activated this hut"
    assert_equal user1.activations(asset_type: 'park'), [], "Activating user has activated no parks"
    assert_equal user2.activations(asset_type: 'hut'), [], "Chasing user has not activated this hut"
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

    assert_equal user1.activations(asset_type: 'hut, park').sort, [asset1.code, asset2.code], "Activating user has activated hut and park"
    assert_equal user1.activations(asset_type: 'island, lighthouse'), [], "Activating user has activated no island or lighthouse"
  end

  test "minor assets not included unless requested" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', minor: true)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code])
    
    assert_equal user1.activations, [], "Activating user does not list minor asset"
    assert_equal user2.activations, [], "Chasing user does not list minor asset"

    assert_equal user1.activations(include_minor: true), [asset1.code], 
         "Activating user has activated location 1 when minor is requested"
    assert_equal user2.activations(include_minor: true), [], 
         "Chasing user does not lost this asset even with minor requested"
  end


  test "QRO contacts not included if QRP requested" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code])
    
    assert_equal user1.activations(qrp: true), [], "Activating user does not list non-QRP contact (all)"
    assert_equal user1.activations(qrp: true, asset_type: 'hut'), [], "Activating user does not list non-QRP contact (hut)"

    assert_equal user1.activations(qrp: false), [asset1.code], "Can pass qrp=false as parameter"

    contact.is_qrp1=true
    contact.is_qrp2=true
    contact.save
    user1.reload

    assert_equal user1.activations(qrp: true), [asset1.code], "Activating user lists QRP (party1) contact (all)"
    assert_equal user1.activations(qrp: true, asset_type: 'hut'), [asset1.code], "Activating user lists QRP (party1) contact (hut)"

    contact.is_qrp1=false
    contact.is_qrp2=true
    contact.save

    assert_equal user1.activations(qrp: true), [], "Activating user does not list QRP (party2) contact (all)"
    assert_equal user1.activations(qrp: true, asset_type: 'hut'), [], "Activating user does not list QRP (party2) contact (hut)"

    contact.is_qrp1=true
    contact.is_qrp2=false
    contact.save

    assert_equal user1.activations(qrp: true), [asset1.code], "Activating user does list QRP (party2) contact (all)"
    assert_equal user1.activations(qrp: true, asset_type: 'hut'), [asset1.code], "Activating user does list QRP (party2) contact (hut)"
  end

  test "Muliple references in an activation are all picked up in activations" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code, asset2.code])
    
    assert_equal user1.activations.sort, [asset1.code,asset2.code].sort, "Activating user has activated both locations"
    assert_equal user2.activations, [], "Chasing user not activated both locations"
  end

  test "Multiple activations of same reference generate only one all-time activation entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: 400.days.ago)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: 400.days.ago)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: Time.now())
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: Time.now())
    
    assert_equal user1.activations, [asset1.code], "Activating user sees multiply-activated location only once"
  end

  test "Multiple activations by_year in different UTC year listed twice" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2019-12-31".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2019-12-31 23:59:59".to_time)
   
    assert_equal user1.activations(by_year: true).sort, [asset1.code+" 2019", asset1.code+" 2020"], "Activating user sees multiply-activated location twice for different years"
  end
  
  test "Multiple activations by_year in same UTC year listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-12-31".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-12-31 23:59:59".to_time)
   
    assert_equal user1.activations(by_year: true), [asset1.code+" 2020"], "Activating user sees multiply-activated location once for same year"
  end
  
  test "Multiple activations by_day in different UTC day listed twice" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-02".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-02 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-01-01 23:59:59".to_time)
    assert_equal user1.activations(by_day: true).sort, [asset1.code+" 2020-01-01", asset1.code+" 2020-01-02"], "Activating user sees multiply-activated location twice for different days"
  end
  
  test "Multiple activations by_day in same UTC day listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-01-01 23:59:59".to_time)
   
    assert_equal user1.activations(by_day: true), [asset1.code+" 2020-01-01"], "Activating user sees multiply-activated location once for same day"
  end
  

  test "Multiple copies of reference in an activation generate only one entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code, asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code, asset1.code])
    
    assert_equal user1.activations.sort, [asset1.code,asset2.code], "Activating user has activated both locations but repeated locn shown only once"
  end

  test "Activation using secondary callsign picked up in activations" do
    user1=create_test_user
    user2=create_test_user
    uc=create_callsign(user1) #secondary callsign
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code], date:Time.now, callsign1: uc.callsign)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code], callsign1: uc.callsign)

    assert_equal contact.callsign1, uc.callsign, "Secondary call applied to contact"
    assert_equal user1.activations, [asset1.code], "Activating user has activated location 1"
  end

  test "Activation using secondary callsign outside time not picked up in activated" do
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
    log=create_test_log(user3,asset_codes: [asset1.code], date: 2.days.ago, callsign1: uc.callsign)
    contact=create_test_contact(user3,user2,log_id: log.id, asset1_codes: [asset1.code], callsign1: uc.callsign, time: 2.days.ago)

    assert_equal contact.callsign1, uc.callsign, "Secondary call applied to contact"
    assert_equal user3.activations, [asset1.code], "Activating call with correct dates has activated location 1"
    assert_equal user1.activations, [], "Another user with same call different dates to activator has not activated location 1"
  end

end

