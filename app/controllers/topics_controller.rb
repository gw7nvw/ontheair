# typed: false
class TopicsController < ApplicationController

before_action :signed_in_user, only: [:destroy, :create, :update]

  def index
    @fulltopics=Topic.all.order(:name)
    @topics=@fulltopics.paginate(:per_page => 20, :page => params[:page])

  end

  def show
    tzid=3
    if current_user then tzid=current_user.timezone end
    @tz=Timezone.find(tzid)

    id=params[:id].to_i
    @topic=Topic.find_by_id(id)
    if @topic then 
      @fullitems=Item.find_by_sql [ "select * from items where topic_id="+id.to_s+" order by updated_at desc" ]
      if params[:title] then
        newitems=[]
        @fullitems.each do |item|
          if item and item.end_item and item.end_item.title==params[:title] then newitems.push ( item ) end
        end
        @fullitems=newitems
      end
      @items=@fullitems.paginate(:per_page => 20, :page => params[:page])
 
      watchers=UserTopicLink.where(topic_id: id)
      @watch_count=watchers.count
   else
    flash[:error]="Sorry - the topic or post that you tried to view no longer exists"
    redirect_to '/'
   end
  end

  def new
    @parent_topic=Topic.find_by_id(params[:topic_id])
    @topic=Topic.new
  end

  def update
  if signed_in?  then
    id=params[:id].to_i
    @topic=Topic.find_by_id(id)
    if @topic and (current_user.is_admin or (current_user.id==@topic.owner_id)) then
       if params[:commit]=="Delete Topic" then
         #delete all item
         @items=Item.where(:topic_id => @topic.id)
         count=0
         if @items then @items.each do |item|
           if item.end_item then item.end_item.destroy end
           if item then item.destroy end
           count=count+1
         end end
         if @topic.destroy
           flash[:success] = "Topic containing "+count.to_s+" posts deleted, id:"+id.to_s
           index()
           render 'index'
         else
           edit()
           render 'edit'
         end
       else
         @topic.assign_attributes(topic_params)
         @topic.updated_by_id=current_user.id
         if @topic.save then
           flash[:success] = "Topic details updated"

           # Handle a successful update.
           if params[:referring]=='index' then
             index()
             render 'index'
           else
             show()
             render 'show'
           end
         else
           render 'edit'
         end
       end #delete or edit
     else
       redirect_to '/'
     end # do we have permissions
    else
      redirect_to '/'
    end #does it exist
  end
  def edit
    if params[:referring] then @referring=params[:referring] end

    id=params[:id].to_i
    if(!(@topic = Topic.where(id: id).first))
      redirect_to '/'
    end
  end

  def create
    if signed_in? and current_user.is_modifier then
      if params[:topic_id] then @parent_topic=Topic.find_by_id(params[:topic_id]) end

      @topic=Topic.new(topic_params)

      @topic.created_by_id = current_user.id #current_user.id
      @topic.updated_by_id = current_user.id #current_user.id
      @topic.last_updated = Time.now

      if @topic.save
        if @parent_topic then
          item=Item.new
          item.topic_id=@parent_topic.id
          item.item_type="topic"
          item.item_id=@topic.id
          item.save
        end

        flash[:success] = "New topic added, id:"+@topic.id.to_s
        @edit=true

      #render edit panel to allow user to add links (can't do in create)
        @id=@topic.id
        params[:id]=@id.to_s
        show()
        render 'show'
      else
        flash[:error] = "Error creating topic"
        @edit=true
        render 'new'
      end
    else
      redirect_to '/'
    end

  end

  def destroy
  end

  private
  def topic_params
    params.require(:topic).permit(:name, :description, :owner_id, :is_owners, :is_public, :is_members_only, :date_required, :duration_required, :allow_mail, :is_spot, :is_alert)
  end

end
