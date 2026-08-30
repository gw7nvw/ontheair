# typed: false
require "test_helper"

class DistrictTest < ActiveSupport::TestCase
  test "can get assets for district" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5), country: 'ZL', code_prefix: 'ZLH/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/OT-', location: create_point(173.5,-41.6), country: 'ZL')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/CB-', location: create_point(171.5,-40.6), country: 'ZL')
    district = District.find_by(district_code: 'CO')
    assets = district.assets
    assert_equal assets.count, 2, "Correct no of assets returned"
    assert_equal assets.first.code, asset1.code
    assert_equal assets.last.code, asset2.code

    district = District.find_by(district_code: 'CC')
    assets = district.assets
    assert_equal assets.count, 1, "Correct no of assets returned"
    assert_equal assets.first.code, asset3.code
  end

  test "can get assets by type for district" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5), country: 'ZL', code_prefix: 'ZLH/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/OT-', location: create_point(173.5,-41.6), country: 'ZL')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/CB-', location: create_point(171.5,-40.6), country: 'ZL')
    district = District.find_by(district_code: 'CO')
    assets = district.assets_by_type('hut')
    assert_equal assets.count, 1, "Correct no of assets returned"
    assert_equal assets.first.code, asset1.code

    district = District.find_by(district_code: 'CC')
    assets = district.assets_by_type('hut')
    assert_equal assets.count, 0, "Correct no of assets returned"
  end

  test "can get assets with type for district" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5), country: 'ZL', code_prefix: 'ZLH/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/OT-', location: create_point(173.5,-41.6), country: 'ZL')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/CB-', location: create_point(171.5,-40.6), country: 'ZL')
    assets = District.get_assets_with_type
    sorted = assets.sort_by {|row| row['site_list']}

    assert_equal assets.count, 3, "Correct no of assets returned"
    assert_equal assets[1].site_list, [asset1.code]
    assert_equal assets[1].type, 'hut'
    assert_equal assets[1].name, 'CO'
    assert_equal assets[2].site_list, [asset2.code]
    assert_equal assets[2].type, 'summit'
    assert_equal assets[2].name, 'CO'
    assert_equal assets[0].site_list, [asset3.code]
    assert_equal assets[0].type, 'summit'
    assert_equal assets[0].name, 'CC'
  end

end


