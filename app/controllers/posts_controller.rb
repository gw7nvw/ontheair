class PostsController < ApplicationController
require "uri"
require "net/http"

before_action :signed_in_user, only: [:delete, :create, :update, :new, :edit]
skip_before_filter :verify_authenticity_token, :only => [:create, :update]

def index
##    @fullposts=Post.all.order(:last_updated)
##    @posts=@fullposts.paginate(:per_page => 20, :page => params[:page])
   redirect_to '/topics'
end

def show
    tzid=3
    if current_user then tzid=current_user.timezone end
    @tz=Timezone.find(tzid)

    @parameters=params_to_query

    @post=Post.find_by_id(params[:id])
    if !@post then 
      flash[:error]="Sorry - the topic or post that you tried to view no longer exists"
      redirect_to '/'
    end
end


def new
    @parameters=params_to_query

    @post=Post.new
    @topic=Topic.find_by_id(params[:topic_id])
    @tz=Timezone.find_by_id(current_user.timezone||3)
    t=Time.now.in_time_zone(@tz.name).strftime('%H:%M')
    d=Time.now.in_time_zone(@tz.name).strftime('%Y-%m-%d')
    if @topic.is_spot then @post.referenced_date=d end
    if @topic.is_spot then @post.referenced_time=t end
    if params[:title] then @post.title=params[:title] end
    if !@topic then 
      redirect_to '/'
    end
    if params[:op_id] then
      op=Post.find_by_id(params[:op_id])
      if op then
        if op.callsign then @post.callsign=op.callsign else @post.callsign=op.updated_by_name end
        @post.asset_codes=op.asset_codes
        @post.title=@post.callsign+" spotted portable" 
      end
    end
end

def edit
    @tz=Timezone.find_by_id(current_user.timezone||3)
    if params[:referring] then @referring=params[:referring] end

    if(!(@post = Post.where(id: params[:id]).first))
      redirect_to '/'
    end
    if @post.referenced_time then 
      @post.referenced_time=@post.referenced_time.in_time_zone(@tz.name).strftime('%H:%M')
      @post.referenced_date=@post.referenced_date.in_time_zone(@tz.name).strftime('%Y-%m-%d')
    end
    @topic=Topic.find_by_id(@post.topic_id)
end

def delete
 if signed_in?  then
    @post=Post.find_by_id(params[:id])
    topic=@post.topic
    if @post and (current_user.is_admin or (current_user.id==@post.created_by_id)) then
      @item=@post.item
      if @item then @item.destroy end
      @post.files.each do |f|
         f.destroy
      end
      @post.images.each do |f|
         f.destroy
      end

      if @post.destroy
        flash[:success] = "Post deleted, id:"+params[:id]
        redirect_to '/topics/'+topic.id.to_s 
      else
        flash[:error] = "Failed to delete post"
        edit()
        render 'edit'
      end
    else 
      flash[:error] = "Failed to delete post"
      redirect_to '/'
    end
  else 
    flash[:error] = "Failed to delete post"
    redirect_to '/'
  end
end

def update
 @tz=Timezone.find_by_id(current_user.timezone||3)
 if signed_in?  then
    @post=Post.find_by_id(params[:id])
    topic=@post.topic
    if @post and (current_user.is_admin or (current_user.id==@post.created_by_id)) then
      if params[:commit]=="Delete Post" then
         @item=@post.item
         @item.destroy
         if @post.destroy
           flash[:success] = "Post deleted, id:"+params[:id]
           @topic=topic     
    #       @items=topic.items
           redirect_to '/topics/'+topic.id.to_s

         else
           flash[:error] = "Failed to delete post"
           edit()
           render 'edit'
         end
       else
         @post.assign_attributes(post_params)
         if params[:post][:asset_codes] then @post.asset_codes=params[:post][:asset_codes].gsub('{','').gsub('}','').split(',') end

         @post.site=""
         @post.asset_codes.each do |ac|
          assets=Asset.assets_from_code(ac)
          @post.site+=(if assets and assets.count>0 then assets.first[:name] else "" end)+" ["+ac+"] "+(if assets and assets.count>0 and assets.first[:asset] then "{"+assets.first[:asset].maidenhead+"}; " else "" end)
        end

         if topic.is_alert then 
           @post.referenced_time=(params[:post][:referenced_date]+' '+params[:post][:referenced_time]).in_time_zone(@tz.name).in_time_zone('UTC')
           @post.referenced_date=(params[:post][:referenced_date]+' '+params[:post][:referenced_time]).in_time_zone(@tz.name).in_time_zone('UTC')
         end

         @post.updated_by_id=current_user.id
         if @post.save then
           isimage=@post.is_image
           isfile=@post.is_file
           if isimage then
             @image=Image.new
             @image.image=File.open(@post.image.path,'rb')
             @image.post_id=@post.id
             if not @image.save then
                  flash[:error]=""
                  @image.errors.full_messages.each do |e|
                     flash[:error]+=e
                     puts e
                  end
             end
             @post.image=nil
             @post.save
           end

           flash[:success] = "Post updated"

           # Handle a successful update.
             render 'show'
         else
           render 'edit'
         end
       end #delete or edit
     else
       redirect_to '/'
     end # do we have permissions
    else
      redirect_to '/'
    end #signed in

