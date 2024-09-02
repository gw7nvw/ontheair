require "test_helper"

class ContactChildrenTest < ActiveSupport::TestCase

  test "Picks up location from point asset" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.location2==asset1.location, "Location taken from point asset"
    assert contact.loc_source2=='point', "Location type is point"
  end

  test "Picks up location from area asset" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.location2==asset1.location, "Location taken from area asset"
    assert contact.loc_source2=='area', "Location type is area"
  end
end
