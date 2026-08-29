# typed: false
require "test_helper"

class DxccPrefixTest < ActiveSupport::TestCase
  test "Can get dxcc from callsign" do
    callsign = "ZL4NVW"
    assert_equal DxccPrefix.from_call("ZL4NVW").name, "New Zealand", "ZL call located" 
    assert_equal DxccPrefix.from_call("VK4NVW").name, "Australia", "VK call located" 
    assert_equal DxccPrefix.from_call("VI4NVW").name, "Australia", "VK call located" 
    assert_equal DxccPrefix.from_call("VI4NVW/P").name, "Australia", "VK portable call located" 
    assert_equal DxccPrefix.from_call("VK/N1AAA").name, "Australia", "Overseas call portable in VK located" 
  end 
  test "Can get dxcc name from callsign" do
    callsign = "ZL4NVW"
    assert_equal DxccPrefix.name_from_call("ZL4NVW"), "New Zealand (Oceania)", "ZL call located" 
    assert_equal DxccPrefix.name_from_call("VK4NVW"), "Australia (Oceania)", "VK call located" 
    assert_equal DxccPrefix.name_from_call("VI4NVW"), "Australia (Oceania)", "VK call located" 
    assert_equal DxccPrefix.name_from_call("VI4NVW/P"), "Australia (Oceania)", "VK portable call located" 
    assert_equal DxccPrefix.name_from_call("VK/N1AAA"), "Australia (Oceania)", "Overseas call portable in VK located" 
  end

   test "Can get continent from callsign" do
    callsign = "ZL4NVW"
    assert_equal DxccPrefix.continent_from_call("ZL4NVW"), "OC", "ZL call located"
    assert_equal DxccPrefix.continent_from_call("VK4NVW"), "OC", "VK call located"
    assert_equal DxccPrefix.continent_from_call("VI4NVW"), "OC", "VK call located"
    assert_equal DxccPrefix.continent_from_call("VI4NVW/P"), "OC", "VK portable call located"
    assert_equal DxccPrefix.continent_from_call("VK/N1AAA"), "OC", "Overseas call portable in VK located"
    assert_equal DxccPrefix.continent_from_call("N1AAA"), "NA", "North america call located"
  end

  test "can get assets by dxcc" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5), country: 'ZL', code_prefix: 'ZLH/WK-')
    asset2=create_test_asset(asset_type: 'summit', code_prefix: 'ZL1/WK-', location: create_point(173.5,-41.6), country: 'ZL')
    asset3=create_test_asset(asset_type: 'summit', code_prefix: 'VK1/AC-', country: 'VK')
    assets = DxccPrefix.get_assets_with_type('ZL')
    sorted = assets.sort_by {|row| row['type']}
    assert_equal assets.count, 2, "Correct no of classes returned"
    assert_equal assets.first["site_list"], [asset1.code]
    assert_equal assets.last["site_list"], [asset2.code]

    assets = DxccPrefix.get_assets_with_type('VK')
    assert_equal assets.count, 1, "Correct no of assets returned"
    assert_equal assets.first["site_list"], [asset3.code]
  end

end


