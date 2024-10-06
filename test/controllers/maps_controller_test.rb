# typed: false
require "test_helper"
include ApplicationHelper
include SessionsHelper
class MapsControllerTest < ActionController::TestCase
  test "Can read projections (legend)" do
    get :legend, {projection: 2193}

    assert_response :success
    assert_select '#projections' do
      Projection.all.each do |p|
        assert_select '[value=?]', p.epsg
      end
      assert_match %q{selected="selected" value="2193"}, @response.body, "Correct item selected"
    end
  end

  test "Can read layerswitcher" do
    get :layerswitcher, {projection: 2193}

    assert_response :success
    assert_select '#basemap' do
      Maplayer.all.each do |l|
        assert_select "##{l.id}"
      end
    end

    assert_select '#region_layers' do
      assert_select '#Districts'
      assert_select '#Regions'
    end

    assert_select '#point_layers' do
      AssetType.where("name != 'all'").each do |l|
        assert_select "##{l.id}"
      end
    end

    assert_select '#polygon_layers' do
      AssetType.where("has_boundary = true and name != 'all'").each do |l|
        assert_select "##{l.id}"
      end
    end
  end
end
