require "test_helper"

class UserSotaContactsTest < ActiveSupport::TestCase

  test "Log of SOTA summit returned in sota_contacts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)

    sota_logs=user1.sota_contacts

    assert sota_logs.count==1, "Expect 1 summit to be logged :"+sota_logs.count.to_s
    assert sota_logs[0][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==1, "Expect 1 contacts for this summit: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id], "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Non-sota sites not included" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'park')

    #log with both SOTA and park
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    #log with just park
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)

    sota_logs=user1.sota_contacts

    assert sota_logs.count==1, "Expect 1 summit to be logged :"+sota_logs.count.to_s
    assert sota_logs[0][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==1, "Expect 1 contacts for this summit: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id], "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Multiple logs / contacts returned" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:57:59'.to_time)


    sota_logs=user1.sota_contacts

    assert sota_logs.count==2, "Expect 2 summits to be logged :"+sota_logs.count.to_s
    #don't know which order they'll be listed, so accept either
    if (sota_logs[0][:code]==asset2.code) then 
      firstlog=asset2; secondlog=asset1; 
      firstcount=1; secondcount=2;
      firstids=[contact3.id]; secondids=[contact.id, contact2.id]
    else 
      firstlog=asset1; secondlog=asset2 
      firstcount=2; secondcount=1;
      firstids=[contact.id, contact2.id]; secondids=[contact3.id]
    end
    assert sota_logs[0][:code]==firstlog.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==firstcount, "Expect #{firstcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==firstids.sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json

    assert sota_logs[1][:code]==secondlog.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[1][:date].strftime('%Y-%m-%d')=="2022-01-01", "Expect date to match log: "+sota_logs[1][:date].to_json
    assert sota_logs[1][:count]==secondcount, "Expect #{secondcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[1][:contacts].map{|c| c.id}.sort==secondids.sort, "Expect contacts to be correct: "+sota_logs[1][:contacts].map{|c| c.id}.sort.to_json
  end

  test "Contacts >24hrs later in new log" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:00:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:01:00'.to_time)
    contact3=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 14.01, time: '2022-01-01 01:00:00'.to_time)

    sota_logs=user1.sota_contacts

    assert sota_logs.count==2, "Expect 2 summit activations to be logged :"+sota_logs.count.to_s
    #don't know which order they'll be listed, so accept either
    if (sota_logs[0][:count]==1) then 
      firstcount=1; secondcount=2;
      firstdate="2022-01-02"; seconddate="2022-01-01"
      firstids=[contact2.id]; secondids=[contact.id, contact3.id]
    else 
      firstcount=2; secondcount=1;
      firstdate="2022-01-01"; seconddate="2022-01-02"
      firstids=[contact.id, contact3.id]; secondids=[contact2.id]
    end

    assert sota_logs[0][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[0][:date].strftime('%Y-%m-%d')==firstdate, "Expect date to match log: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==firstcount, "Expect #{firstcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==firstids.sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json

    assert sota_logs[1][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[1][:date].strftime('%Y-%m-%d')==seconddate, "Expect date to match log: "+sota_logs[1][:date].to_json
    assert sota_logs[1][:count]==secondcount, "Expect #{secondcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[1][:contacts].map{|c| c.id}.sort==secondids.sort, "Expect contacts to be correct: "+sota_logs[1][:contacts].map{|c| c.id}.sort.to_json
  end


  test "Contacts <24hrs later in same log even if new UTC day" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 14.01, time: '2022-01-01 01:00:00'.to_time)

    sota_logs=user1.sota_contacts

    assert sota_logs.count==1, "Expect 1 summit activations to be logged :"+sota_logs.count.to_s

    assert sota_logs[0][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[0][:date].strftime('%Y-%m-%d')=='2022-01-01', "Expect date to match log: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==3, "Expect 3 contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==[contact.id, contact2.id, contact3.id].sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json

  end

  test "Contacts <24hrs later in new log if in new UTC year" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2021-12-31 23:59:00'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 00:01:00'.to_time)
    contact3=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 14.01, time: '2021-12-31 23:50:00'.to_time)

    sota_logs=user1.sota_contacts

    assert sota_logs.count==2, "Expect 2 summit activations to be logged :"+sota_logs.count.to_s
    firstcount=2; secondcount=1;
    firstdate="2021-12-31"; seconddate="2022-01-01"
    firstids=[contact.id, contact3.id]; secondids=[contact2.id]

    assert sota_logs[0][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[0][:date].strftime('%Y-%m-%d')==firstdate, "Expect date to match log: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==firstcount, "Expect #{firstcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==firstids.sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json

    assert sota_logs[1][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[1][:date].strftime('%Y-%m-%d')==seconddate, "Expect date to match log: "+sota_logs[1][:date].to_json
    assert sota_logs[1][:count]==secondcount, "Expect #{secondcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[1][:contacts].map{|c| c.id}.sort==secondids.sort, "Expect contacts to be correct: "+sota_logs[1][:contacts].map{|c| c.id}.sort.to_json
  end

  test "can request specific summit" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')

    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-01 23:59:59'.to_time)
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code], mode: 'SSB', frequency: 7.01, time: '2022-01-03 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], mode: 'SSB', frequency: 14.01, time: '2022-01-01 23:57:59'.to_time)

    sota_logs=user1.sota_contacts(asset1.code)

    assert sota_logs.count==2, "Expect 2 activations to be logged :"+sota_logs.count.to_s

    #don't know which order they'll be listed, so accept either
    if sota_logs[0][:date].strftime('%Y-%m-%d')=="2022-01-03" then 
      firstcount=1; secondcount=1;
      firstdate="2022-01-03"; seconddate="2022-01-01"
      firstids=[contact2.id]; secondids=[contact.id]
    else 
      firstcount=1; secondcount=1;
      firstdate="2022-01-01"; seconddate="2022-01-03"
      firstids=[contact.id]; secondids=[contact2.id]
    end

    assert sota_logs[0][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[0][:date].strftime('%Y-%m-%d')==firstdate, "Expect date to match log: "+sota_logs[0][:date].to_json
    assert sota_logs[0][:count]==firstcount, "Expect #{firstcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[0][:contacts].map{|c| c.id}.sort==firstids.sort, "Expect contacts to be correct: "+sota_logs[0][:contacts].map{|c| c.id}.sort.to_json

    assert sota_logs[1][:code]==asset1.code, "Expect summit to be correct: "+sota_logs[0][:code].to_json
    assert sota_logs[1][:date].strftime('%Y-%m-%d')==seconddate, "Expect date to match log: "+sota_logs[1][:date].to_json
    assert sota_logs[1][:count]==secondcount, "Expect #{secondcount} contacts for this park: "+sota_logs[0][:count].to_s
    assert sota_logs[1][:contacts].map{|c| c.id}.sort==secondids.sort, "Expect contacts to be correct: "+sota_logs[1][:contacts].map{|c| c.id}.sort.to_json
  end
end
