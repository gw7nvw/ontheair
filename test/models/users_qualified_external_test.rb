require "test_helper"

class UserQualifiedExternalTest < ActiveSupport::TestCase

  test "user requires 4 external contacts to qualify park" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 3)
    assert user1.qualified(asset_type: 'park', include_external: true)==[], "Location not qualified with 3 contacts: "+user1.qualified(asset_type: 'park', include_external: true).to_json
    activation2=create_test_external_activation(user1,asset1,qso_count: 4)
    assert user1.qualified(asset_type: 'park', include_external: true)==[asset1.code], "Location qualified with 4 contacts: "+user1.qualified(asset_type: 'park', include_external: true).to_json
  end

  test "Multiple qualifications of same reference generate only one all-time activation entry" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 4, date: '2022-01-01'.to_date)
    activation2=create_test_external_activation(user1,asset1,qso_count: 4, date: '2022-01-02'.to_date)
    assert user1.qualified(asset_type: 'park', include_external: true)==[asset1.code], "Location listed only once after 2nd activation: "+user1.qualified(asset_type: 'park', include_external: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_year: true)==[asset1.code], "Location listed only once by_year after 2nd activation: "+user1.qualified(asset_type: 'park', include_external: true, by_year: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_day: true)==[asset1.code, asset1.code], "Location listed twice by_day after 2nd activation: "+user1.qualified(asset_type: 'park', include_external: true, by_day: true).to_json
  end

  test "Multiple qualifications by_year in different UTC year listed twice" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 4, date: '2022-01-01'.to_date)
    activation2=create_test_external_activation(user1,asset1,qso_count: 4, date: '2023-01-02'.to_date)
    assert user1.qualified(asset_type: 'park', include_external: true)==[asset1.code], "Location listed only once after 2nd activation: "+user1.qualified(asset_type: 'park', include_external: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_year: true)==[asset1.code, asset1.code], "Location listed twice by_year after 2nd activation: "+user1.qualified(asset_type: 'park', include_external: true, by_year: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_day: true)==[asset1.code, asset1.code], "Location listed twice by_day after 2nd activation: "+user1.qualified(asset_type: 'park', include_external: true, by_day: true).to_json
  end
  
  test "Qualification using secondary callsign picked up in qualified" do
    user1=create_test_user
    uc=create_callsign(user1) #secondary callsign
    asset1=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 4, callsign: uc.callsign)
    assert activation.callsign==uc.callsign, "Check external actuvation used secondary call"
    assert user1.qualified(asset_type: 'park', include_external: true)==[asset1.code], "Location qualified with 4 contacts: "+user1.qualified(asset_type: 'park', include_external: true).to_json
  end

  test "Activations from both internal and external logs listed" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user

    asset1=create_test_asset(asset_type: 'park')
    asset2=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 4)

    log=create_test_log(user1,asset_codes: [asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset2.code])
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset2.code])
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset2.code])
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset2.code])

    assert user1.qualified(asset_type: 'park', include_external: true).sort==[asset1.code, asset2.code], "Both locations qualified with 4 contacts: "+user1.qualified(asset_type: 'park', include_external: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_year: true).sort==[asset1.code, asset2.code], "Both locations qualified with 4 contacts: "+user1.qualified(asset_type: 'park', include_external: true, by_year: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_day: true).sort==[asset1.code, asset2.code], "Both locations qualified with 4 contacts: "+user1.qualified(asset_type: 'park', include_external: true, by_day: true).to_json
  end

  test "Same activation logged internally and externally generates single entry" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user

    asset1=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 4)

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code])
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code])
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code])

    assert user1.qualified(asset_type: 'park', include_external: true).sort==[asset1.code], "Location listed only once: "+user1.qualified(asset_type: 'park', include_external: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_year: true).sort==[asset1.code], "Location listed only once:: "+user1.qualified(asset_type: 'park', include_external: true, by_year: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_day: true).sort==[asset1.code], "Location listed only once:: "+user1.qualified(asset_type: 'park', include_external: true, by_day: true).to_json
  end

  test "Same activation logged internally and externally generates single entry unless date range differs (day)" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user

    asset1=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 4, date: '2022-01-01'.to_date)

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)

    assert user1.qualified(asset_type: 'park', include_external: true).sort==[asset1.code], "Location listed only once: "+user1.qualified(asset_type: 'park', include_external: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_year: true).sort==[asset1.code], "Location listed only once: "+user1.qualified(asset_type: 'park', include_external: true, by_year: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_day: true).sort==[asset1.code, asset1.code], "Location listed twice for different days: "+user1.qualified(asset_type: 'park', include_external: true, by_day: true).to_json
  end

  test "Same activation logged internally and externally generates single entry unless date range differs (year)"  do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user

    asset1=create_test_asset(asset_type: 'park')
    activation=create_test_external_activation(user1,asset1,qso_count: 4, date: '2022-01-01'.to_date)

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2023-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user4,log_id: log.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)
    contact4=create_test_contact(user1,user5,log_id: log.id, asset1_codes: [asset1.code], time: '2023-01-02 00:00:00'.to_time)

    assert user1.qualified(asset_type: 'park', include_external: true).sort==[asset1.code], "Location listed only once: "+user1.qualified(asset_type: 'park', include_external: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_year: true).sort==[asset1.code, asset1.code], "Location listed only once: "+user1.qualified(asset_type: 'park', include_external: true, by_year: true).to_json
    assert user1.qualified(asset_type: 'park', include_external: true, by_day: true).sort==[asset1.code, asset1.code], "Location listed twice for different days: "+user1.qualified(asset_type: 'park', include_external: true, by_day: true).to_json
  end
end

