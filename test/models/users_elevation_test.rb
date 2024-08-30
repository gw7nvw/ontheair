require "test_helper"

class UserElevationTest < ActiveSupport::TestCase

  test "activating log triggers elevation for both parties" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 100, asset_type: 'summit', code_prefix: 'ZL3/OT-')
    assert asset1.altitude==100, "Test summit has altitude=100m"
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    
    assert user1.elevation_chased==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased.to_s
    assert user2.elevation_chased==100, "Chasing user has earned location 1 chaser elevation: "+user2.elevation_chased.to_s
    assert user1.elevation_activated==100, "Activating user has earned activator elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_activated==0, "Chasing user has not earned location 1 activator  elevation: "+user1.elevation_activated.to_s
    assert user1.elevation_bagged==100, "Activating user has not earned bagged elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_bagged==100, "Chasing user has earned location 1 bagged elevation: "+user1.elevation_activated.to_s
  end

  test "chaser log triggers elevation for both parties" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 101, asset_type: 'summit', code_prefix: 'ZL3/OT-')
    assert asset1.altitude==101, "Test summit has altitude=101m"
    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code])

    assert user2.elevation_chased==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased.to_s
    assert user1.elevation_chased==101, "Chasing user has earned location 1 chaser elevation: "+user2.elevation_chased.to_s
    assert user2.elevation_activated==101, "Activating user has not earned chaser elevation: "+user1.elevation_activated.to_s
    assert user1.elevation_activated==0, "Chasing user has earned location 1 chaser elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_bagged==101, "Activating user has earned bagged elevation: "+user1.elevation_activated.to_s
    assert user1.elevation_bagged==101, "Chasing user has earned location 1 bagged elevation: "+user1.elevation_activated.to_s
    
  end

  test "single elevation listed if both patries log the contact" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 102, asset_type: 'summit', code_prefix: 'ZL3/OT-')
    log1=create_test_log(user1, asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code])
    log2=create_test_log(user2)
    contact2=create_test_contact(user2,user1,log_id: log2.id, asset2_codes: [asset1.code])
    
    assert user1.elevation_chased==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased.to_s
    assert user2.elevation_chased==102, "Chasing user has earned location 1 chaser elevation: "+user2.elevation_chased.to_s
    assert user1.elevation_activated==102, "Activating user has earned activator elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_activated==0, "Chasing user has not earned location 1 activator  elevation: "+user1.elevation_activated.to_s
    assert user1.elevation_bagged==102, "Activating user has not earned bagged elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_bagged==102, "Chasing user has earned location 1 bagged elevation: "+user1.elevation_activated.to_s
  end


  test "Muliple references in an activation are all picked up in activations" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 103, asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(altitude: 104, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code, asset2.code])
    
    assert user1.elevation_chased==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased.to_s
    assert user2.elevation_chased==207, "Chasing user has earned both location chaser elevation: "+user2.elevation_chased.to_s
    assert user1.elevation_activated==207, "Activating user has earned bith location activator elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_activated==0, "Chasing user has not earned both location activator elevation: "+user1.elevation_activated.to_s
    assert user1.elevation_bagged==207, "Activating user has earned bith location bagged elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_bagged==207, "Chasing user has earned both location bagged elevation: "+user1.elevation_activated.to_s
  end

  test "Multiple contacts with same reference generate only one all-time entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 104, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log1=create_test_log(user1,asset_codes: [asset1.code], date: 400.days.ago)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: 400.days.ago)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: Time.now())
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: Time.now())

    assert user1.elevation_chased==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased.to_s
    assert user2.elevation_chased==104, "Chasing user has earned location 1 chaser elevation: "+user2.elevation_chased.to_s
    assert user1.elevation_activated==104, "Activating user has earned activator elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_activated==0, "Chasing user has not earned location 1 activator  elevation: "+user1.elevation_activated.to_s
    assert user1.elevation_bagged==104, "Activating user has earned bagged elevation: "+user1.elevation_activated.to_s
    assert user2.elevation_bagged==104, "Chasing user has earned location 1 bagged elevation: "+user1.elevation_activated.to_s
  end

  test "Multiple contacts by_year in different UTC year listed twice" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 105, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2019-12-31".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2019-12-31 23:59:59".to_time)
  
    assert user1.elevation_chased(by_year: true)==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased(by_year: true).to_s
    assert user2.elevation_chased(by_year: true)==210, "Chasing user has earned location 1 chaser elevation twice: "+user2.elevation_chased(by_year: true).to_s
    assert user1.elevation_activated(by_year: true)==210, "Activating user has earned activator elevation: "+user1.elevation_activated(by_year: true).to_s
    assert user2.elevation_activated(by_year: true)==0, "Chasing user has not earned location 1 activator elevation twice: "+user1.elevation_activated(by_year: true).to_s
  end
  
  test "Multiple contacts by_year in same UTC year listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 106, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-12-31".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-12-31 23:59:59".to_time)
  
    assert user1.elevation_chased(by_year: true)==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased(by_year: true).to_s
    assert user2.elevation_chased(by_year: true)==106, "Chasing user has earned location 1 chaser elevation once: "+user2.elevation_chased(by_year: true).to_s
    assert user1.elevation_activated(by_year: true)==106, "Activating user has earned activator elevation: "+user1.elevation_activated(by_year: true).to_s
    assert user2.elevation_activated(by_year: true)==0, "Chasing user has not earned location 1 activator elevation once: "+user1.elevation_activated(by_year: true).to_s
  end
  
  test "Multiple contacts by_day in different UTC day listed twice" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 108, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-02".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-01-02 23:59:59".to_time)
  
    assert user1.elevation_chased(by_day: true)==0, "Activating user has not earned chaser elevation: "+user1.elevation_chased(by_day: true).to_s
    assert user2.elevation_chased(by_day: true)==216, "Chasing user has earned location 1 chaser elevation twice: "+user2.elevation_chased(by_day: true).to_s
    assert user1.elevation_activated(by_day: true)==216, "Activating user has earned activator elevation: "+user1.elevation_activated(by_day: true).to_s
    assert user2.elevation_activated(by_day: true)==0, "Chasing user has not earned location 1 activator elevation twice: "+user1.elevation_activated(by_day: true).to_s
  end
  
  test "Multiple contacts by_day in same UTC day listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(altitude: 107, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log1=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: "2020-01-01 00:00:00".to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: "2020-01-01".to_time)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: "2020-01-01 23:59:59".to_time)
  
    assert user1.elevation_chased(by_day: true)==0, "Activating user has not earned chaser elevation: "
    assert user2.elevation_chased(by_day: true)==107, "Chasing user has earned location 1 chaser elevation once: "
    assert user1.elevation_activated(by_day: true)==107, "Activating user has earned activator elevation: "
    assert user2.elevation_activated(by_day: true)==0, "Chasing user has not earned location 1 activator elevation once: "
  end
  

  test "Chase using secondary callsign picked up in chased" do
    user1=create_test_user
    user2=create_test_user
    uc=create_callsign(user2) #secondary callsign
    asset1=create_test_asset(altitude: 109, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log=create_test_log(user1,asset_codes: [asset1.code], date:Time.now)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code], callsign2: uc.callsign)

    assert contact.callsign2==uc.callsign, "Secondary call applied to contact"
    assert user2.elevation_chased==109, "Chasing user has earned location 1 chaser elevation: "
    assert user2.elevation_bagged==109, "Chasing user has earned location 1 bagged elevation: "
  end

  test "Activation using secondary callsign picked up in activated" do
    user1=create_test_user
    user2=create_test_user
    uc=create_callsign(user1) #secondary callsign
    asset1=create_test_asset(altitude: 110, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log=create_test_log(user1,asset_codes: [asset1.code], date:Time.now, callsign1: uc.callsign)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes:[asset1.code], callsign1: uc.callsign)

    assert contact.callsign1==uc.callsign, "Secondary call applied to contact"
    assert user1.elevation_activated==110, "Activating user has earned location 1 activator elevation: "
    assert user1.elevation_bagged==110, "Activating user has earned location 1 bagged elevation: "
  end

  test "Chase using secondary callsign outside time not picked up in chased" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    #expire user1 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user2.callsign)
    uc1.to_date=11.days.ago
    uc1.save 
 
    #add user1's callsign to user3
    uc=create_callsign(user3, callsign: user2.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
    assert uc.callsign==user2.callsign, "User1 callsign applied to user3 as secondary call"

    asset1=create_test_asset(altitude: 111, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log=create_test_log(user3,asset_codes: [asset1.code], date: 2.days.ago)
    contact=create_test_contact(user3,user2,log_id: log.id, asset1_codes: [asset1.code], callsign2: uc.callsign, time: 2.days.ago)

    assert contact.callsign2==uc.callsign, "Secondary call applied to contact"
    assert user3.elevation_chased==111, "Chasing user has earned location 1 activator elevation: "
    assert user3.elevation_bagged==111, "Chasing user has earned location 1 bagged elevation: "
    assert user2.elevation_chased==0, "User with same call at different time has not earned elevation chased"
    assert user2.elevation_bagged==0, "User with same call at different time has not earned elevation bagged"
  end

  test "Activation using secondary callsign outside time not picked up in activated" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    #expire user1 callsign 11 days ago
    uc1=UserCallsign.find_by(callsign: user2.callsign)
    uc1.to_date=11.days.ago
    uc1.save 
 
    #add user1's callsign to user3
    uc=create_callsign(user3, callsign: user2.callsign, from_date: 10.days.ago, to_date: 1.days.ago) #secondary callsign
    assert uc.callsign==user2.callsign, "User1 callsign applied to user3 as secondary call"

    asset1=create_test_asset(altitude: 112, asset_type: 'hump', code_prefix: 'ZL3/HOT-')
    log=create_test_log(user3,asset_codes: [asset1.code], date: 2.days.ago)
    contact=create_test_contact(user3,user2,log_id: log.id, asset1_codes: [asset1.code], callsign2: uc.callsign, time: 2.days.ago)

    assert contact.callsign2==uc.callsign, "Secondary call applied to contact"
    assert user3.elevation_activated==112, "Axctivating user has earned location 1 activator elevation: "
    assert user3.elevation_bagged==112, "Axctivating user has earned location 1 bagged elevation: "
    assert user1.elevation_activated==0, "User with same call at different time has not earned elevation activated"
    assert user1.elevation_bagged==0, "User with same call at different time has not earned elevation bagged"
  end
end

