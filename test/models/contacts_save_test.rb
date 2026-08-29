# typed: strict
require "test_helper"

class ContactSaveTest < ActiveSupport::TestCase

  test "save contact adds user_ids" do
    user1=create_test_user
    user2=create_test_user
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id)
    assert_equal contact.user1_id, user1.id, "User 1 ID assigned" 
    assert_equal contact.user2_id, user2.id, "User 2 ID assigned" 
  end

  test "save contact handles secondary callsign" do
    user1=create_test_user
    user2=create_test_user
    uc=create_callsign(user1)

    #activator call
    log=create_test_log(user1, callsign1: uc.callsign)
    contact=create_test_contact(user1, user2, log_id: log.id, callsign1: uc.callsign)
    assert_equal contact.callsign1, uc.callsign, "Contact created correctly"
    assert_equal contact.user1_id, user1.id, "User 1 ID assigned" 
    assert_equal contact.user2_id, user2.id, "User 2 ID assigned" 

    #chaser call
    log2=create_test_log(user2)
    contact2=create_test_contact(user2, user1, log_id: log2.id, callsign2: uc.callsign)
    assert_equal contact2.callsign2, uc.callsign, "Contact created correctly"
    assert_equal contact2.user1_id, user2.id, "User 2 ID assigned" 
    assert_equal contact2.user2_id, user1.id, "User 1 ID assigned" 
  end

  test "save contact handles suffixes and prefixes" do
    user1=create_test_user
    user2=create_test_user

    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, callsign2: "VK/"+user2.callsign+"/P")
    assert_equal contact.callsign2, user2.callsign, "Contact created correctly"
    assert_equal contact.user1_id, user1.id, "User 1 ID assigned"
    assert_equal contact.user2_id, user2.id, "User 2 ID assigned"
  end

  test "band added based on frequency specified" do
    user1=create_test_user
    user2=create_test_user

    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, frequency: 18.136)
    assert_equal contact.band, "17m", "Correct band assigned"
    contact2=create_test_contact(user1, user2, log_id: log.id, frequency: 50.123)
    assert_equal contact2.band, "6m", "Correct band assigned"
    #out of band freq gives blank band
    contact3=create_test_contact(user1, user2, log_id: log.id, frequency: 16.01)
    assert_equal contact3.band, "", "Handles bad frequency without issues"
  end

  test "asset1 codes inherited from log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code])
    contact=create_test_contact(user1, user2, log_id: log.id)
    assert_equal contact.asset1_codes.sort, [asset1.code, asset2.code].sort, "Asset 1 codes inherited from log"
  end

  test "asset2 codes can be read from loc_desc2 if not already present" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1)
     #single code
    contact=create_test_contact(user1, user2, log_id: log.id, loc_desc2:asset1.code)
    assert_equal contact.asset2_codes.sort, [asset1.code].sort, "Asset 2 code read from loc_desc2"
    #multiple codes
    contact2=create_test_contact(user1, user2, log_id: log.id, loc_desc2:asset1.code+","+asset2.code)
    assert_equal contact2.asset2_codes.sort, [asset1.code,asset2.code].sort, "Multiple asset 2 codes read from loc_desc2"

    #not a code
    contact3=create_test_contact(user1, user2, log_id: log.id, loc_desc2: "Hello world")
    assert_equal contact3.asset2_codes.sort, [].sort, "Can ignore text descriptions in loc_desc2"

    #a code from another award programme
    contact4=create_test_contact(user1, user2, log_id: log.id, loc_desc2: "KFF-0001")
    assert_equal contact4.asset2_codes.sort, ["KFF-0001"].sort, "Code from another award programme accepted"

    #code ignore if an asset code already specified
    contact5=create_test_contact(user1, user2, log_id: log.id, loc_desc2: asset2.code, asset2_codes: [asset1.code])
    assert_equal contact5.asset2_codes.sort, [asset1.code].sort, "Ignore code in description if one provided in asset2_codes"
  end

  test "Cannot activate and chase same location" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1, asset_codes: [asset1.code])

    #single code in desc
    contact=create_test_contact(user1, user2, log_id: log.id, loc_desc2: asset1.code)
    assert_equal contact.asset2_codes, [], "Asset 2 code ignored when is duplicate of asset1_code"
    assert_equal contact.loc_desc2, 'INVALID', "Lod_desc overwritten when it contains invalid code"

    #single code in codes
    contact2=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert_equal contact2.asset2_codes, [], "Asset 2 code ignored when is duplicate of asset1_code"
    assert_equal contact2.loc_desc2, 'INVALID', "Lod_desc overwritten when it contains invalid code"

    #multiple code in codes partial match
    contact3=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code])
    assert_equal contact3.asset2_codes, [asset1.code, asset2.code], "not deleted when only some codes match"

    #multiple code in codes full match
    log2=create_test_log(user1, asset_codes: [asset1.code, asset2.code])
    contact4=create_test_contact(user1, user2, log_id: log2.id, asset1_codes: [asset1.code, asset2.code], asset2_codes: [asset1.code, asset2.code])
    assert_equal contact4.asset2_codes, [], "Delete if all codes match"
  end
end
