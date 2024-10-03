# typed: strict
require "test_helper"

class UserPotaContactsTest < ActiveSupport::TestCase

  test "Log of POTA pota park returned in pota_contacts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)

    pota_logs=user1.pota_contacts

    assert pota_logs.count==1, "Expect 1 pota park to be logged :"+pota_logs.count.to_s
    assert pota_logs[0][:code]==asset1.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+pota_logs[0][:date].to_json
    assert pota_logs[0][:count]==1, "Expect 1 contacts for this pota park: "+pota_logs[0][:count].to_s
    assert pota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id], "Expect contacts to be correct: "+pota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Non-pota sites not included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'park')

    #log with both POTA and park
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    #log with just park
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)

    pota_logs=user1.pota_contacts

    assert pota_logs.count==1, "Expect 1 pota park to be logged :"+pota_logs.count.to_s
    assert pota_logs[0][:code]==asset1.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+pota_logs[0][:date].to_json
    assert pota_logs[0][:count]==1, "Expect 1 contacts for this pota park: "+pota_logs[0][:count].to_s
    assert pota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id], "Expect contacts to be correct: "+pota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Multiple logs / contacts returned" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:57:59'.to_time)


    pota_logs=user1.pota_contacts

    assert pota_logs.count==2, "Expect 2 pota parks to be logged :"+pota_logs.count.to_s
    #don't know which order they'll be listed, so accept either
    if (pota_logs[0][:code]==asset2.code) then 
      firstlog=asset2; secondlog=asset1; 
      firstcount=1; secondcount=2;
      firstids=[contact3.id]; secondids=[contact.id, contact2.id]
    else 
      firstlog=asset1; secondlog=asset2 
      firstcount=2; secondcount=1;
      firstids=[contact.id, contact2.id]; secondids=[contact3.id]
    end
    assert pota_logs[0][:code]==firstlog.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+pota_logs[0][:date].to_json
    assert pota_logs[0][:count]==firstcount, "Expect #{firstcount} contacts for this park: "+pota_logs[0][:count].to_s
    assert pota_logs[0][:contacts].map{|c| c.id}.sort==firstids.sort, "Expect contacts to be correct: "+pota_logs[0][:contacts].map{|c| c.id}.sort.to_json

    assert pota_logs[1][:code]==secondlog.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[1][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+pota_logs[1][:date].to_json
    assert pota_logs[1][:count]==secondcount, "Expect #{secondcount} contacts for this park: "+pota_logs[0][:count].to_s
    assert pota_logs[1][:contacts].map{|c| c.id}.sort==secondids.sort, "Expect contacts to be correct: "+pota_logs[1][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Contacts on new day in new log" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 14.01, time: '2022-01-01 23:57:59'.to_time)

    pota_logs=user1.pota_contacts

    assert pota_logs.count==2, "Expect 2 pota park activations to be logged :"+pota_logs.count.to_s
    #don't know which order they'll be listed, so accept either
    if (pota_logs[0][:count]==1) then 
      firstcount=1; secondcount=2;
      firstdate="2022-01-02"; seconddate="2022-01-01"
      firstids=[contact2.id]; secondids=[contact.id, contact3.id]
    else 
      firstcount=2; secondcount=1;
      firstdate="2022-01-01"; seconddate="2022-01-02"
      firstids=[contact.id, contact3.id]; secondids=[contact2.id]
    end

    assert pota_logs[0][:code]==asset1.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[0][:date].strftime('%Y-%m-%d')==firstdate, "Expect date to match log: "+pota_logs[0][:date].to_json
    assert pota_logs[0][:count]==firstcount, "Expect #{firstcount} contacts for this park: "+pota_logs[0][:count].to_s
    assert pota_logs[0][:contacts].map{|c| c.id}.sort==firstids.sort, "Expect contacts to be correct: "+pota_logs[0][:contacts].map{|c| c.id}.sort.to_json

    assert pota_logs[1][:code]==asset1.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[1][:date].strftime('%Y-%m-%d')==seconddate, "Expect date to match log: "+pota_logs[1][:date].to_json
    assert pota_logs[1][:count]==secondcount, "Expect #{secondcount} contacts for this park: "+pota_logs[0][:count].to_s
    assert pota_logs[1][:contacts].map{|c| c.id}.sort==secondids.sort, "Expect contacts to be correct: "+pota_logs[1][:contacts].map{|c| c.id}.sort.to_json
  end


  test "can request specific pota park" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 14.01, time: '2022-01-01 23:57:59'.to_time)

    pota_logs=user1.pota_contacts(asset1.code)

    assert pota_logs.count==2, "Expect 2 activations to be logged :"+pota_logs.count.to_s

    #don't know which order they'll be listed, so accept either
    if pota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-02" then 
      firstcount=1; secondcount=1;
      firstdate="2022-01-02"; seconddate="2022-01-01"
      firstids=[contact2.id]; secondids=[contact.id]
    else 
      firstcount=1; secondcount=1;
      firstdate="2022-01-01"; seconddate="2022-01-02"
      firstids=[contact.id]; secondids=[contact2.id]
    end

    assert pota_logs[0][:code]==asset1.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[0][:date].strftime('%Y-%m-%d')==firstdate, "Expect date to match log: "+pota_logs[0][:date].to_json
    assert pota_logs[0][:count]==firstcount, "Expect #{firstcount} contacts for this park: "+pota_logs[0][:count].to_s
    assert pota_logs[0][:contacts].map{|c| c.id}.sort==firstids.sort, "Expect contacts to be correct: "+pota_logs[0][:contacts].map{|c| c.id}.sort.to_json

    assert pota_logs[1][:code]==asset1.code, "Expect pota park to be correct: "+pota_logs[0][:code].to_json
    assert pota_logs[1][:date].strftime('%Y-%m-%d')==seconddate, "Expect date to match log: "+pota_logs[1][:date].to_json
    assert pota_logs[1][:count]==secondcount, "Expect #{secondcount} contacts for this park: "+pota_logs[0][:count].to_s
    assert pota_logs[1][:contacts].map{|c| c.id}.sort==secondids.sort, "Expect contacts to be correct: "+pota_logs[1][:contacts].map{|c| c.id}.sort.to_json
  end
end
