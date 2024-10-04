# frozen_string_literal: true

# typed: false
class TopicsController < ApplicationController
  before_action :signed_in_user, only: %i[destroy create update]

  def index
    @fulltopics = Topic.all.order(:name)
    @topics = @fulltopics.paginate(per_page: 20, page: params[:page])
  end

  def show
    id = params[:id].to_i
    @topic = Topic.find_by_id(id)
    if @topic
      @fullitems = Item.find_by_sql ['select * from items where topic_id=' + id.to_s + ' order by updated_at desc']
      if params[:title]
        newitems = []
        @fullitems.each do |item|
          if item && item.end_item && (item.end_item.title == params[:title]) then newitems.push item end
        end
        @fullitems = newitems
      end
      @items = @fullitems.paginate(per_page: 20, page: params[:page])

      watchers = UserTopicLink.where(topic_id: id)
      @watch_count = watchers.count
    else
      flash[:error] = 'Sorry - the topic or post that you tried to view no longer exists'
      redirect_to '/'
   end
  end

  def new
    @parent_topic = Topic.find_by_id(params[:topic_id])
    @topic = Topic.new
  end

  def update
    if signed_in?
      id = params[:id].to_i
      @topic = Topic.find_by_id(id)
      if @topic && (current_user.is_admin || (current_user.id == @topic.owner_id))
        if params[:commit] == 'Delete Topic'
          # delete all item
          @items = Item.where(topic_id: @topic.id)
          count = 0
          if @items then @items.each do |item|
            item.end_item.destroy if item.end_item
            item.destroy if item
            count += 1
          end end
          if @topic.destroy
            flash[:success] = 'Topic containing ' + count.to_s + ' posts deleted, id:' + id.to_s
            index
            render 'index'
          else
            edit
            render 'edit'
          end
        else
          @topic.assign_attributes(topic_params)
          @topic.updated_by_id = current_user.id
          if @topic.save
            flash[:success] = 'Topic details updated'

            # Handle a successful update.
            if params[:referring] == 'index'
              index
              render 'index'
            else
              show
              render 'show'
            end
          else
            render 'edit'
          end
        end # delete or edit
      else
        redirect_to '/'
       end # do we have permissions
    else
      redirect_to '/'
      end # does it exist
  end

  def edit
    @referring = params[:referring] if params[:referring]

    id = params[:id].to_i
    redirect_to '/' unless (@topic = Topic.where(id: id).first)
  end

  def create
    if signed_in? && current_user.is_modifier
      @parent_topic = Topic.find_by_id(params[:topic_id]) if params[:topic_id]

      @topic = Topic.new(topic_params)

      @topic.created_by_id = current_user.id # current_user.id
      @topic.updated_by_id = current_user.id # current_user.id
      @topic.last_updated = Time.now

      if @topic.save
        if @parent_topic
          item = Item.new
          item.topic_id = @parent_topic.id
          item.item_type = 'topic'
          item.item_id = @topic.id
          item.save
        end

        flash[:success] = 'New topic added, id:' + @topic.id.to_s
        @edit = true

        # render edit panel to allow user to add links (can't do in create)
        @id = @topic.id
        params[:id] = @id.to_s
        show
        render 'show'
      else
        flash[:error] = 'Error creating topic'
        @edit = true
        render 'new'
      end
    else
      redirect_to '/'
    end
  end

  def destroy; end

  private

  def topic_params
    params.require(:topic).permit(:name, :description, :owner_id, :is_owners, :is_public, :is_members_only, :date_required, :duration_required, :allow_mail, :is_spot, :is_alert)
  end
end
