# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class CommentsControllerTest < ActionController::TestCase

  ##################################################################
  # INDEX
  ##################################################################
  test "Should get index page" do
    get :index
    assert_response :success
  
    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Comments/

    #Action control bar
    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/
  end

  test "Shows all comments by default" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    comment2=Comment.create(comment: "Another comment ...", code: asset1.code, updated_by_id: user.id)

    get :index
    assert_response :success

    #data:
    table=get_table_test(@response.body, 'comment_table')
    assert_equal 3, get_row_count_test(table), "3 rows incl header"
    row=get_row_test(table,2)
    assert_match /#{user.callsign}/, get_col_test(row,1), "Correct callsign"
    assert_match /#{Time.now.in_time_zone('UTC').strftime('%Y-%m-%d')}/, get_col_test(row,2), "Creation date"
    assert_match /#{asset1.code}/, get_col_test(row,3), "Correct asset"
    assert_match /The Oamaru lookout point at the end of Tamar Road .../, get_col_test(row,4), "Correct comment"
    row=get_row_test(table,3)
    assert_match /Another comment .../, get_col_test(row,4), "Correct comment"
  end


  ##################################################################
  # SHOW
  ##################################################################
  test "Should get show page" do
    asset1=create_test_asset
    user=create_test_user
    comment=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    get :show, {id: comment.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Comments/
    assert_select '#crumbs', /#{comment.id}/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', {count: 0, text: /Delete/}
    assert_select '#controls', /Index/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#user', /#{user.callsign}/, "Name"
    assert_select '#asset', /#{make_regex_safe(asset1.code)}/, "code"
    assert_select '#date', /#{comment.updated_at.in_time_zone('UTC').strftime('%Y-%m-%d')}/, "Date"
    assert_select '#box_controls', {count: 0, text: /Edit/}
    assert_select '#box_controls', {count: 0, text: /Delete/}
    assert_select '#description', /#{make_regex_safe(comment.comment)}/, "text"
  end

  test "Creating user should get show page" do
    asset1=create_test_asset
    user=create_test_user
    sign_in(user)
    comment=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)

    get :show, {id: comment.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Comments/
    assert_select '#crumbs', /#{comment.id}/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 1, text: /Edit/}
    assert_select '#controls', {count: 1, text: /Delete/}
    assert_select '#controls', /Index/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#user', /#{user.callsign}/, "Name"
    assert_select '#asset', /#{make_regex_safe(asset1.code)}/, "code"
    assert_select '#date', /#{comment.updated_at.in_time_zone('UTC').strftime('%Y-%m-%d')}/, "Date"
    assert_select '#box_controls', {count: 1, text: /Edit/}
    assert_select '#box_controls', {count: 1, text: /Delete/}
    assert_select '#description', /#{make_regex_safe(comment.comment)}/, "text"
  end

  test "Admin user should get show page" do
    asset1=create_test_asset
    user=create_test_user
    sign_in users(:zl4nvw)
    comment=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)

    get :show, {id: comment.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Comments/
    assert_select '#crumbs', /#{comment.id}/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 1, text: /Edit/}
    assert_select '#controls', {count: 1, text: /Delete/}
    assert_select '#controls', /Index/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#user', /#{user.callsign}/, "Name"
    assert_select '#asset', /#{make_regex_safe(asset1.code)}/, "code"
    assert_select '#date', /#{comment.updated_at.in_time_zone('UTC').strftime('%Y-%m-%d')}/, "Date"
    assert_select '#box_controls', {count: 1, text: /Edit/}
    assert_select '#box_controls', {count: 1, text: /Delete/}
    assert_select '#description', /#{make_regex_safe(comment.comment)}/, "text"
  end

  test "Another user should get show page" do
    asset1=create_test_asset
    user=create_test_user
    sign_in users(:zl3cc)
    comment=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    get :show, {id: comment.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Comments/
    assert_select '#crumbs', /#{comment.id}/

    #Action control bar
    #does not show logged in version
    assert_select '#controls', {count: 0, text: /Edit/}
    assert_select '#controls', {count: 0, text: /Delete/}
    assert_select '#controls', /Index/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    assert_select '#user', /#{user.callsign}/, "Name"
    assert_select '#asset', /#{make_regex_safe(asset1.code)}/, "code"
    assert_select '#date', /#{comment.updated_at.in_time_zone('UTC').strftime('%Y-%m-%d')}/, "Date"
    assert_select '#box_controls', {count: 0, text: /Edit/}
    assert_select '#box_controls', {count: 0, text: /Delete/}
    assert_select '#description', /#{make_regex_safe(comment.comment)}/, "text"
  end

  ##################################################################
  # CREATE
  ##################################################################
  test "User should get create page" do
    asset1=create_test_asset
    user=create_test_user
    sign_in user

    get :new, {asset: asset1.safecode}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Comments/
    assert_select '#crumbs', /#{make_regex_safe(asset1.code)}/
    assert_select '#crumbs', /New/

    #Action control bar
    assert_select '#controls', /Cancel/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    assert_select '#comment_code' do assert_select "[value=?]", /#{make_regex_safe(asset1.code)}/ end
    assert_select '#comment_comment'
    assert_select '#submit'
  end

  test "Must be signed in to get create page" do
    asset1=create_test_asset

    get :new, {asset: asset1.safecode}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Can create a comment" do
    asset1=create_test_asset
    user=create_test_user
    sign_in user

    post :create, comment: {code: asset1.code, comment: 'This is a comment'}
    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode
    assert_equal "Posted!", flash[:success]

    comment=Comment.last
    assert_equal asset1.code, comment.code, "Code"
    assert_equal 'This is a comment', comment.comment, "Text"
    assert_equal user.id, comment.updated_by_id, "Poster"
    assert_equal Time.now.to_date, comment.updated_at.to_date, "Posted today"
  end

  test "Must be signed in to create comment" do
    asset1=create_test_asset
    user=create_test_user

    post :create, comment: {code: asset1.code, comment: 'This is a comment'}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "invalid comment params rejected correctly" do
    asset1=create_test_asset
    user=create_test_user
    sign_in user

    #no asset code
    post :create, comment: {comment: "this is a comment"}
    assert_response :success
    assert_select "#error_explanation", /Code/

    #no comment
    post :create, comment: {code: asset1.code, comment: ""}
    assert_response :success
    assert_select "#error_explanation", /Comment/
  end

  ##################################################################
  # EDIT
  ##################################################################
  test "User should get edit page" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    sign_in user

    get :edit, {id: comment1.id}
    assert_response :success

    #Breadcrumbs
    assert_select '#crumbs', /Home/
    assert_select '#crumbs', /Comments/
    assert_select '#crumbs', /#{make_regex_safe(asset1.code)}/
    assert_select '#crumbs', /#{comment1.id}/
    assert_select '#crumbs', /Edit/

    #Action control bar
    assert_select '#controls', /Cancel/

    assert_select '#controls', /Smaller Map/
    assert_select '#controls', /Larger Map/
    assert_select '#controls', /Back/

    #form 
    assert_select '#comment_code' do assert_select "[value=?]", /#{make_regex_safe(asset1.code)}/ end
    assert_select '#comment_comment' do assert_select "textarea", /The Oamaru lookout point at the end of Tamar Road/ end
    assert_select '#submit'
    assert_select '#deletebutton'
  end

  test "Must be signed in to get edit page" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    asset1=create_test_asset

    get :edit, {id: comment1.id}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Can update a comment" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    sign_in user

    patch :update, id: comment1.id, comment: {code: asset1.code, comment: 'This is a comment'}
    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode
    assert_equal "Post updated", flash[:success]

    comment=Comment.last
    assert_equal asset1.code, comment.code, "Code"
    assert_equal 'This is a comment', comment.comment, "Text"
    assert_equal user.id, comment.updated_by_id, "Poster"
    assert_equal Time.now.to_date, comment.updated_at.to_date, "Posted today"
  end

  test "Must be signed in to update comment" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)

    patch :update, id: comment1.id, comment: {code: asset1.code, comment: 'This is a comment'}
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Another user cannot update comment" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    sign_in users(:zl3cc)

    patch :update, id: comment1.id, comment: {code: asset1.code, comment: 'This is a comment'}
    assert_response :redirect
    assert_redirected_to "/assets/"+comment1.asset.safecode

    assert_equal "You do not have permissions to update this comment",  flash[:error]

    #not updated
    comment1.reload
    assert_not_equal "This is a comment", comment1.comment
  end

  test "invalid comment update params rejected correctly" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    sign_in user

    #no comment
    patch :update, id: comment1.id, comment: {code: asset1.code, comment: ''}
    assert_response :success
    assert_select "#error_explanation", /Comment/
  end

  ##################################################################
  # DELETE
  ##################################################################
  test "Can delete a comment" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    sign_in user

    get :delete, id: comment1.id
    assert_response :redirect
    assert_redirected_to "/assets/"+asset1.safecode
    assert_match "Comment deleted", flash[:success]

    comments=Comment.where(id: comment1.id)
    assert_equal 0, comments.count, "No comment with this id"
  end

  test "Must be signed in to delete comment" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)

    get :delete, id: comment1.id
    assert_response :redirect
    assert_redirected_to /signin/

    assert_equal "Please sign in.",  flash[:notice]
  end

  test "Another user cannot delete comment" do
    asset1=create_test_asset
    user=create_test_user
    comment1=Comment.create(comment: "The Oamaru lookout point at the end of Tamar Road ...", code: asset1.code, updated_by_id: user.id)
    comments=Comment.count
    sign_in users(:zl3cc)

    patch :update, id: comment1.id, comment: {code: asset1.code, comment: 'This is a comment'}
    assert_response :redirect
    assert_redirected_to "/assets/"+comment1.asset.safecode

    assert_equal "You do not have permissions to update this comment",  flash[:error]
    assert_equal comments, Comment.count, "Nothing deleted"
  end
end
