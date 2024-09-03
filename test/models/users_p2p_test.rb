require "test_helper"

class UserP2pTest < ActiveSupport::TestCase

  test "P2P listed for both parties" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts[0]=="2022-01-01 "+asset1.code+" "+asset2.code, "Correct parks in correct 
order"

    contacts=user2.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts[0]=="2022-01-01 "+asset2.code+" "+asset1.code, "Correct parks in correct order"
  end

  test "Multiple P2Ps from different assets" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code])
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset3.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==2, "Expect 2 p2p contact"
    assert contacts.sort==["2022-01-01 "+asset1.code+" "+asset2.code, 
                           "2022-01-01 "+asset1.code+" "+asset3.code
                          ].sort, "Correct parks in correct order"

    contacts=user2.get_p2p_all
    assert contacts.count==2, "Expect 2 p2p contact"
    assert contacts.sort==["2022-01-01 "+asset2.code+" "+asset1.code, 
                           "2022-01-01 "+asset3.code+" "+asset1.code
                          ].sort, "Correct parks in correct order"
  end

  test "Multiple P2Ps from different days" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-02 00:00:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==2, "Expect 2 p2p contact"
    assert contacts.sort==["2022-01-01 "+asset1.code+" "+asset2.code, 
                           "2022-01-02 "+asset1.code+" "+asset2.code
                          ].sort, "Correct parks in correct order"

    contacts=user2.get_p2p_all
    assert contacts.count==2, "Expect 2 p2p contact"
    assert contacts.sort==["2022-01-01 "+asset2.code+" "+asset1.code, 
                           "2022-01-02 "+asset2.code+" "+asset1.code
                          ].sort, "Correct parks in correct order"
  end

  test "Duplicates not shown" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: [asset2.code], time: '2022-01-01 00:01:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts==["2022-01-01 "+asset1.code+" "+asset2.code],"Correct parks in correct order"

    contacts=user2.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts==["2022-01-01 "+asset2.code+" "+asset1.code],"Correct parks in correct order"
  end

  test "Multiple P2Ps from multiple assets in single activation" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset
    asset4=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code, asset2.code], date: '2022-01-01'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code, asset2.code], asset2_codes: [asset3.code, asset4.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==4, "Expect 4 p2p contact"
    assert contacts.sort==["2022-01-01 "+asset1.code+" "+asset3.code, 
                           "2022-01-01 "+asset1.code+" "+asset4.code,
                           "2022-01-01 "+asset2.code+" "+asset3.code, 
                           "2022-01-01 "+asset2.code+" "+asset4.code
                          ].sort, "Correct parks in correct order"

    contacts=user2.get_p2p_all
    assert contacts.count==4, "Expect 4 p2p contact"
    assert contacts.sort==["2022-01-01 "+asset3.code+" "+asset1.code, 
                           "2022-01-01 "+asset3.code+" "+asset2.code,
                           "2022-01-01 "+asset4.code+" "+asset1.code, 
                           "2022-01-01 "+asset4.code+" "+asset2.code
                          ].sort, "Correct parks in correct order"
  end

  test "Supports chasing party at overseas park" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_vkasset(award: 'HEMA', code: 'VK3/HSE-002', location: create_point(148.79, -35.61))
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], asset2_codes: ['VK3/HSE-002'], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts[0]=="2022-01-01 "+asset1.code+" VK3/HSE-002", "Correct parks in correct order"+contacts[0]

    contacts=user2.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts[0]=="2022-01-01 VK3/HSE-002 "+asset1.code, "Correct parks in correct order"
  end

  test "Supports sctivating party at overseas park" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: ['GM/SW-002'])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: ['GM/SW-002'], asset2_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts[0]=="2022-01-01 GM/SW-002 "+asset1.code, "Correct parks in correct order"

    contacts=user2.get_p2p_all
    assert contacts.count==1, "Expect 1 p2p contact"
    assert contacts[0]=="2022-01-01 "+asset1.code+" GM/SW-002", "Correct parks in correct order"+contacts[0]
  end

  test "But both parties cnnot be at non-ZLOTA" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset3=create_test_vkasset(award: 'SOTA', code: 'VK3/CB-001', location: create_point(148.79, -35.61))

    log=create_test_log(user1,asset_codes: ['GM/SW-002'])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: ['GM/SW-002'], asset2_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    log=create_test_log(user1,asset_codes: [asset2.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset2.code], asset2_codes: ['VK3/CB-001'], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.get_p2p_all
    assert contacts.count==0, "Expect no p2p contact"

    contacts=user2.get_p2p_all
    assert contacts.count==0, "Expect no p2p contact"
  end
end
