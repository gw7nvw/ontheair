require "test_helper"

class ContactChildrenTest < ActiveSupport::TestCase

  test "For a point, all containing polygons listed" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.asset2_codes.sort==[asset1.code, asset2.code].sort, "Containing polygon added"
  end

  test "For a polygon, polygons containing parent listed" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.11)
    asset4=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.asset2_codes.sort==[asset1.code, asset2.code, asset3.code].sort, "Containing polygon added"
  end

  test "For a polygon, polygons overlapping by 90%+ listed" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.094) # Specify length. Area=0.94x0.94=88.3%
    asset3=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.095) # Specify length. Area=0.95x0.95=90.2%
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.asset2_codes.sort==[asset1.code, asset3.code].sort, "Containing polygon added"
  end

  test "can be called with user-supplied location (point) and no parent asset" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.11) #park containing asset1
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-46), test_radius: 0.11) #park containing user-supplied location
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code], location2: create_point(174,-46), loc_source2: 'user')

    assert contact.asset2_codes.sort==[asset1.code, asset3.code].sort, "User-supplied locaion used, not polygon location"
  end

  test "can handle parent polygon asset with no boundary" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45)) #parent with no polygon
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.asset2_codes.sort==[asset1.code, asset2.code].sort, "Containing polygon added"
  end

  test "can handle point asset with no location" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut') #parent with no location
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.asset2_codes.sort==[asset1.code].sort, "No children added as we have no location"
  end

  test "can handle polygon asset with no location or boundary" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park') #parent with no polygon or location
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code])
    assert contact.asset2_codes.sort==[asset1.code].sort, "No children added as we have no location"
  end

end
