# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class QueryControllerTest < ActionController::TestCase
  test "Can search by code" do
    asset1=create_test_asset
    get :index, {asset_type: {name: 'all'}, searchtext: asset1.code, assetfield: 'asset', minor: 'on'}


    assert_response :success

    #Asset Types listed, all selected
    assert_select '#asset_type_name' do
      AssetType.all.each do |p|
        assert_select '[value=?]', p.name
      end
    end
    assert_match %q{selected="selected" value="all"}, @response.body, "Correct asset type selected"

    #searchtext
    assert_select '#searchtext' do
      assert_select '[value=?]', asset1.code
    end

    # minor - EXCLUDE by default (checked)
    assert_select '#minor' do
      assert_select '[checked=?]', "checked"
    end
    
    #results
    table=get_table_test(@response.body, 'result_table')
    assert_equal 1, get_row_count_test(table), "1 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,1), "Asset1 listed"
  end

  test "Can show linked assets" do
    #Hut within a park
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', region: 'CB', location: create_point(173,-45), test_radius: 0.1)

    get :index, {asset_type: {name: 'all'}, searchtext: asset1.code, assetfield: 'asset', minor: 'on'}


    assert_response :success

    #Asset Types listed, all selected
    assert_select '#asset_type_name' do
      AssetType.all.each do |p|
        assert_select '[value=?]', p.name
      end
    end
    assert_match %q{selected="selected" value="all"}, @response.body, "Correct asset type selected"

    #searchtext
    assert_select '#searchtext' do
      assert_select '[value=?]', asset1.code
    end

    # minor - EXCLUDE by default (checked)
    assert_select '#minor' do
      assert_select '[checked=?]', "checked"
    end
    
    #results
    table=get_table_test(@response.body, 'result_table')
    assert_equal 1, get_row_count_test(table), "1 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,1), "Asset1 listed"
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,2), "Asset2 listed as linked asset"
  end

  test "Can match multiple assets" do
    #two huts in CB
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-46))

    get :index, {asset_type: {name: 'all'}, searchtext: 'ZLH/CB', assetfield: 'asset', minor: 'on'}


    assert_response :success

    #Asset Types listed, all selected
    assert_select '#asset_type_name' do
      AssetType.all.each do |p|
        assert_select '[value=?]', p.name
      end
    end
    assert_match %q{selected="selected" value="all"}, @response.body, "Correct asset type selected"

    #searchtext
    assert_select '#searchtext' do
      assert_select '[value=?]', 'ZLH/CB'
    end

    # minor - EXCLUDE by default (checked)
    assert_select '#minor' do
      assert_select '[checked=?]', "checked"
    end
    
    #results
    table=get_table_test(@response.body, 'result_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,1), "Asset1 listed"
    row=get_row_test(table,2)
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,1), "Asset2 listed"
  end

  test "Can match by name" do
    #two huts in CB
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-46))

    get :index, {asset_type: {name: 'all'}, searchtext: asset1.name, assetfield: 'asset', minor: 'on'}


    assert_response :success

    #Asset Types listed, all selected
    assert_select '#asset_type_name' do
      AssetType.all.each do |p|
        assert_select '[value=?]', p.name
      end
    end
    assert_match %q{selected="selected" value="all"}, @response.body, "Correct asset type selected"

    #searchtext
    assert_select '#searchtext' do
      assert_select '[value=?]', asset1.name
    end

    # minor - EXCLUDE by default (checked)
    assert_select '#minor' do
      assert_select '[checked=?]', "checked"
    end
    
    #results
    table=get_table_test(@response.body, 'result_table')
    assert_equal 1, get_row_count_test(table), "1 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,1), "Asset1 listed"
  end

  test "Can exclude minor assets" do
    #two huts in CB
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), minor: true)
    asset2=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-46))

    get :index, {asset_type: {name: 'all'}, searchtext: 'ZLH/CB', assetfield: 'asset', minor: 'on'}

    assert_response :success

    #Asset Types listed, all selected
    assert_select '#asset_type_name' do
      AssetType.all.each do |p|
        assert_select '[value=?]', p.name
      end
    end
    assert_match %q{selected="selected" value="all"}, @response.body, "Correct asset type selected"

    #searchtext
    assert_select '#searchtext' do
      assert_select '[value=?]', 'ZLH/CB'
    end
    # minor - EXCLUDE by default (checked)
    assert_select '#minor' do
      assert_select '[checked=?]', "checked"
    end
    
    #results
    table=get_table_test(@response.body, 'result_table')
    assert_equal 1, get_row_count_test(table), "1 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,1), "Asset2 listed"
  end


  test "Can include minor assets" do
    #two huts in CB
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), minor: true)
    asset2=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-46))

    get :index, {asset_type: {name: 'all'}, searchtext: 'ZLH/CB', assetfield: 'asset'}

    assert_response :success

    #Asset Types listed, all selected
    assert_select '#asset_type_name' do
      AssetType.all.each do |p|
        assert_select '[value=?]', p.name
      end
    end
    assert_match %q{selected="selected" value="all"}, @response.body, "Correct asset type selected"

    #searchtext
    assert_select '#searchtext' do
      assert_select '[value=?]', 'ZLH/CB'
    end
    # minor - EXCLUDE by default (checked)
    assert_select '#minor' do
      assert_select '[checked]', {count: 0}
    end
    
    #results
    table=get_table_test(@response.body, 'result_table')
    assert_equal 2, get_row_count_test(table), "2 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset1.codename)}/, get_col_test(row,1), "Minor Asset1 listed"
    row=get_row_test(table,2)
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,1), "Asset2 listed"
  end

  test "Can filter by type" do
    #hut and park
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), minor: true)
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment", location: create_point(173,-46))

    get :index, {asset_type: {name: 'park'}, searchtext: '/CB-', assetfield: 'asset', minor: 'on'}

    assert_response :success

    #Asset Types listed, all selected
    assert_select '#asset_type_name' do
      AssetType.all.each do |p|
        assert_select '[value=?]', p.name
      end
    end
    assert_match %q{selected="selected" value="park"}, @response.body, "Correct asset type selected"

    #searchtext
    assert_select '#searchtext' do
      assert_select '[value=?]', '/CB-'
    end
    # minor - EXCLUDE by default (checked)
    assert_select '#minor' do
      assert_select '[checked=?]', "checked"
    end
    
    #results
    table=get_table_test(@response.body, 'result_table')
    assert_equal 1, get_row_count_test(table), "1 rows"
    row=get_row_test(table,1)
    assert_match /#{make_regex_safe(asset2.codename)}/, get_col_test(row,1), "Only park listed"
  end

end
