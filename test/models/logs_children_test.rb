require "test_helper"

class LogChildrenTest < ActiveSupport::TestCase

  test "For a point, all containing polygons listed" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code, asset2.code].sort, "Containing polygon added"
  end

  test "For a polygon, polygons containing parent listed" do 
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.11)
    asset4=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code, asset2.code, asset3.code].sort, "Containing polygon added"
  end

  test "For a polygon, polygons overlapping by 90%+ listed" do 
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.094) # Specify length. Area=0.94x0.94=88.3%
    asset3=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.095) # Specify length. Area=0.95x0.95=90.2%
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code, asset3.code].sort, "Containing polygon added"
  end

  test "can be called with user-supplied location (point) and no parent asset" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.11) #park containing asset1
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-46), test_radius: 0.11) #park containing user-supplied location
    log=create_test_log(user1, asset_codes: [asset1.code], location1: create_point(174,-46), loc_source: 'user')

    assert log.asset_codes.sort==[asset1.code, asset3.code].sort, "User-supplied locaion used, not polygon location"
  end

  test "can handle parent polygon asset with no boundary" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45)) #parent with no polygon
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code, asset2.code].sort, "Containing polygon added"
  end

  test "can handle point asset with no location" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'hut') #parent with no location
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code].sort, "No contained_by_assets added as we have no location"
  end

  test "can handle polygon asset with no location or boundary" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park') #parent with no polygon or location
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code].sort, "No contained_by_assets added as we have no location"
  end

  test "vk_assets use lookup table to find contained_by_assets" do
    user1=create_test_user
    asset1=create_test_vkasset(award: 'WWFF', code_prefix: 'VKFF-0')
    asset2=create_test_vkasset(award: 'POTA', code_prefix: 'AU-0')
    asset3=create_test_vkasset(award: 'SOTA', code_prefix: 'VK3/SE-', wwff_code: asset1.code, pota_code: asset2.code)
    log=create_test_log(user1, asset_codes: [asset3.code])
    assert log.asset_codes.sort==[asset1.code, asset2.code, asset3.code].sort, "VK Asset returns containing parks"
  end

  test "vk asset with no contained_by_assets handled ok" do
    user1=create_test_user
    asset1=create_test_vkasset(award: 'WWFF', code_prefix: 'VKFF-0')
    log=create_test_log(user1, asset_codes: [asset1.code])
    assert log.asset_codes.sort==[asset1.code], "Handles asset with no contained_by_assets"
  end

  test "master codes applied for inactive asset" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1, is_active: false, master_code: asset1.code)
    log=create_test_log(user1, asset_codes: [asset2.code])
    assert log.asset_codes.sort==[asset1.code].sort, "Inactive park replaced with master replacement"
  end

  test "master codes not applied for active asset" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1, master_code: asset1.code)
    log=create_test_log(user1, asset_codes: [asset2.code])
    assert log.asset_codes.sort==[asset2.code].sort, "Active park not replaced with master replacement"
  end

  test "inactive contained_by_assets not applied" do
    user1=create_test_user
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1, is_active: false)
    log=create_test_log(user1, asset_codes: [asset2.code])
    assert log.asset_codes.sort==[asset2.code].sort, "Inactive chid park not applied even though it contains parent"
  end

  test "do not lookup respected" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    log=create_test_log(user1, asset_codes: [asset1.code], do_not_lookup: true)
    assert log.asset_codes.sort==[asset1.code].sort, "No lookup if do_not_lookup requested"

    log2=create_test_log(user1, asset_codes: [asset1.code], do_not_lookup: false)
    assert log2.asset_codes.sort==[asset1.code, asset2.code].sort, "Lookup executed if requested"
  end 
end
