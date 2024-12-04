# frozen_string_literal: true

# typed: false
class PostsController < ApplicationController
  require 'uri'
  require 'net/http'

  before_action :signed_in_user, only: %i[delete create update new edit]
  skip_before_filter :verify_authenticity_token, only: %i[create update]

  def index
    ##    @fullposts=Post.all.order(:last_updated)
    ##    @posts=@fullposts.paginate(:per_page => 20, :page => params[:page])
    redirect_to '/topics'
  end

  def show
    @post = Post.find_by_id(params[:id])
    unless @post
      flash[:error] = 'Sorry - the topic or post that you tried to view no longer exists'
      redirect_to '/'
    end
  end

  def new
    @post = Post.new
    @topic = Topic.find_by_id(params[:topic_id])
    t = Time.now.in_time_zone(@tz.name).at_beginning_of_minute
    d = Time.now.in_time_zone(@tz.name).strftime('%Y-%m-%d 00:00 UTC').to_time
    @post.referenced_date = d.to_time if @topic.is_spot
    @post.referenced_time = t.to_time if @topic.is_spot
    @post.title = params[:title] if params[:title]
    redirect_to '/' unless @topic
    if params[:op_id]
      op = Post.find_by_id(params[:op_id])
      if op
        @post.callsign = op.callsign || op.updated_by_name
        @post.asset_codes = op.asset_codes
        @post.title = @post.callsign + ' spotted portable'
      end
    end
    @post.asset_codes = [params[:code].tr('_', '/')] if params[:code]
    if params[:spot]
      @post.do_not_lookup = true
      @post.referenced_time = Time.now.in_time_zone('UTC').at_beginning_of_minute
      @post.referenced_date = Time.now.in_time_zone('UTC').at_beginning_of_minute
      if params[:spot].to_i > 0
        spot = ExternalSpot.find_by(id: params[:spot].to_i)
        if spot
          @post.callsign = spot.activatorCallsign
          @post.freq = spot.frequency
          @post.mode = spot.mode
          @post.asset_codes = [spot.code.tr('_', '/')] if spot.code
        end
      else
        spot = Post.find_by(id: -params[:spot].to_i)
        if spot
          @post.callsign = spot.callsign
          @post.freq = spot.freq
          @post.mode = spot.mode
          @post.asset_codes = spot.asset_codes
        end
      end
    end
  end

  def edit
    @referring = params[:referring] if params[:referring]

    redirect_to '/' unless (@post = Post.where(id: params[:id]).first)
    if @post.referenced_time
      @post.referenced_time = @post.referenced_time.in_time_zone(@tz.name)
      @post.referenced_date = @post.referenced_date.in_time_zone(@tz.name).strftime('%Y-%m-%d 00:00 UTC').to_time
    end
    @topic = Topic.find_by_id(@post.topic_id)
  end

  def delete
    if signed_in?
      @post = Post.find_by_id(params[:id])
      topic = @post.topic
      if @post && (current_user.is_admin || (current_user.id == @post.created_by_id))
        @item = @post.item
        @item.destroy if @item
        @post.files.each(&:destroy)
        @post.images.each(&:destroy)

        if @post.destroy
          flash[:success] = 'Post deleted, id:' + params[:id]
          redirect_to '/topics/' + topic.id.to_s
        else
          flash[:error] = 'Failed to delete post'
          edit
          render 'edit'
        end
      else
        flash[:error] = 'Failed to delete post'
        redirect_to '/'
      end
    else
      flash[:error] = 'Failed to delete post'
      redirect_to '/'
     end
  end

  def update
    if signed_in?
      @post = Post.find_by_id(params[:id])
      topic = @post.topic
      if @post && (current_user.is_admin || (current_user.id == @post.created_by_id))
        if params[:commit] == 'Delete Post'
          @item = @post.item
          @item.destroy
          if @post.destroy
            flash[:success] = 'Post deleted, id:' + params[:id]
            @topic = topic
            #       @items=topic.items
            redirect_to '/topics/' + topic.id.to_s

          else
            flash[:error] = 'Failed to delete post'
            edit
            render 'edit'
          end
        else
          @post.assign_attributes(post_params)
          if params[:post][:asset_codes] then @post.asset_codes = params[:post][:asset_codes].delete('{').delete('}').split(',') end

          @post.site = ''
          @post.asset_codes.each do |ac|
            assets = Asset.assets_from_code(ac)
            @post.site += (assets && (assets.count > 0) ? assets.first[:name] : '') + ' [' + ac + '] ' + (assets && (assets.count > 0) && assets.first[:asset] ? '{' + assets.first[:asset].maidenhead + '}; ' : '')
          end

          if topic.is_alert
            @post.referenced_time = (params[:post][:referenced_date] + ' ' + params[:post][:referenced_time]).to_time.in_time_zone(@tz.name).in_time_zone('UTC').to_time
            @post.referenced_date = (params[:post][:referenced_date] + ' ' + params[:post][:referenced_time]).to_time.in_time_zone(@tz.name).in_time_zone('UTC').to_time
          end

          @post.updated_by_id = current_user.id
          if @post.save
            isimage = @post.is_image
            isfile = @post.is_file
            if isimage
              @image = Image.new
              @image.image = File.open(@post.image.path, 'rb')
              @image.post_id = @post.id
              unless @image.save
                flash[:error] = ''
                @image.errors.full_messages.each do |e|
                  flash[:error] += e
                  puts e
                end
              end
              @post.image = nil
              @post.save
            end

            flash[:success] = 'Post updated'

            # Handle a successful update.
            render 'show'
          else
            render 'edit'
          end
         end # delete or edit
      else
        redirect_to '/'
       end # do we have permissions
    else
      redirect_to '/'
       end # signed in
    end

  def create
    invalid = false
    errors = ''
    debug = params[:debug] ? true : false
    @topic = Topic.find_by_id(params[:topic_id])
    if signed_in? && @topic && (@topic.is_public || current_user.is_admin || ((@topic.owner_id == current_user.id) && @topic.is_owners))
      @post = Post.new(post_params)
      if @post.callsign.nil? || (@post.callsign == '') then @post.callsign = current_user.callsign end
      if params[:post][:asset_codes]
        @post.asset_codes = params[:post][:asset_codes].upcase.delete('{').delete('}').split(',').map(&:strip)
      end

      @post.site = ''
      @post.asset_codes.each do |ac|
        assets = Asset.assets_from_code(ac)
        @post.site += (assets && (assets.count > 0) ? (assets.first[:name] || '') : '') + ' [' + ac + '] ' + (assets && (assets.count > 0) && assets.first[:asset] ? '{' + assets.first[:asset].maidenhead + '}; ' : '')
      end
      @post.created_by_id = current_user.id # current_user.id
      @post.updated_by_id = current_user.id # current_user.id
      if @topic.is_alert
        if params[:post][:referenced_date] && !params[:post][:referenced_date].empty? && params[:post][:referenced_time] && !params[:post][:referenced_time].empty?
          t=(params[:post][:referenced_date] + ' ' + params[:post][:referenced_time]).to_time
          @post.referenced_time = Time.new.in_time_zone(@tz.name).change(year: t.year, month: t.month, day: t.day, hour: t.hour, min: t.min, sec: t.sec).in_time_zone('UTC').to_time
          @post.referenced_date = @post.referenced_time
        else
          invalid = true
          errors += 'Date / time are required; '
        end
      end

      if @topic.is_spot

        @post.referenced_time = Time.now
        @post.referenced_date = Time.now

      end
      @topic.last_updated = Time.now

      if !invalid && (debug || (!debug && @post.save))
        @post.add_map_image if @topic.is_spot || @topic.is_alert
        unless debug
          item = Item.new
          item.topic_id = @topic.id
          item.item_type = 'post'
          item.item_id = @post.id
          item.save
          item.send_emails unless @post.do_not_publish
        end
        flash[:success] = 'Posted! '
        @edit = true

        if params[:pnp] == 'on'
          success = @post.send_to_all(debug, current_user, @post.callsign, @post.asset_codes, @post.freq, @post.mode, @post.description, @topic, @post.referenced_date.strftime('%Y-%m-%d'), @post.referenced_time.strftime('%H:%M'), 'UTC')
          puts 'DEBUG: controller success: ' + success.to_s
          flash[:error] = success[:messages] if success[:result] == false
          if (success[:result] == true) && (success[:messages] != '') then flash[:success] += success[:messages] end
        end

        if debug
          render 'new'
        else
          render 'show'
        end
      else
        errors = 'Error creating post: ' + errors
        flash[:error] = errors
        @edit = true
        render 'new'
      end
    else
      puts 'Topoic: ' + @topic.to_s
      redirect_to '/'
    end
    end

  private

  def post_params
    params.require(:post).permit(:title, :description, :image, :do_not_publish, :duration, :is_hut, :is_park, :is_island, :is_summit, :site, :freq, :mode, :hut, :park, :island, :summit, :callsign, :asset_codes, :do_not_lookup)
  end
end
