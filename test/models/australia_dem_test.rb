# typed: strict
require "test_helper"

class AustraliaDemTest < ActiveSupport::TestCase

  # slow test.  Manually run with: RUN_SLOW=true rails test test/models/australia_dem_test.rb
  test "SLOW: get correct AZ" do
    skip "Enable manually"
    asset1=create_test_asset(asset_type: 'summit', location: create_point(145.6399,-32.6864), code_prefix: 'VK2/LW-', altitude: 425)
    VCR.use_cassette("australia_dem/fetch_success") do
      asset1.add_vk_sota_activation_zone(25)
    end
    asset1.reload
    asset1.add_az_area
    asset1.reload
    assert_equal asset1.az_area.round(0), 1022458, "Correct VK AZ calculated"  
  end
end

