require "test_helper"

class UserWithAssetsTest < ActiveSupport::TestCase

  test "user listed if they have chased/activated this asset type" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    user1.update_score
    user2.update_score
    user3.update_score
 
    users=User.users_with_assets('hut','chased_count',10)
    assert users.count==1, "Expect 1 user listed as chaser"
    assert users.first==user2, "Expect correct user chasing"

    users=User.users_with_assets('hut','activated_count',10)
    assert users.count==1, "Expect 1 user listed as activator"
    assert users.first==user1, "Expect correct user activating"

    users=User.users_with_assets('hut','score',10)
    assert users.count==2, "Expect 2 user listed as bagged"
    assert users.sort==[user1, user2].sort, "Expect correct users bagged"
  end

  test "user listed only for selected asset type" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    user1.update_score
    user2.update_score
    user3.update_score
 
    users=User.users_with_assets('hut','score',10)
    assert users.count==2, "Expect 2 user listed as hut bagger"
    assert users.sort==[user1, user2].sort, "Expect correct user bagging"

    users=User.users_with_assets('park','score',10)
    assert users.count==0, "Expect 0 user listed as park bagger"
  end

  test "can isort and limit list" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'hut')
    asset3=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1)
    contact=create_test_contact(user3,user1,log_id: log.id, asset2_codes: [asset1.code])
    contact2=create_test_contact(user3,user2,log_id: log.id, asset2_codes: [asset2.code])
    contact3=create_test_contact(user3,user1,log_id: log.id, asset2_codes: [asset3.code])
    user1.update_score
    user2.update_score
    user3.update_score
 
    users=User.users_with_assets('hut','score',1)
    assert users.count==1, "Expect 1 user listed as #1 hut bagger"
    assert users==[user3], "Expect correct user to top the list"+users.to_json

    users=User.users_with_assets('hut','score',3)
    assert users.count==3, "Expect 3 user listed as hut bagger"
    assert users==[user3, user1, user2], "Expect correct user to top the list"+users.to_json
  end
end
