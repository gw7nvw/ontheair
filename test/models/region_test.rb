# typed: false
require "test_helper"

class RegionTest < ActiveSupport::TestCase
  test "can get assets for region" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5), country: 'ZL', code_prefix: 'ZLH/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/OT-', location: create_point(173.5,-41.6), country: 'ZL')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/CB-', location: create_point(171.5,-40.6), country: 'ZL')
    region = Region.find_by(sota_code: 'OT')
    assets = region.assets.sort_by {|row| row['code']}

    assert_equal assets.count, 2, "Correct no of assets returned"
    assert_equal assets.first.code, asset2.code
    assert_equal assets.last.code, asset1.code

    region = Region.find_by(sota_code: 'CB')
    assets = region.assets
    assert_equal assets.count, 1, "Correct no of assets returned"
    assert_equal assets.first.code, asset3.code
  end

  test "can get assets by type for region" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5), country: 'ZL', code_prefix: 'ZLH/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/OT-', location: create_point(173.5,-41.6), country: 'ZL')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/CB-', location: create_point(171.5,-40.6), country: 'ZL')
    region = Region.find_by(sota_code: 'OT')
    assets = region.assets_by_type('hut')
    assert_equal assets.count, 1, "Correct no of assets returned"
    assert_equal assets.first.code, asset1.code

    region = Region.find_by(sota_code: 'CB')
    assets = region.assets_by_type('hut')
    assert_equal assets.count, 0, "Correct no of assets returned"
  end

  test "can get assets with type for region" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5), country: 'ZL', code_prefix: 'ZLH/OT-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/OT-', location: create_point(173.5,-41.6), country: 'ZL')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/CB-', location: create_point(171.5,-40.6), country: 'ZL')
    assets = Region.get_assets_with_type
    sorted = assets.sort_by {|row| row['site_list']}

    assert_equal assets.count, 3, "Correct no of assets returned"
    assert_equal assets[1].site_list, [asset1.code]
    assert_equal assets[1].type, 'hut'
    assert_equal assets[1].name, 'OT'
    assert_equal assets[2].site_list, [asset2.code]
    assert_equal assets[2].type, 'summit'
    assert_equal assets[2].name, 'OT'
    assert_equal assets[0].site_list, [asset3.code]
    assert_equal assets[0].type, 'summit'
    assert_equal assets[0].name, 'CB'
  end

end


