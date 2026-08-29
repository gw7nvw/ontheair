# typed: strict
require "test_helper"

class AssetContainingByLocationTest < ActiveSupport::TestCase

  test "For a point, all containing polygons listed" do
    location=create_point(173,-45)
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.2)
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)
    assert_equal [asset1.code, asset2.code].sort, Asset.containing_codes_from_location(location).sort, "Asset containing our point listed"
  end

  test "inactive contained_by_assets not applied" do
    location=create_point(173,-45)
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1, is_active: false)
    assert_equal [asset1.code], Asset.containing_codes_from_location(location), "Inactive location not listed"
  end

  test "AZ for point location picked up by contained point" do
    location=create_point(173,-45)
    asset1=create_test_asset(asset_type: 'lighthouse', location: create_point(173,-45), test_radius: 0.1)
    assert_equal [asset1.code], Asset.containing_codes_from_location(location), "Point location with AZ is listed"
  end
end
