require "test_helper"

class AssetChildrenTest < ActiveSupport::TestCase

  test "For a point, all containing polygons listed" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)

    assert asset1.contained_by_assets==[asset2].sort, "Asset Containing our point added"
    assert asset1.contains_assets==[].sort, "no contained assets for point"
    assert asset2.contained_by_assets==[].sort, "No contaning assets for polygon"
    assert asset2.contains_assets==[asset1].sort, "Point asset contained by polygon"
    assert asset3.contained_by_assets==[].sort, "No contaning assets for polygon elsewhere"
    assert asset3.contains_assets==[].sort, "No asset contained by polygon elsewhere"
  end

 test "For a polygon, polygons containing parent listed" do 
    #small
    asset1=create_test_asset(asset_type: 'park', location: create_point(174,-45), test_radius: 0.01)
    #large
    asset2=create_test_asset(asset_type: 'park', location: create_point(174,-45), test_radius: 0.1)
    #elsewhere
    asset3=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)

    assert_equal asset1.contained_by_assets, [asset2].sort, "Asset Containing our smaller polygon added"
    assert_equal asset1.contains_assets, [].sort, "no contained assets for our smaller polygon"
    assert_equal asset2.contained_by_assets, [].sort, "No contaning assets for larger polygon"
    assert_equal asset2.contains_assets, [asset1].sort, "Smaller polygon contained by larger polygon"
    assert_equal asset3.contained_by_assets, [].sort, "No contaning assets for polygon elsewhere"
    assert_equal asset3.contains_assets, [].sort, "No asset contained by polygon elsewhere"
  end

  test "For a polygon, polygons overlapping by 90%+ listed" do 
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.094) # Specify length. Area=0.94x0.94=88.3%
    asset3=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.095) # Specify length. Area=0.95x0.95=90.2%
    assert asset1.contained_by_assets.sort==[asset3].sort, "Asset 1 (0.1) polygon contained by asset3  polgon (0.9):"+asset1.contained_by_assets.map{|c| c.code}.to_json
    assert asset1.contains_assets.sort==[asset2, asset3].sort, "both smaller polygons contained by larger"+asset1.contains_assets.map{|c| c.code}.to_json
  end

  test "can handle contained polygon asset with no boundary" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45)) #contained with no polygon
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    assert asset1.contained_by_assets.sort==[asset2].sort, "Asset 1 boundryless polygon contained by asset2 polgon:"+asset1.contained_by_assets.map{|c| c.code}.to_json
    assert asset1.contains_assets.sort==[].sort, "boundryless polygon contains nothing"
  end

  test "can handle point asset with no location" do
    asset1=create_test_asset(asset_type: 'hut') #parent with no location
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    assert asset1.contained_by_assets.sort==[].sort, "Point with no location contained by nothing"
    assert asset1.contains_assets.sort==[].sort, "Point with no location contains nothing"
  end

  test "can handle polygon asset with no location or boundary" do
    asset1=create_test_asset(asset_type: 'park') #parent with no polygon or location
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    assert asset1.contained_by_assets.sort==[].sort, "Polygon with no location contained by nothing"
    assert asset1.contains_assets.sort==[].sort, "Polygon with no location contains nothing"
  end

  test "inactive contained_by_assets not applied" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1, is_active: false)
    assert asset1.contained_by_assets.sort==[].sort, "Inactive Polygon not returned"
  end
end
