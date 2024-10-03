# typed: strict
require "test_helper"

class UserWwffLogsTest < ActiveSupport::TestCase

  test "Log of wwff park returned in wwff_logs" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    wwff_logs=user1.wwff_logs
    assert wwff_logs.count==1, "Expect 1 park to be logged :"+wwff_logs.count.to_s
    assert wwff_logs[0][:park][:wwffpark]==asset1.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:park][:name]==asset1.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:count]==2, "Expect 2 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[0][:contacts].sort==[contact, contact2].sort, "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[0][:dups]==[], "Expect duplicates to be empty: "+wwff_logs[0][:dups].to_json
  end

  test "Non-wwff parks not included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    #log with both WWFF and POTA
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    #log with just POTA
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code, asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)

    wwff_logs=user1.wwff_logs

    assert wwff_logs.count==1, "Expect 1 park to be logged :"+wwff_logs.count.to_s
    assert wwff_logs[0][:park][:wwffpark]==asset1.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:park][:name]==asset1.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:count]==1, "Expect 1 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[0][:contacts]==[contact], "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[0][:dups]==[], "Expect duplicates to be empty: "+wwff_logs[0][:dups].to_json
  end

  test "Duplicate contacts not included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:00:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    wwff_logs=user1.wwff_logs
    assert wwff_logs.count==1, "Expect 1 park to be logged :"+wwff_logs.count.to_s
    assert wwff_logs[0][:park][:wwffpark]==asset1.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:park][:name]==asset1.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:count]==1, "Expect 1 contact for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[0][:contacts]==[contact], "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[0][:dups].count==1, "Expect duplicates to contain 1 contact: "+wwff_logs[0][:dups].count.to_s
    assert wwff_logs[0][:dups]==[contact2], "Expect duplicates to contain 1 contact: "+wwff_logs[0][:dups].to_json
  end

  test "Band, mode, callsign, date all trigger new unique contact" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 14.01, time: '2022-01-02 00:01:00'.to_time)
    contact4=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'CW', frequency: 7.01, time: '2022-01-02 00:01:00'.to_time)
    contact5=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:01:00'.to_time)

    wwff_logs=user1.wwff_logs
    assert wwff_logs.count==1, "Expect 1 park to be logged :"+wwff_logs.count.to_s
    assert wwff_logs[0][:park][:wwffpark]==asset1.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:park][:name]==asset1.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:count]==5, "Expect 5 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[0][:contacts].sort==[contact, contact2, contact3, contact4, contact5].sort, "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[0][:dups].count==0, "Expect duplicates to contain 0 contacts: "+wwff_logs[0][:dups].count.to_s
  end

  test "Multiple logs returned" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')
    asset2=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:57:59'.to_time)
    contact4=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:01:00'.to_time)


    wwff_logs=user1.wwff_logs
    assert wwff_logs.count==2, "Expect 2 parks to be logged :"+wwff_logs.count.to_s
    #don't know which order they'll be listed, so accept either
    if (wwff_logs[0][:park][:wwffpark]==asset2.code) then 
      firstlog=asset2; secondlog=asset1 
      firstcontacts=[contact3,contact4]
      secondcontacts=[contact,contact2]
    else 
      firstlog=asset1; secondlog=asset2 
      firstcontacts=[contact,contact2]
      secondcontacts=[contact3,contact4]
    end
    assert wwff_logs[0][:park][:wwffpark]==firstlog.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:park][:name]==firstlog.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:count]==2, "Expect 2 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[0][:contacts].sort==firstcontacts.sort, "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[0][:dups].count==0, "Expect duplicates to contain 0 contacts: "+wwff_logs[0][:dups].count.to_s

    assert wwff_logs[1][:park][:wwffpark]==secondlog.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[1][:park][:name]==secondlog.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[1][:count]==2, "Expect 2 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[1][:contacts].sort==secondcontacts.sort, "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[1][:dups].count==0, "Expect duplicates to contain 0 contacts: "+wwff_logs[0][:dups].count.to_s
  end

  test "Submitted logs not shown" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')
    asset2=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')

    #fully submitted log
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time, submitted_to_wwff: true)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time, submitted_to_wwff: true)
    #part submitted log
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:57:59'.to_time, submitted_to_wwff: true)
    contact4=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:01:00'.to_time)

    wwff_logs=user1.wwff_logs

    assert wwff_logs.count==1, "Expect 1 parks to be logged :"+wwff_logs.count.to_s
    assert wwff_logs[0][:park][:wwffpark]==asset2.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:park][:name]==asset2.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:count]==1, "Expect 1 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[0][:contacts].sort==[contact4].sort, "Expect only unsubmitted contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[0][:dups].count==0, "Expect duplicates to contain 0 contacts: "+wwff_logs[0][:dups].count.to_s
  end

  test "Submitted logs shown if resubmit requested" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')
    asset2=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time, submitted_to_wwff: true)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time, submitted_to_wwff: true)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:57:59'.to_time, submitted_to_wwff: true)
    contact4=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:01:00'.to_time)


    wwff_logs=user1.wwff_logs(true)
    assert wwff_logs.count==2, "Expect 2 parks to be logged :"+wwff_logs.count.to_s
    #don't know which order they'll be listed, so accept either
    if (wwff_logs[0][:park][:wwffpark]==asset2.code) then 
      firstlog=asset2; secondlog=asset1 
      firstcontacts=[contact3,contact4]
      secondcontacts=[contact,contact2]
    else 
      firstlog=asset1; secondlog=asset2 
      firstcontacts=[contact,contact2]
      secondcontacts=[contact3,contact4]
    end
    assert wwff_logs[0][:park][:wwffpark]==firstlog.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:park][:name]==firstlog.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[0][:count]==2, "Expect 2 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[0][:contacts].sort==firstcontacts.sort, "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[0][:dups].count==0, "Expect duplicates to contain 0 contacts: "+wwff_logs[0][:dups].count.to_s

    assert wwff_logs[1][:park][:wwffpark]==secondlog.code, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[1][:park][:name]==secondlog.name, "Expect park to be correct: "+wwff_logs[0][:park].to_json
    assert wwff_logs[1][:count]==2, "Expect 2 contacts for this park: "+wwff_logs[0][:count].to_s
    assert wwff_logs[1][:contacts].sort==secondcontacts.sort, "Expect correct contact: "+wwff_logs[0][:contacts].to_json
    assert wwff_logs[1][:dups].count==0, "Expect duplicates to contain 0 contacts: "+wwff_logs[0][:dups].count.to_s
  end
end
