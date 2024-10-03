# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class AssetWebLinksControllerTest < ActionController::TestCase

  ##################################################################
  # CREATE
  ##################################################################
  test "Create link with valid asset succeeds" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')

    post :create, { asset_web_link: { asset_code: asset1.safecode, link_class: 'other', url: 'http://example.com/test' }}

    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode

    #success/failure  message
    assert_equal "Link created", flash[:success]
    assert_not_equal "Asset not found", flash[:error]

    #latest link
    awl=AssetWebLink.last

    assert_equal asset1.code, awl.asset_code, "Parent asset code"
    assert_equal 'http://example.com/test', awl.url, "URL"
    assert_equal 'other', awl.link_class, "Type"
  end

  test "Create link with valid asset succeeds - handles https" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')

    post :create, { asset_web_link: { asset_code: asset1.safecode, link_class: 'other', url: 'https://example.com/test' }}

    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode

    #success/failure  message
    assert_equal "Link created", flash[:success]
    assert_not_equal "Asset not found", flash[:error]

    #latest link
    awl=AssetWebLink.last

    assert_equal asset1.code, awl.asset_code, "Parent asset code"
    assert_equal 'https://example.com/test', awl.url, "URL"
    assert_equal 'other', awl.link_class, "Type"
  end

  test "Create link with valid asset succeeds - handles URl without protocol" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')

    post :create, { asset_web_link: { asset_code: asset1.safecode, link_class: 'other', url: 'example.com/test' }}

    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode

    #success/failure  message
    assert_equal "Link created", flash[:success]
    assert_not_equal "Asset not found", flash[:error]

    #latest link
    awl=AssetWebLink.last

    assert_equal asset1.code, awl.asset_code, "Parent asset code"
    assert_equal 'http://example.com/test', awl.url, "URL"
    assert_equal 'other', awl.link_class, "Type"
  end

  test "Create link with invalid asset rejected" do
    sign_in users(:zl3cc)

    post :create, { asset_web_link: { asset_code: 'ZLP_XX-1234', link_class: 'other', url: 'example.com/test' }}

    assert_response :redirect
    assert_redirected_to "/"

    #success/failure  message
    assert_not_equal "Link created", flash[:success]
    assert_equal "Asset not found", flash[:error]
  end

  test "Must be logged in to create links" do
    post :create, { asset_web_link: { asset_code: 'ZLP_XX-1234', link_class: 'other', url: 'example.com/test' }}

    assert_response :redirect
    assert_redirected_to /signin/

    #success/failure  message
    assert_equal "Please sign in.", flash[:notice]
  end

  ##################################################################
  # DELETE
  ##################################################################
  test "Delete valid link succeeds" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    awl=AssetWebLink.create(asset_code: asset1.safecode, link_class: 'other', url: 'http://example.com/test')
    awls=AssetWebLink.count

    post :delete, { id: awl.id }

    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode

    #success/failure  message
    assert_equal "Link deleted", flash[:success]
    assert_not_equal "Failed to delete link", flash[:error]

    #latest link gone
    assert_equal awls-1, AssetWebLink.count
  end

  test "Delete invalid link rejected correctly" do
    sign_in users(:zl3cc)
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    awl=AssetWebLink.create(asset_code: asset1.safecode, link_class: 'other', url: 'http://example.com/test')
    awls=AssetWebLink.count

    post :delete, { id: 999999 }

    assert_response :redirect
    assert_redirected_to "/"

    #success/failure message
    assert_not_equal "Link deleted", flash[:success]
    assert_equal "Failed to delete link", flash[:error]

    #latest link still there
    assert_equal awls, AssetWebLink.count
  end

  test "Must be signed in to delete link" do
    asset1=create_test_asset(asset_type: 'hut', region: 'CB', description: "This is a comment", location: create_point(173,-45), name: 'test hut')
    awl=AssetWebLink.create(asset_code: asset1.safecode, link_class: 'other', url: 'http://example.com/test')
    awls=AssetWebLink.count

    post :delete, { id: awl.id }

    assert_response :redirect
    assert_redirected_to /signin/

    #success/failure message
    assert_equal "Please sign in.", flash[:notice]

    #latest link still there
    assert_equal awls, AssetWebLink.count
  end
end