end

def create
    @tz=Timezone.find_by_id(current_user.timezone||3)
    if params[:debug] then debug=true else debug=false end
    @topic=Topic.find_by_id(params[:topic_id])
    if signed_in? and @topic and (@topic.is_public or current_user.is_admin or (@topic.owner_id==current_user.id and @topic.is_owners)) then
      @post=Post.new(post_params)
      if params[:post][:asset_codes] then 
         @post.asset_codes=params[:post][:asset_codes].upcase.gsub('{','').gsub('}','').split(',')
      end

      @post.site=""
      @post.asset_codes.each do |ac|
        assets=Asset.assets_from_code(ac)
        @post.site+=(if assets and assets.count>0 then assets.first[:name]||"" else "" end)+" ["+ac+"] "+(if assets and assets.count>0 and assets.first[:asset] then "{"+assets.first[:asset].maidenhead+"}; " else "" end)
      end
      @post.created_by_id = current_user.id #current_user.id
      @post.updated_by_id = current_user.id #current_user.id
      if @topic.is_alert then
        @post.referenced_time=(params[:post][:referenced_date]+" "+params[:post][:referenced_time]).in_time_zone(@tz.name).in_time_zone('UTC')
        @post.referenced_date=(params[:post][:referenced_date]+" "+params[:post][:referenced_time]).in_time_zone(@tz.name).in_time_zone('UTC')
      end

      if @topic.is_spot then 
       
#        @post.referenced_time=Time.now.strftime('%H:%M')
        @post.referenced_time=Time.now
        @post.referenced_date=Time.now

#        @post.referenced_date=Time.now.strftime('%Y-%m-%d')
      end
      @topic.last_updated = Time.now


      if debug or (!debug and @post.save) then
        if @topic.is_spot or @topic.is_alert then
           @post.add_map_image
        end
        if !debug then 
          item=Item.new
          item.topic_id=@topic.id
          item.item_type="post"
          item.item_id=@post.id
          item.save
          if !@post.do_not_publish then item.send_emails end
        end
        flash[:success] = "Posted!"
        @edit=true


        if params[:pnp]=="on" then 
            res=@post.send_to_pnp(debug,@topic,@post.referenced_date.strftime('%Y-%m-%d'),@post.referenced_time.strftime('%H:%M'),'UTC')
            if res and res!="" then
              debugstart=res.body.index("INSERT")
              if debugstart then
                flash[:success]=res.body[debugstart..-1]
              end
            else
              flash[:error]="Failed to send to PnP. Did you specify a valid place, frequency, mode & callsign?"
            end
        end
       
        if debug then 
          render 'new'
        else
          render 'show'
        end
      else
        flash[:error] = "Error creating post"
        @edit=true
        render 'new'
      end
    else
      redirect_to '/'
    end

end

  private
  def post_params
    params.require(:post).permit(:title, :description, :image, :do_not_publish, :referenced_date, :referenced_time, :duration, :is_hut, :is_park, :is_island,:is_summit, :site, :freq, :mode, :hut, :park, :island, :summit, :callsign, :asset_codes)
  end

end
