# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class AssetLinksControllerTest < ActionController::TestCase

  ##################################################################
  # CREATE
  ##################################################################
  test "Create link with valid asset succeeds" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')

    post :create, {asset_code: asset1.safecode, asset_link: { contained_code: asset1.safecode, containing_code: asset2.safecode}}

    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode+"/associations"

    #success/failure  message
    assert_equal "Link created", flash[:success]
    assert_not_equal "Asset not found", flash[:error]

    #latest link
    aal=AssetLink.last

    assert_equal asset1.code, aal.contained_code, "Contained asset correct"
    assert_equal asset2.code, aal.containing_code, "Containing asset correct"
  end

  test "Create link with invalid contained asset fails" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')

    post :create, {asset_code: asset1.safecode, asset_link: { contained_code: 'ZLP_XX-1234', containing_code: asset2.safecode}}

    assert_response :redirect
    assert_redirected_to "/"

    #success/failure  message
    assert_not_equal "Link created", flash[:success]
    assert_equal "Asset not found", flash[:error]
  end

  test "Create link with invalid containing asset fails" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')

    post :create, {asset_code: asset1.safecode, asset_link: { contained_code: asset1.safecode, containing_code: 'ZLP_XX-1234'}}

    assert_response :redirect
    assert_redirected_to "/"

    #success /failure message
    assert_not_equal "Link created", flash[:success]
    assert_equal "Asset not found", flash[:error]
  end

  test "Create link with no referring asset succeeds but redirects to /" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')

    post :create, {asset_link: { contained_code: asset1.safecode, containing_code: asset2.safecode}}

    assert_response :redirect
    assert_redirected_to "/"

    #success /failure message
    assert_equal "Link created", flash[:success]
    assert_not_equal "Asset not found", flash[:error]

    #latest link
    aal=AssetLink.last

    assert_equal asset1.code, aal.contained_code, "Contained asset correct"
    assert_equal asset2.code, aal.containing_code, "Containing asset correct"
  end

  test "Cannot create link without signing in" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')

    post :create, {asset_code: asset1.safecode, asset_link: { contained_code: asset1.safecode, containing_code: asset2.safecode}}

    assert_response :redirect
    assert_redirected_to /signin/

    #success /failure message
    assert_equal "Please sign in.", flash[:notice]
  end

  ##################################################################
  # DELETE
  ###################################################################
  test "Delete link with valid asset succeeds" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')
    aal=AssetLink.create(containing_code: asset2.code, contained_code: asset1.code)
    aals=AssetLink.count

    post :delete, {id: aal.id, asset_code: asset1.safecode}

    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode+"/associations"

    #success/failure  message
    assert_equal "Link deleted", flash[:success]
    assert_not_equal "Failed to delete link", flash[:error]

    #gone
    assert_equal aals-1, AssetLink.count
  end

  test "Delete link with invalid asset rejected" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')
    aal=AssetLink.create(containing_code: asset2.code, contained_code: asset1.code)
    aals=AssetLink.count

    post :delete, {id: 99999999, asset_code: asset1.safecode}

    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode+"/associations"

    #success/failure  message
    assert_not_equal "Link deleted", flash[:success]
    assert_equal "Failed to delete link", flash[:error]

    #not gone
    assert_equal aals, AssetLink.count
  end

  test "Delete link with valid id, no referring asset succeeds, redirected to /" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')
    aal=AssetLink.create(containing_code: asset2.code, contained_code: asset1.code)
    aals=AssetLink.count

    post :delete, {id: aal.id}

    assert_response :redirect
    assert_redirected_to "/"

    #success/failure  message
    assert_equal "Link deleted", flash[:success]
    assert_not_equal "Failed to delete link", flash[:error]

    #gone
    assert_equal aals-1, AssetLink.count
  end

  test "must be logged in to delete link" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    asset2=create_test_asset(asset_type: 'park', region: 'CB', description: "This is a comment2", location: create_point(173,-45), name: 'test park')
    aal=AssetLink.create(containing_code: asset2.code, contained_code: asset1.code)
    aals=AssetLink.count

    post :delete, {id: aal.id, asset_code: asset1.safecode}

    assert_response :redirect
    assert_redirected_to /signin/

    #success /failure message
    assert_equal "Please sign in.", flash[:notice]
  end
end
