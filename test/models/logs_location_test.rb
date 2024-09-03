require "test_helper"

class LogLocationTest < ActiveSupport::TestCase

  test "Picks up location from point asset" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.location1==asset1.location, "Location taken from point asset"
    assert log.loc_source=='point', "Location type is point"
  end

  test "Picks up location from area asset" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.location1==asset1.location, "Location taken from area asset"
    assert log.loc_source=='area', "Location type is area"
  end

  test "Point location preferred over polygon" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code, asset3.code])
    assert log.location1==asset2.location, "Location taken from point asset"
    assert log.loc_source=='point', "Location type is point"
  end

  test "Can handle multiple point locations" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'summit', location: create_point(173,-45), code_prefix: 'ZL3/OT-')
    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code])
    assert log.location1==asset2.location, "Location taken from point asset"
    assert log.loc_source=='point', "Location type is point"
  end

  test "Smaller polygon preferred over larger polygon" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.3)
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code, asset3.code])
    assert log.location1==asset2.location, "Location taken from smallest area asset"
    assert log.loc_source=='area', "Location type is area"
  end

  test "Can handle null polygons" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.3)
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code, asset3.code])
    assert log.location1==asset2.location, "Location taken from smalled area asset"
    assert log.loc_source=='area', "Location type is area"
  end

  test "Can handle only null polygons" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01))
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.location1==asset1.location, "Location taken from only asset: "+log.location1.to_s
    assert log.loc_source=='area', "Location type is area"
  end

  test "Ignore AZ in point locations - use point" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.3)
    log=create_test_log(user1, asset_codes: [asset1.code, asset2.code, asset3.code])
    assert log.location1==asset1.location, "Location taken from point despite larger AZ area"
    assert log.loc_source=='point', "Location type is point"
  end

  test "do not overwrite user-supplied location" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    log=create_test_log(user1, asset_codes: [asset1.code], location1: create_point(174,-46), loc_source: 'user')
    assert log.location1.x==174, "User supplied location retained"
    assert log.location1.y==-46, "User supplied location retained"
    assert log.loc_source=='user', "Location type is user"
  end

  test "overwrite existing location by default" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code], location1: create_point(174,-46), loc_source: 'point')
    assert log.location1==asset1.location, "Previous location overwritten when not user"
    assert log.loc_source=='area', "Location type is now area"
  end
end
