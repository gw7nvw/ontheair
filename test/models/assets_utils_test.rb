# typed: strict
require "test_helper"

class AssetSaveTest < ActiveSupport::TestCase

  test "return master codes for a retired code" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1, is_active: false, master_code: asset1.code)
    assert_equal [asset1.code], Asset.find_master_codes([asset2.code]), "Master code returned"
  end

  test "return multiple master codes for  retired codes" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1, is_active: false, master_code: asset1.code)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset4=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1, is_active: false, master_code: asset3.code)
    assert_equal [asset1.code, asset3.code].sort, Asset.find_master_codes([asset2.code, asset4.code].sort), "Master code returned"
  end

  test "return codes from text field" do
    location_text="ZL3/OT-001 Place 1, [NZ-0001] Place 2, ZLFF-0001"
    assert_equal ["ZL3/OT-001", "NZ-0001", "ZLFF-0001"].sort, Asset.check_codes_in_text(location_text).sort, "Correct codes returned"
  end

  test "Get most accurate location returns user by choice" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)

    loc=Asset.get_most_accurate_location([asset1.code, asset2.code, asset3.code], 'user', create_point(170,-46))
    assert_equal create_point(170,-46), loc[:location], "Nothing overwrites user location"
    assert_equal 'user', loc[:source], "Nothing overwrites user location"
    assert_nil loc[:asset], "Asset not used"
  end

  test "Get most accurate location returns point over polygon" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)

    loc=Asset.get_most_accurate_location([asset1.code, asset2.code, asset3.code])
    assert_equal create_point(173,-45).to_s, loc[:location].to_s, "Point location preferreed"
    assert_equal 'point', loc[:source], "Point lcoation preferred"
    assert_equal asset2, loc[:asset], "Point asset returned"
  end

  test "Get most accurate location returns smallest polygon" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.012,-45.012), test_radius: 0.2)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.011,-45.011), test_radius: 0.3)
    loc=Asset.get_most_accurate_location([asset1.code, asset2.code, asset3.code])
    assert_equal create_point(173.01,-45.01).to_s, loc[:location].to_s, "Location"
    assert_equal 'area', loc[:source], "Smaller polygon lcoation preferred"
    assert_equal asset2, loc[:asset], "Samller polygon asset returned"
  end

  test "Single asset returned no matter what" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.011,-45.011), test_radius: 0.3)
    loc=Asset.get_most_accurate_location([asset1.code])
    assert_equal create_point(173.011,-45.011).to_s, loc[:location].to_s, "Locatio
n"
    assert_equal 'area', loc[:source], "Area type returned"
    assert_equal asset1, loc[:asset], "Only asset returned"
  end

  test "correct reference format errors" do
    assert_equal 'ZLL/0001', Asset.correct_separators('ZLL-0001'), "Corrected"
    assert_equal 'ZLP/CB-0001', Asset.correct_separators('ZLP-CB/0001'), "Corrected"
    assert_equal 'ZLI/CB-001', Asset.correct_separators('ZLI-CB/001'), "Corrected"
    assert_equal 'ZLB/001', Asset.correct_separators('ZLB-001'), "Corrected"
  end

  test "Maidenhead for location" do
    assert_equal 'RF70aa',  Asset.get_maidenhead_from_location(create_point(174,-40)), "Correct maidenhead"
  end

  test "Get next code" do
    #returns correct default
    assert_equal 'ZLL/0001', Asset.get_next_code('lake')
    assert_equal 'ZLH/CB-001', Asset.get_next_code('hut','CB')
    assert_equal 'ZLI/CB-001', Asset.get_next_code('island','CB')
    assert_equal 'ZLP/CB-0001', Asset.get_next_code('park','CB')
    assert_equal 'ZLB/001', Asset.get_next_code('lighthouse','CB')

    asset1=create_test_asset(asset_type: 'hut', region: 'CB')
    asset2=create_test_asset(asset_type: 'lake')
    asset3=create_test_asset(asset_type: 'island', region: 'CB')
    asset4=create_test_asset(asset_type: 'park', region: 'CB')
    asset5=create_test_asset(asset_type: 'lighthouse')

    #CB region now returns '2' as '1' used
    assert_equal 'ZLL/0002', Asset.get_next_code('lake')
    assert_equal 'ZLH/CB-002', Asset.get_next_code('hut','CB')
    assert_equal 'ZLI/CB-002', Asset.get_next_code('island','CB')
    assert_equal 'ZLP/CB-0002', Asset.get_next_code('park','CB')
    assert_equal 'ZLB/002', Asset.get_next_code('lighthouse','CB')

    #But PT region still gives '1'
    assert_equal 'ZLH/OT-001', Asset.get_next_code('hut','OT')
    assert_equal 'ZLI/OT-001', Asset.get_next_code('island','OT')
    assert_equal 'ZLP/OT-0001', Asset.get_next_code('park','OT')
  end
end
