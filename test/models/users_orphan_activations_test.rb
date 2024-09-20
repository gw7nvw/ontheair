require "test_helper"

class UserOrphanActivationTest < ActiveSupport::TestCase

  test "log submitted by chaser but not activator triggers orphan activation" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log=create_test_log(user2)
    contact=create_test_contact(user2,user1,log_id: log.id, asset2_codes: [asset1.code])
    
    contacts=user1.orphan_activations
    assert_equal contacts, [contact], "Activating user has unconfirmed activation of asset1"
    contacts=user2.orphan_activations
    assert_equal contacts, [], "Chasing user has no orphan activations"
  end

  test "log submitted by both patries does not trigger orphan activatoon" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)
    log2=create_test_log(user2, date: '2022-01-01'.to_date)
    contact2=create_test_contact(user2,user1,log_id: log2.id, asset2_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)
    
    contacts=user1.orphan_activations
    assert_equal contacts, [], "No orphan activations when both users submit log"
  end

  test "chaser log submitted in different year trigger orphan activation" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    log1=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1,user2,log_id: log1.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)
    log2=create_test_log(user2, date: '2021-12-31'.to_date)
    contact2=create_test_contact(user2,user1,log_id: log2.id, asset2_codes: [asset1.code], time: '2021-12-31 23:59'.to_time)
    
    contacts=user1.orphan_activations
    assert_equal contacts, [contact2], "Orphan activation as chaser log is in different year"
  end

end
