require "test_helper"

class AssetLookthroughTest < ActiveSupport::TestCase

  test "Look-through values available" do

    #NOTE - this creates a record in an active, live production table - be warned
    #tidy up
    ls=Lake.where(code: 'ZLL/9999')
    ls.destroy_all

    asset=create_test_asset(asset_type: 'lake', code: 'ZLL/9999', is_active: false)

    assert asset.type.fields=="info_origin", "Test will not work if AssetType does not list correct fields"
    assert asset.type.table_name=="Lake", "Test will not work if AssetType does not list correct fields"

    lake=Lake.create(name: asset.name, code: asset.code, info_origin: "The origin is ...", topo50_fid: 12345)

    assert asset.table==Lake, "Correct underlying table returned: "+asset.table.to_s
    assert asset.record==lake, "Can retrieve underlying lake record: "+asset.record.to_json
    #info origin is listed as a shared field - get it
    assert asset.r_field("info_origin")=="The origin is ...", "Can retrieve look-through fields"
    #topo50_fid is not listed as a shared field - but get it anyway
    assert asset.r_field("topo50_fid")==12345, "Can retrieve unpublished fields too"
  
    #cleanup 
    lake.destroy 
  end
end
