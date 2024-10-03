# typed: strict
require "test_helper"

class AssetSaveTest < ActiveSupport::TestCase

  test "All calculated fields applied for a point site" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5))
    assert_equal asset1.valid_from, '1900-01-01'.to_time, "Default from time applied"
    assert_equal asset1.minor, false, "Default minor_asset status applied"
    assert_equal asset1.region, 'OT', "Region looked up from location"+asset1.region
    assert_equal asset1.district, 'CO', "District looked up from location"+asset1.district
    assert_equal asset1.code, 'ZLH/OT-001', "Code applied based on region: "+asset1.code
    assert_equal asset1.safecode, 'ZLH_OT-001', "Safe code generated"
    assert_equal asset1.url, 'assets/ZLH_OT-001', "URL generated"
    asset1.reload
    assert_nil asset1.area, "No area calculated"
  end

  test "All calculated fields applied for a polygon site" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(172,-40.5), test_radius: 0.01)
    assert asset1.valid_from=='1900-01-01'.to_time, "Default from time applied"
    assert asset1.minor==false, "Default minor_asset status applied"
    assert asset1.region=='CB', "Region looked up from location"
    assert asset1.district=='CC', "District looked up from location"
    assert asset1.code=='ZLP/CB-0001', "Code applied based on region: "+asset1.code
    assert asset1.safecode=='ZLP_CB-0001', "Safe code generated"
    assert asset1.url=='assets/ZLP_CB-0001', "URL generated"
    asset1.reload
    assert asset1.area>0, "Area calculated"
  end
  
end
