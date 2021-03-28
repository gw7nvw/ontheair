class PostsController < ApplicationController

before_action :signed_in_user, only: [:delete, :create, :update]

def index
##    @fullposts=Post.all.order(:last_updated)
##    @posts=@fullposts.paginate(:per_page => 20, :page => params[:page])
   redirect_to '/topics'
end

def show
    @post=Post.find_by_id(params[:id])
    if !@post then 
      flash[:error]="Sorry - the topic or post that you tried to view no longer exists"
      redirect_to '/'
    end
end


def new
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
        @post.hut=op.hut
        @post.park=op.park
        @post.island=op.island
        @post.summit=op.summit
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
           @items=topic.items
           render 'topics/show'

         else
           flash[:error] = "Failed to delete post"
           edit()
           render 'edit'
         end
       else
         @post.assign_attributes(post_params)
         @post.site=""
         if @post.hut and @post.hut.length>0 then @post.is_hut=true; @post.site+="[Hut: "+@post.hut+"] " else @post.is_hut=false end
         if @post.park and @post.park.length>0 then @post.is_park=true; @post.site+="[Park: "+@post.park+"] "  else @post.is_park=false end
         if @post.island and @post.island.length>0 then @post.is_island=true; @post.site+="[Island: "+@post.island+"] " else @post.is_island=false end
         if @post.summit and @post.summit.length>0 then @post.is_summit=true; @post.site+="[Summit: "+@post.summit+"] " else @post.is_summit=false end
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
    @topic=Topic.find_by_id(params[:topic_id])
    if signed_in? and @topic and (@topic.is_public or current_user.is_admin or (@topic.owner_id==current_user.id and @topic.is_owners)) then
      @post=Post.new(post_params)
      @post.site=""
      if @post.hut and @post.hut.length>0 then @post.is_hut=true; @post.site+="[Hut: "+@post.hut+"] " else @post.is_hut=false end
      if @post.park and @post.park.length>0 then @post.is_park=true; @post.site+="[Park: "+@post.park+"] "  else @post.is_park=false end
      if @post.island and @post.island.length>0 then @post.is_island=true; @post.site+="[Island: "+@post.island+"] " else @post.is_island=false end
      if @post.summit and @post.summit.length>0 then @post.is_summit=true; @post.site+="[Summit: "+@post.summit+"] " else @post.is_summit=false end
      @post.created_by_id = current_user.id #current_user.id
      @post.updated_by_id = current_user.id #current_user.id
      @topic.last_updated = Time.now

      if @post.save then
  
        item=Item.new
        item.topic_id=@topic.id
        item.item_type="post"
        item.item_id=@post.id
        item.save
        if !@post.do_not_publish then item.send_emails end

        flash[:success] = "Posted!"
        @edit=true

        render 'show'
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
    params.require(:post).permit(:title, :description, :image, :do_not_publish, :referenced_date, :referenced_time, :duration, :is_hut, :is_park, :is_island,:is_summit, :site, :freq, :mode, :hut, :park, :island, :summit, :callsign)
  end

end
