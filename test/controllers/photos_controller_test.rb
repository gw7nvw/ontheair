# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class PhotosControllerTest < ActionController::TestCase
  test "Can create new photo" do
    sign_in users(:zl4nvw)
    user1=User.find_by(callsign: 'ZL4NVW')
    asset1=create_test_asset

    get :new, {topic_id: PHOTO_TOPIC}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Photos/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #fields
    assert_select '#image_title'
    assert_select '#image_description'
    assert_select '#image_asset_codes'
    assert_select '#image_image'
    assert_select "#submit", {value: "Create Photo"}

    #create post
    upload_file = fixture_file_upload("files/image/test.jpeg",'image/jpeg')
    post :create, topic_id: PHOTO_TOPIC, image: {title: 'test image', description: 'This is a description', asset_codes: asset1.code, image: upload_file}
    assert_response :success
    post=Image.last
    apl=AssetPhotoLink.last


    #record created
    assert_equal user1.id, post.updated_by_id, "Author callsign"
    assert_equal 'test image', post.title, "Title"
    assert_equal 'This is a description', post.description, "description"

    #link to asset created
    assert_equal asset1.code, apl.asset_code, "Codes"
    assert_equal apl.photo_id, post.id, "link photo id"

    #show photo page

    #Breadcrumbs
    assert_select '#crumbs', /Photos/
    assert_select '#crumbs', /test image/

    #Action control bar
    assert_select '#controls', /Edit/
    assert_select '#controls', /Delete/
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select ".alert-success", /Posted/, "Success message"

    assert_select ".box_header", /ZL4NVW/, "Spotter Callsign"
    assert_select ".box_header", /test image/, "title"
    assert_select ".box_contents", /This is a description/, "description"
    assert_select ".box_header", /#{make_regex_safe(asset1.codename)}/, "location"
  end


  #TODO: edit photo

  #TODO: delete photo
end
