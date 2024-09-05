require "test_helper"

class UserQualifiedTest < ActiveSupport::TestCase

  test "user requires 4 contacts to qualify park" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    assert asset1.type.min_qso==4, "Park requires 4 QSOs"
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code])
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code])

    assert user1.qualified(asset_type: 'park', by_day: true)==[], "Location not qualified with 3 contacts: "+user1.qualified(asset_type: 'park', by_day: true).to_json
 
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code])

    assert user1.qualified(asset_type: 'park')==[asset1.code], "Location qualified with 4 contacts: "+user1.qualified(asset_type: 'park').to_json
  end

  test "minor assets not included unless requested" do 
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user
    asset1=create_test_asset(asset_type: 'park', minor: true)
    assert asset1.type.min_qso==4, "Park requires 4 QSOs"
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code])
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code])
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code])
    log.reload
    assert user1.qualified(asset_type: 'park')==[], "Minor assets not listed if not requested: "+user1.qualified(asset_type: 'park').to_json
    assert user1.qualified(asset_type: 'park', include_minor: false)==[], "Minor assets not listed if not requested: "+user1.qualified(asset_type: 'park', include_minor: false).to_json
    assert user1.qualified(asset_type: 'park', include_minor: true)==[asset1.code], "Minor assets listed if requested: "+user1.qualified(asset_type: 'park', include_minor: true).to_json
  end


  test "Muliple references in an activation are all picked up in qualified" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code])
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code, asset2.code])
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code, asset2.code])
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code, asset2.code])
    log.reload
    assert user1.qualified(asset_type: 'park').sort==[asset1.code, asset2.code].sort, "Both locations qualified: "+user1.qualified(asset_type: 'park').to_json
  end

  test "Multiple qualifications of same reference generate only one all-time activation entry" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log2.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user4,log_id: log2.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    contact4=create_test_contact(user1,user5,log_id: log2.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    assert user1.qualified(asset_type: 'park')==[asset1.code], "Location qualified only once for all-time: "+user1.qualified(asset_type: 'park').to_json
    assert user1.qualified(asset_type: 'park', by_year: true)==[asset1.code], "Location qualified only once by_year: "+user1.qualified(asset_type: 'park', by_year: true).to_json
    assert user1.qualified(asset_type: 'park', by_day: true)==[asset1.code, asset1.code], "Location qualified twice by_day: "+user1.qualified(asset_type: 'park', by_day: true).to_json
  end

  test "Multiple qualifications by_year in different UTC year listed twice" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: '2023-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log2.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user4,log_id: log2.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)
    contact4=create_test_contact(user1,user5,log_id: log2.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)
    assert user1.qualified(asset_type: 'park', by_year: true)==[asset1.code, asset1.code], "Location qualified twice by_year: "+user1.qualified(asset_type: 'park', by_day: true).to_json
  end
  
  test "Qualification using secondary callsign picked up in qualified" do
    user1=create_test_user
    uc=create_callsign(user1) #secondary callsign
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code], callsign1: uc.callsign)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], callsign1: uc.callsign)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], callsign1: uc.callsign)
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code], callsign1: uc.callsign)
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code], callsign1: uc.callsign)
    assert user1.qualified(asset_type: 'park')==[asset1.code], "Location qualified using secondary callsign: "+user1.qualified(asset_type: 'park').to_json
  end
end

