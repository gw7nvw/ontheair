require "test_helper"

class PostSpotSaveTest < ActiveSupport::TestCase

  test "Known asset codes handled OK" do
    user1=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    item=create_test_spot(user1, asset_codes: [asset1.code, asset2.code])
    spot=item.post

    assert_equal [asset1.code, asset2.code].sort, spot.asset_codes.sort, "Known asset codes added correctly"
    assert_equal nil, spot.description, "Correct description"
  end

  test "Known VK asset codes handled OK" do
    user1=create_test_user
    asset1=create_test_vkasset(award: 'SOTA', code: 'VK3/CB-001', location: create_point(148.79, -35.61))
    asset2=create_test_vkasset(award: 'WWFF', code_prefix: 'VKFF-0')

    item=create_test_spot(user1, asset_codes: [asset1.code, asset2.code])
    spot=item.post

    assert_equal [asset1.code, asset2.code].sort, spot.asset_codes.sort, "Known asset codes added correctly"
    assert_equal nil, spot.description, "Correct description"
  end

  test "Correctly formatted external asset handled OK" do
    user1=create_test_user

    item=create_test_spot(user1, asset_codes: ["GM/SE-001", "GFF-0001"])
    spot=item.post

    assert_equal ["GM/SE-001", "GFF-0001"].sort, spot.asset_codes.sort, "Known asset codes added correctly"
    assert_equal nil, spot.description, "Correct description"
  end

  test "Incorrectly formatted asset handled OK" do
    user1=create_test_user

    item=create_test_spot(user1, asset_codes: ["My local picnic area", "ZLL/001"])
    spot=item.post

    assert_equal [].sort, spot.asset_codes.sort, "Known asset codes added correctly"
    assert spot.description["Unknown location: My local picnic area"], "Correct description"
    assert spot.description["Unknown location: ZLL/001"], "Correct description"
  end

  test "Master codes applied for superceded locations" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1, is_active: false, master_code: asset1.code)

    item=create_test_spot(user1, asset_codes: [asset2.code])
    spot=item.post

    assert_equal [asset1.code].sort, spot.asset_codes.sort, "Master code applied"
    assert_equal nil, spot.description, "Correct description"
  end


  test "Containing ZL assets added" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)

    item=create_test_spot(user1, asset_codes: [asset1.code])
    spot=item.post

    assert_equal [asset1.code, asset2.code].sort, spot.asset_codes.sort, "Containing parks added"
    assert_equal nil, spot.description, "Correct description"
  end

  test "Containing POTA and WWFF assets added when user authorised to do so" do
    user1=create_test_user(logs_pota: true, logs_wwff: true)
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'pota park', location: create_point(173,-45), test_radius: 0.1, code_prefix: "NZ-0")
    asset3=create_test_asset(asset_type: 'wwff park', location: create_point(173,-45), test_radius: 0.1, code_prefix: "ZLFF-0")

    item=create_test_spot(user1, asset_codes: [asset1.code])
    spot=item.post

    assert_equal [asset1.code, asset2.code, asset3.code].sort, spot.asset_codes.sort, "Containing POTA and WWFF park added"
    assert_equal nil, spot.description, "Correct description"
  end
  test "Containing POTA assets added only when user authorised to do so" do
    user1=create_test_user(logs_pota: false, logs_wwff: true)
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'pota park', location: create_point(173,-45), test_radius: 0.1, code_prefix: "NZ-0")
    asset3=create_test_asset(asset_type: 'wwff park', location: create_point(173,-45), test_radius: 0.1, code_prefix: "ZLFF-0")

    item=create_test_spot(user1, asset_codes: [asset1.code])
    spot=item.post

    assert_equal [asset1.code, asset3.code].sort, spot.asset_codes.sort, "Containing POTA not added if user requests not"
    assert_equal nil, spot.description, "Correct description"
  end
  test "Containing WWFF assets added only when user authorised to do so" do
    user1=create_test_user(logs_pota: true, logs_wwff: false)
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'pota park', location: create_point(173,-45), test_radius: 0.1, code_prefix: "NZ-0")
    asset3=create_test_asset(asset_type: 'wwff park', location: create_point(173,-45), test_radius: 0.1, code_prefix: "ZLFF-0")

    item=create_test_spot(user1, asset_codes: [asset1.code])
    spot=item.post

    assert_equal [asset1.code, asset2.code].sort, spot.asset_codes.sort, "Containing WWFF not added if user requests not"
    assert_equal nil, spot.description, "Correct description"
  end

  test "Get loction for spot" do
    user1=create_test_user(logs_pota: true, logs_wwff: false)
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)

    item=create_test_spot(user1, asset_codes: [asset1.code, asset2.code, asset3.code])
    spot=item.post

    location=spot.get_most_accurate_location  
    assert_equal create_point(173,-45).to_s, location.to_s, "Point location preferreed"
  end

  test "Get loction for spot handles vk-asset" do
    user1=create_test_user(logs_pota: true, logs_wwff: false)
    asset1=create_test_vkasset(award: 'SOTA', code: 'VK3/CB-001', location: create_point(148.79, -35.61))

    item=create_test_spot(user1, asset_codes: [asset1.code])
    spot=item.post

    location=spot.get_most_accurate_location  
    assert_equal "", location.to_s, "VK asset returns blank location"
  end

  test "Get loction for spot handles unknown-asset" do
    user1=create_test_user(logs_pota: true, logs_wwff: false)

    item=create_test_spot(user1, asset_codes: ['GFF-0001'])
    spot=item.post

    location=spot.get_most_accurate_location  
    assert_equal "", location.to_s, "unknown asset returns blank location"
  end
end

