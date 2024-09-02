require "test_helper"

class ContactLocationTest < ActiveSupport::TestCase

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

  test "Point location preferred over polygon" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code, asset3.code])
    assert contact.location2==asset2.location, "Location taken from point asset"
    assert contact.loc_source2=='point', "Location type is point"
  end

  test "Can handle multiple point locations" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'summit', location: create_point(173,-45), code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code])
    assert contact.location2==asset2.location, "Location taken from point asset"
    assert contact.loc_source2=='point', "Location type is point"
  end

  test "Smaller polygon preferred over larger polygon" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.3)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code, asset3.code])
    assert contact.location2==asset2.location, "Location taken from smallest area asset"
    assert contact.loc_source2=='area', "Location type is area"
  end

  test "Can handle null polygons" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.3)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code, asset3.code])
    assert contact.location2==asset2.location, "Location taken from smalled area asset"
    assert contact.loc_source2=='area', "Location type is area"
  end

  test "Can handle only null polygons" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01))
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.location2==asset1.location, "Location taken from only asset: "+contact.location2.to_s
    assert contact.loc_source2=='area', "Location type is area"
  end

  test "Ignore AZ in point locations - use point" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.3)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code, asset3.code])
    assert contact.location2==asset1.location, "Location taken from point despite larger AZ area"
    assert contact.loc_source2=='point', "Location type is point"
  end

  test "do not overwrite user-supplied location" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code], location2: create_point(174,-46), loc_source2: 'user')
    assert contact.location2.x==174, "User supplied location retained"
    assert contact.location2.y==-46, "User supplied location retained"
    assert contact.loc_source2=='user', "Location type is user"
  end

  test "overwrite existing location by default" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code], location2: create_point(174,-46), loc_source2: 'point')
    assert contact.location2==asset1.location, "Previous location overwritten when not user"
    assert contact.loc_source2=='area', "Location type is now area"
  end
end
