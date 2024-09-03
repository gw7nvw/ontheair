require "test_helper"

class LogSaveTest < ActiveSupport::TestCase

  test "save log adds user_ids" do
    user1=create_test_user
    log=create_test_log(user1)
    assert log.user1_id==user1.id, "User 1 ID assigned" 
  end

  test "save log handles secondary callsign" do
    user1=create_test_user
    uc=create_callsign(user1)

    log=create_test_log(user1, callsign1: uc.callsign)
    assert log.callsign1==uc.callsign, "Contact created correctly"
    assert log.user1_id==user1.id, "User 1 ID assigned" 
  end

  test "save log handles suffixes and prefixes" do
    user1=create_test_user

    log=create_test_log(user1, callsign1: "VK/"+user1.callsign+"/P")
    assert log.callsign1==user1.callsign, "Log has root callsign only"
    assert log.user1_id==user1.id, "User 1 ID assigned"
  end

  test "asset codes can be read from loc_desc if not already present" do
    user1=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

     #single code
    log=create_test_log(user1, loc_desc1: asset1.code)
    assert log.asset_codes.sort==[asset1.code].sort, "Asset code read from loc_desc"

    #multiple codes
    log=create_test_log(user1, loc_desc1: asset1.code+", "+asset2.code)
    assert log.asset_codes.sort==[asset1.code, asset2.code].sort, "Asset codes both read from loc_desc"

    #not a code
    log=create_test_log(user1, loc_desc1: "Birmingham, AL")
    assert log.asset_codes.sort==[], "Ignore descriptive text in location"

    #a code from another award programme
    log=create_test_log(user1, loc_desc1: "KFF-0001")
    assert log.asset_codes.sort==["KFF-0001"].sort, "Code from another award programme accepted"

    #code ignore if an asset code already specified
    log=create_test_log(user1, loc_desc1: asset2.code, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code].sort, "Loc desc ignored if code already specified"
  end

  test "contacts updated when log updated" do
    user1=create_test_user
    uc=create_callsign(user1)
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1, user2, log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 03:01'.to_time)

    #update log:
    log.date='2022-01-02'.to_date
    log.callsign1=uc.callsign
    log.asset_codes=[asset2.code]
    log.save
    contact.reload

    #changes propogated to contacts
    assert contact.asset1_codes==[asset2.code], "Asset codes updated"
    assert contact.callsign1==uc.callsign, "Callsign1 updated"
    assert contact.date=='2022-01-02'.to_date
    assert contact.time=='2022-01-02 03:01'.to_time
  end
end
