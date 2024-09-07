require "test_helper"

class AssetSaveTest < ActiveSupport::TestCase

  test "Add area" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173.5,-41.5), boundary: 'MULTIPOLYGON(((171 -45, 171.1 -45, 171.1 -45.1, 171 -45.1)))')
    asset1.reload
    assert_in_delta 87548393, asset1.area, 50000, "Area calculated correctly +/- 0.5%"
  end

  test "add elevation" do
    asset1=create_test_asset(asset_type: 'summit', location: create_point(173.3636016845703, -41.47439956665039), code_prefix: 'ZL3/OT-')
    asset1.reload
    assert_in_delta 1480, asset1.altitude, 1, "Altitide correctly added +/-1m"
  end

  test "add AZ (SOTA)" do
    asset1=create_test_asset(asset_type: 'summit', location: create_point(175.47459411621094,-38.25600051879883), code_prefix: 'ZL3/OT-', altitude: 496)
    asset1.reload
    result=Asset.find_by_sql [" select ST_Area(ST_Transform(boundary,2193)) as area from assets where id=#{asset1.id}; "]
    assert_in_delta 34502, result.first.area, 3500, "AZ added of size expected +/- 10%"
  end

  test "add AZ (lighthouse)" do
    asset1=create_test_asset(asset_type: 'lighthouse', location: create_point(168.163650908159, -46.8955991917859), az_radius: 10)
    asset1.reload
    result=Asset.find_by_sql [" select ST_Area(ST_Transform(boundary,2193)) as area from assets where id=#{asset1.id}; "]
    assert_in_delta 312144515, result.first.area, 300000, "AZ added of size expected +/- 1%"
  end

  #no roads, DOC tracks, legal road data in test env, so just test with parks
  test "get access (testable via parks only)" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(173, -45), test_radius: 0.1)

    asset2=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset3=create_test_asset(asset_type: 'hut', location: create_point(173.2,-45.2))
    asset4=create_test_asset(asset_type: 'lighthouse', location: create_point(173.2,-45.2), az_radius: 50)
    asset2.reload
    asset3.reload
    asset4.reload

    assert_equal true, asset2.public_access,  "Hut in park has access"
    assert_equal [asset1.id.to_s], asset2.access_park_ids,  "Hut access is via park"
    
    assert_equal false, asset3.public_access,  "Hut outside park has no access"
    assert_equal nil, asset3.access_park_ids,  "Hut has no access"
    
    assert_equal true, asset4.public_access,  "Lighthouse outside park has access as AZ overlaps park"
    assert_equal [asset1.id.to_s], asset4.access_park_ids,  "Lighhouse AZ has access via park"
  end

  #no roads, DOC tracks, legal road data in test env, so just test with parks
  test "get lake access wth buffer (testable via parks only)" do
    asset1=create_test_asset(asset_type: 'park', location: create_point(170.9, -45), test_radius: 0.1)
    asset2=create_test_asset(asset_type: 'island', location: create_point(171.1025, -45), test_radius: 0.1) #near point 171.0025 is 490m from park
    asset3=create_test_asset(asset_type: 'lake', location: create_point(171.1025, -45), test_radius: 0.1) #near point 171.0025 is 490m from park
    asset2.reload
    asset3.reload

    assert_equal false, asset2.public_access,  "Island has no acess as is 490m from park"
    assert_equal nil, asset2.access_park_ids,  "No park access to island"
    
    assert_equal true, asset3.public_access,  "Lake does have access as 500m buffer includes park"
    assert_equal [asset1.id.to_s], asset3.access_park_ids,  "Lake has access due to 500m buffer"
  end
end
