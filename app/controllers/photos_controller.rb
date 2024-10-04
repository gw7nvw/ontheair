# frozen_string_literal: true

# typed: false
class PhotosController < ApplicationController
  require 'uri'
  require 'net/http'

  before_action :signed_in_user, only: %i[delete create update new edit]
  skip_before_filter :verify_authenticity_token, only: %i[create update]

  def index
    redirect_to '/topics'
  end

  def show
    @parameters = params_to_query

    @image = Image.find_by_id(params[:id])
    unless @image
      flash[:error] = 'Sorry - the topic or image that you tried to view no longer exists'
      redirect_to '/'
    end
    @image.asset_codes = @image.get_asset_codes
  end

  def new
    @parameters = params_to_query

    @image = Image.new
    @topic = Topic.find_by_id(params[:topic_id])
    @image.title = params[:title] if params[:title]
    @image.asset_codes = params[:asset].tr('_', '/') if params[:asset]
    redirect_to '/' unless @topic
  end

  def edit
    @referring = params[:referring] if params[:referring]

    redirect_to '/' unless (@image = Image.where(id: params[:id]).first)
    @topic = Topic.find_by_id(@image.topic_id)
    @image.asset_codes = @image.get_asset_codes
  end

  def delete
    if signed_in?
      @image = Image.find_by_id(params[:id])
      topic = @image.topic
      if @image && (current_user.is_admin || (current_user.id == @image.created_by_id))
        @item = @image.item
        @item.destroy if @item
        @image.links.each(&:destroy)

        if @image.destroy
          flash[:success] = 'Image deleted, id:' + params[:id]
          redirect_to '/topics/' + topic.id.to_s
        else
          flash[:error] = 'Failed to delete image'
          edit
          render 'edit'
        end
      else
        flash[:error] = 'Failed to delete image'
        redirect_to '/'
      end
    else
      flash[:error] = 'Failed to delete image'
      redirect_to '/'
     end
  end

  def update
    if signed_in?
      @image = Image.find_by_id(params[:id])
      topic = @image.topic
      if @image && (current_user.is_admin || (current_user.id == @image.created_by_id))
        if params[:commit] == 'Delete Image'
          @item = @image.item
          @item.destroy
          @image.links.each(&:destroy)
          if @image.destroy
            flash[:success] = 'Image deleted, id:' + params[:id]
            @topic = topic
            #      @items=topic.items
            redirect_to '/topics/' + topic.id.to_s

          else
            flash[:error] = 'Failed to delete image'
            edit
            render 'edit'
          end
        else
          @image.assign_attributes(image_params)

          @image.updated_by_id = current_user.id
          if @image.save
            flash[:success] = 'Image updated'
          else
            flash[:error] = 'Could not update image'
          end
          @image.links.each(&:destroy)
          assets = Asset.assets_from_code(@image.asset_codes)
          assets.each do |asset|
            pal = AssetPhotoLink.new
            pal.photo_id = @image.id
            pal.link_url = @image.image.url(:original)
            pal.asset_code = asset[:code]
            pal.save
          end

          # Handle a successful update.
          render 'show'
        end # delete or edit
      else
        flash[:error] = "Sorry - you don't have permissions to post to this topic"
        redirect_to '/'
      end # do we have permissions
    else
      redirect_to '/'
     end # signed in
    end

  def create
    @topic = Topic.find_by_id(params[:topic_id])
    if signed_in? && @topic && (@topic.is_public || current_user.is_admin || ((@topic.owner_id == current_user.id) && @topic.is_owners))
      @image = Image.new(image_params)

      @image.created_by_id = current_user.id # current_user.id
      @image.updated_by_id = current_user.id # current_user.id
      @topic.last_updated = Time.now

      if @image.save
        item = Item.new
        item.topic_id = @topic.id
        item.item_type = 'image'
        item.item_id = @image.id
        item.save

        assets = Asset.assets_from_code(@image.asset_codes)
        assets.each do |asset|
          pal = AssetPhotoLink.new
          pal.photo_id = @image.id
          pal.link_url = @image.image.url(:original)
          pal.asset_code = asset[:code]
          pal.save
        end

        flash[:success] = 'Posted!'
        @edit = true

        render 'show'
      else
        flash[:error] = 'Error creating image'
        @edit = true
        render 'new'
      end
    else
      redirect_to '/'
    end
    end

  private

  def image_params
    params.require(:image).permit(:title, :description, :image, :site, :asset_codes)
  end
end
