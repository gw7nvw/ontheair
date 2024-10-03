# typed: strict
require "test_helper"

class UserSotaChaserContactsTest < ActiveSupport::TestCase

  test "Log of SOTA chaser contacts returned in sota_contacts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)

    sota_logs=user1.sota_chaser_contacts

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert_nil sota_logs[0][:code], "Expect summit to be nil: "+sota_logs[0][:code].to_json
    assert_nil sota_logs[0][:date], "Expect date to be nil: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==1, "Expect 1 chaser contacts: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id], "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Foreign SOTA summits included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_vkasset(award: 'SOTA', code: 'VK1/SE-001', location: create_point(148.79, -35.61))

    log=create_test_log(user1,date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: ['3Y/BV-001'], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset2_codes: ['VK1/SE-001'], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:02:00'.to_time)
    contact3=create_test_contact(user1,user2,log_id: log.id, asset2_codes: ['EA9/CE-001'], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:03:00'.to_time)

    sota_logs=user1.sota_chaser_contacts

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert sota_logs[0][:count]==3, "Expect 3 chaser contacts: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id, contact2.id, contact3.id].sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json+" == "+[contact.id, contact2.id, contact3.id].sort.to_json
  end

  test "Non-sota sites not included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZLFF-0')
    asset2=create_test_asset(asset_type: 'park')

    #log with both SOTA and park
    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code, asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    #log with just park
    log2=create_test_log(user1)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)

    sota_logs=user1.sota_chaser_contacts

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert sota_logs[0][:count]==1, "Expect 1 contacts for this summit: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id], "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  #summit2summit submitted in activator log, so do not include here
  test "Summit-to-summit not included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZLFF-0')
    asset2=create_test_asset(asset_type: 'park')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'ZLFF-0')

    #log from both SOTA and park - S2S
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code], asset2_codes: [asset3.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    #log from just park - park to summit
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code, asset2.code], asset2_codes: [asset3.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:01:00'.to_time)

    sota_logs=user1.sota_chaser_contacts

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert sota_logs[0][:count]==1, "Expect 1 contacts for this summit: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact2.id], "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Contacts returned from multiple submitted logs" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset2_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1)
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:57:59'.to_time)


    sota_logs=user1.sota_chaser_contacts

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert sota_logs[0][:count]==3, "Expect 3 contacts for this log: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id, contact2.id, contact3.id].sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "can request specific summit" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset2_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time)
    log2=create_test_log(user1)
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset2.code], mode: 'SSB', frequency: 14.01, time: '2022-01-01 23:57:59'.to_time)

    sota_logs=user1.sota_chaser_contacts(asset1.code)

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert sota_logs[0][:count]==1, "Expect 1 contacts for this log: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id].sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "submitted contacts not included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-02-01 00:01:00'.to_time, submitted_to_sota: true)

    sota_logs=user1.sota_chaser_contacts

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert sota_logs[0][:count]==1, "Expect 1 chaser contacts: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id], "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "can request submitted contacts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
  
    log=create_test_log(user1,date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-02-01 00:01:00'.to_time, submitted_to_sota: true)

    sota_logs=user1.sota_chaser_contacts(nil, true)

    assert sota_logs.count==1, "Expect 1 log: "+sota_logs.count.to_s
    assert sota_logs[0][:count]==2, "Expect 2 chaser contacts: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id, contact2.id].sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

end
