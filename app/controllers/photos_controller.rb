class PhotosController < ApplicationController
require "uri"
require "net/http"

before_action :signed_in_user, only: [:delete, :create, :update, :new, :edit]
skip_before_filter :verify_authenticity_token, :only => [:create, :update]

def index
##    @fullimages=Image.all.order(:last_updated)
##    @images=@fullimages.paginate(:per_page => 20, :page => params[:page])
   redirect_to '/topics'
end

def show
    @parameters=params_to_query

    @image=Image.find_by_id(params[:id])
    if !@image then 
      flash[:error]="Sorry - the topic or image that you tried to view no longer exists"
      redirect_to '/'
    end
    @image.asset_codes=@image.get_asset_codes
end


def new
    @parameters=params_to_query

    @image=Image.new
    @topic=Topic.find_by_id(params[:topic_id])
    if params[:title] then @image.title=params[:title] end
    if params[:asset] then @image.asset_codes=params[:asset].gsub('_','/') end
    if !@topic then 
      redirect_to '/'
    end
end

def edit
    @tz=Timezone.find_by_id(current_user.timezone||3)
    if params[:referring] then @referring=params[:referring] end

    if(!(@image = Image.where(id: params[:id]).first))
      redirect_to '/'
    end
    @topic=Topic.find_by_id(@image.topic_id)
    @image.asset_codes=@image.get_asset_codes
end

def delete
 if signed_in?  then
    @image=Image.find_by_id(params[:id])
    topic=@image.topic
    if @image and (current_user.is_admin or (current_user.id==@image.created_by_id)) then
      @item=@image.item
      if @item then @item.destroy end
      @image.links.each do |link|
        link.destroy
      end

      if @image.destroy
        flash[:success] = "Image deleted, id:"+params[:id]
        redirect_to '/topics/'+topic.id.to_s 
      else
        flash[:error] = "Failed to delete image"
        edit()
        render 'edit'
      end
    else 
      flash[:error] = "Failed to delete image"
      redirect_to '/'
    end
  else 
    flash[:error] = "Failed to delete image"
    redirect_to '/'
  end
end

def update
 @tz=Timezone.find_by_id(current_user.timezone||3)
 if signed_in?  then
    @image=Image.find_by_id(params[:id])
    topic=@image.topic
    if @image and (current_user.is_admin or (current_user.id==@image.created_by_id)) then
      if params[:commit]=="Delete Image" then
        @item=@image.item
        @item.destroy
        @image.links.each do |link|
          link.destroy
        end
        if @image.destroy
          flash[:success] = "Image deleted, id:"+params[:id]
          @topic=topic     
    #      @items=topic.items
          redirect_to '/topics/'+topic.id.to_s

        else
          flash[:error] = "Failed to delete image"
          edit()
          render 'edit'
        end
      else
        @image.assign_attributes(image_params)

        @image.updated_by_id=current_user.id
        if @image.save then
          flash[:success] = "Image updated"
        else
          flash[:error] = "Could not update image"
        end
        @image.links.each do |link|
          link.destroy
        end
        assets=Asset.assets_from_code(@image.asset_codes)
        assets.each do |asset|
          pal=AssetPhotoLink.new
          pal.photo_id=@image.id
          pal.link_url=@image.image.url(:original)
          pal.asset_code=asset[:code]
          pal.save
        end

        # Handle a successful update.
        render 'show'
      end #delete or edit
    else
      flash[:error]="Sorry - you don't have permissions to post to this topic"
      redirect_to '/'
    end # do we have permissions
  else
    redirect_to '/'
  end #signed in

end

def create
    @topic=Topic.find_by_id(params[:topic_id])
    if signed_in? and @topic and (@topic.is_public or current_user.is_admin or (@topic.owner_id==current_user.id and @topic.is_owners)) then
      @image=Image.new(image_params)

      #@image.site=""
      #@image.asset_codes.each do |ac|
      #  assets=Asset.assets_from_code(ac)
      #  @image.site+=(if assets and assets.count>0 then assets.first[:name]||"" else "" end)+" ["+ac+"] " 
      #end
      @image.created_by_id = current_user.id #current_user.id
      @image.updated_by_id = current_user.id #current_user.id
      @topic.last_updated = Time.now


      if @image.save then
        item=Item.new
        item.topic_id=@topic.id
        item.item_type="image"
        item.item_id=@image.id
        item.save

        assets=Asset.assets_from_code(@image.asset_codes)
        assets.each do |asset|
          pal=AssetPhotoLink.new
          pal.photo_id=@image.id
          pal.link_url=@image.image.url(:original)
          pal.asset_code=asset[:code]
          pal.save
        end

        flash[:success] = "Posted!"
        @edit=true


        render 'show'
      else
        flash[:error] = "Error creating image"
        @edit=true
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
