class PostsController < ApplicationController
require "uri"
require "net/http"

before_action :signed_in_user, only: [:delete, :create, :update, :new, :edit]

def index
##    @fullposts=Post.all.order(:last_updated)
##    @posts=@fullposts.paginate(:per_page => 20, :page => params[:page])
   redirect_to '/topics'
end

def show
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
    t=Time.now.in_time_zone("Pacific/Auckland").strftime('%H:%M')
    d=Time.now.in_time_zone("Pacific/Auckland").strftime('%Y-%m-%d')
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
    if params[:referring] then @referring=params[:referring] end

    if(!(@post = Post.where(id: params[:id]).first))
      redirect_to '/'
    end
    @topic=Topic.find_by_id(@post.topic_id)
end

def delete
 if signed_in?  then
    @post=Post.find_by_id(params[:id])
    topic=@post.topic
    if @post and (current_user.is_admin or (current_user.id==@post.created_by_id)) then
      @item=@post.item
      @item.destroy

      if @post.destroy
        flash[:success] = "Post deleted, id:"+params[:id]
        redirect_to '/' 
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
           render 'topics/show'

         else
           flash[:error] = "Failed to delete post"
           edit()
           render 'edit'
         end
       else
         @post.assign_attributes(post_params)
         pp=[];params[:post][:asset_codes].each do |p,k| if k and k.length>0 then pp.push(k) end end
         @post.asset_codes=pp
         @post.site=""
         @post.asset_codes.each do |ac|
           @post.site+=ac+" "
         end

         @post.updated_by_id=current_user.id
         if @post.save then

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
    if params[:debug] then debug=true else debug=false end
    @topic=Topic.find_by_id(params[:topic_id])
    if signed_in? and @topic and (@topic.is_public or current_user.is_admin or (@topic.owner_id==current_user.id and @topic.is_owners)) then
      @post=Post.new(post_params)
      pp=[];params[:post][:asset_codes].each do |p,k| if k and k.length>0 then pp.push(k) end end
      @post.asset_codes=pp
      @post.site=""
      @post.asset_codes.each do |ac|
        @post.site+=ac+" " 
      end
      @post.created_by_id = current_user.id #current_user.id
      @post.updated_by_id = current_user.id #current_user.id
      if @topic.is_spot then 
       
        @post.referenced_time=Time.now.in_time_zone("Pacific/Auckland").strftime('%H:%M')

        @post.referenced_date=Time.now.in_time_zone("Pacific/Auckland").strftime('%Y-%m-%d')
      end
      @topic.last_updated = Time.now

      if debug or (!debug and @post.save) then
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
            res=@post.send_to_pnp(debug,@topic,params[:post][:referenced_date],params[:post][:referenced_time],nil)
            debugstart=res.body.index("INSERT")
            if debugstart then
              flash[:success]=res.body[debugstart..-1]
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
