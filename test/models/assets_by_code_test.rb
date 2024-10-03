# typed: strict
require "test_helper"

class AssetByCodeTest < ActiveSupport::TestCase

  # Covers all ..._by_code methods


  #TODO: why is the addition of '/' needed in URL?  
  #Code should be consistent and always include it, 
  #but recall there were issues with that approach ...
  test "Correct details returned for a known asset" do
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173.5,-41.5))
    #assets_from_code
    a_s=Asset.assets_from_code(asset1.code)
 
    assert_equal(a_s.count, 1, "One asset returned")
    a=a_s.first
    assert_equal(a[:asset],asset1)
    assert_equal(a[:url],'/'+asset1.url, "Correct URL Returned")
    assert_equal(a[:name], asset1.name, "Correct name returned")
    assert_equal(a[:code], asset1.code, "Correct code returned")
    assert_equal(a[:type], asset1.asset_type, "Correct type returned")
    assert_equal(a[:external], false, "Internal asset to pur database")
    assert_nil(a[:external_url], "External URL correct")
    assert_equal(a[:title], asset1.type.display_name, "Title is asset type display name")

    #get_asset_type_from_code
    assert_equal('hut', Asset.get_asset_type_from_code(asset1.code), "Correct type from get_asset_type")

    #get pnp class by code
    assert_equal('ZLOTA', Asset.get_pnp_class_from_code(asset1.code), "Correct type from get_pnp_class")
  end

  test "Correct details returned for a known VK asset" do
    asset1=create_test_vkasset(award: 'POTA', code_prefix: 'AU-0', site_type: 'POTA Park')
    a_s=Asset.assets_from_code(asset1.code)
 
    assert_equal(a_s.count, 1, "One asset returned")
    a=a_s.first
    assert_equal(a[:asset],asset1)
    assert_equal(a[:url], asset1.url, "Correct URL Returned")
    assert_equal(a[:name], asset1.name, "Correct name returned")
    assert_equal(a[:code], asset1.code, "Correct code returned")
    assert_equal(a[:type], 'pota park', "Correct type returned")
    assert_equal(a[:external], false, "Internal asset to our database")
    assert_equal(a[:external_url], asset1.external_url, "External URL correct")
    assert_equal(a[:title], asset1.site_type, "Title is site type display name")

    #get_asset_type_from_code
    assert_equal('pota park', Asset.get_asset_type_from_code(asset1.code), "Correct type from get_pnp_class")

    #get pnp class by code
    assert_equal('POTA', Asset.get_pnp_class_from_code(asset1.code), "Correct type from get_asset_type")
  end

  test "Correct details returned for overseas HEMA" do
    testcode='GM/HES-001'
    a_s=Asset.assets_from_code(testcode)

    assert_equal(1, a_s.count, "One asset returned")
    a=a_s.first
    assert_nil(a[:asset],"No asset returned")
    assert_equal(a[:url], "http://hema.org.uk", "Correct URL")
    assert_equal(a[:name], testcode, "Name is code")
    assert_equal(a[:code], testcode, "Correct code returned")
    assert_equal(a[:type], 'hump', "Correct type returned")
    assert_equal(a[:external], true, "External asset")
    assert_equal(a[:title], 'HEMA', "Title is award name")

    #get_asset_type_from_code
    assert_equal('hump', Asset.get_asset_type_from_code(testcode), "Correct type from get_asset_type")

    #get pnp class by code
    assert_equal('HEMA', Asset.get_pnp_class_from_code(testcode), "Correct type from get_asset_type")

  end

  test "Correct details returned for overseas SiOTA" do
    testcode='VK-ABC1'
    a_s=Asset.assets_from_code(testcode)

    assert_equal(1, a_s.count, "One asset returned")
    a=a_s.first
    assert_nil(a[:asset],"No asset returned")
    assert_equal(a[:url], "https://www.silosontheair.com/silos/#"+testcode, "Correct URL")
    assert_equal(a[:name], testcode, "Name is code")
    assert_equal(a[:code], testcode, "Correct code returned")
    assert_equal(a[:type], 'silo', "Correct type returned")
    assert_equal(a[:external], true, "External asset")
    assert_equal(a[:title], 'SiOTA', "Title is award name")

    #get_asset_type_from_code
    assert_equal('silo', Asset.get_asset_type_from_code(testcode), "Correct type from get_asset_type")

    #get pnp class by code
    assert_equal('SiOTA', Asset.get_pnp_class_from_code(testcode), "Correct type from get_asset_type")
  end

  test "Correct details returned for overseas POTA" do
    testcode='US-12345'
    a_s=Asset.assets_from_code(testcode)

    assert_equal(1, a_s.count, "One asset returned")
    a=a_s.first
    assert_nil(a[:asset],"No asset returned")
    assert_equal(a[:url], "https://pota.app/#/park/"+testcode, "Correct URL")
    assert_equal(a[:name], testcode, "Name is code")
    assert_equal(a[:code], testcode, "Correct code returned")
    assert_equal(a[:type], 'pota park', "Correct type returned")
    assert_equal(a[:external], true, "External asset")
    assert_equal(a[:title], 'POTA', "Title is award name")

    #get_asset_type_from_code
    assert_equal('pota park', Asset.get_asset_type_from_code(testcode), "Correct type from get_asset_type")

    #get pnp class by code
    assert_equal('POTA', Asset.get_pnp_class_from_code(testcode), "Correct type from get_asset_type")
  end

  test "Correct details returned for overseas WWFF" do
    testcode='4UFF-1234'
    a_s=Asset.assets_from_code(testcode)

    assert_equal(1, a_s.count, "One asset returned")
    a=a_s.first
    assert_nil(a[:asset],"No asset returned")
    assert_equal(a[:url], "https://wwff.co/directory/?showRef="+testcode, "Correct URL")
    assert_equal(a[:name], testcode, "Name is code")
    assert_equal(a[:code], testcode, "Correct code returned")
    assert_equal(a[:type], 'wwff park', "Correct type returned")
    assert_equal(a[:external], true, "External asset")
    assert_equal(a[:title], 'WWFF', "Title is award name")

    #get_asset_type_from_code
    assert_equal('wwff park', Asset.get_asset_type_from_code(testcode), "Correct type from get_asset_type")

    #get pnp class by code
    assert_equal('WWFF', Asset.get_pnp_class_from_code(testcode), "Correct type from get_asset_type")
  end

  test "Correct details returned for overseas SOTA" do
    testcode='K9/AL-123'
    a_s=Asset.assets_from_code(testcode)

    assert_equal(1, a_s.count, "One asset returned")
    a=a_s.first
    assert_nil(a[:asset],"No asset returned")
    assert_equal(a[:url], "https://www.sotadata.org.uk/en/summit/"+testcode, "Correct URL")
    assert_equal(a[:name], testcode, "Name is code")
    assert_equal(a[:code], testcode, "Correct code returned")
    assert_equal(a[:type], 'summit', "Correct type returned")
    assert_equal(a[:external], true, "External asset")
    assert_equal(a[:title], 'SOTA', "Title is award name")

    #get_asset_type_from_code
    assert_equal('summit', Asset.get_asset_type_from_code(testcode), "Correct type from get_asset_type")
  end
end
