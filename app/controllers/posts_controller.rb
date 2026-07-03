# frozen_string_literal: true

# typed: false
class PostsController < ApplicationController
  require 'uri'
  require 'net/http'

  before_action :signed_in_user, only: %i[delete create update new edit]
  skip_before_filter :verify_authenticity_token, only: %i[create update sms]

  def sms
    logger.info params.to_json
    logger.info response.body.to_json

    ats = AssetType.where("name != 'all'")
    pnp_classes = ats.map{|at| at.pnp_class}

    via = 'SMS'
    puts 'DEBUG SMS'
    body = params[:text]
    lines = body.split(/\r?\n/)
    msgs = lines[0].split(' ')
    logger.debug "DEBUG msgs "+msgs.to_json
    if msgs[0].upcase=='ALERT' then
      posttype='alert'
      msgs=msgs[1..-1]
    elsif msgs[0].upcase=='SPOT' then
      posttype='spot'
      msgs=msgs[1..-1]
    else
      posttype='spot'
    end

    # passkey = nil
    acctnumber = params[:from]
    acctnumber = acctnumber.strip.delete(' ')
    logger.debug 'DEBUG from number: ' + acctnumber
    user = User.find_by(acctnumber: acctnumber)
    logger.error "ERROR: SMS account not found for " + acctnumber if !user

    if msgs then
      #handle pnp style spots by dropping 2nd parameter
      if pnp_classes.include?(msgs[1])
        msgs=[msgs[0]]+msgs[2..-1] 
      end

      callsign = msgs[0].upcase
      callsign = sub_callsign if callsign == '!'
      asset_code = msgs[1].upcase
      if asset_code.include?('/') || asset_code.include?('-')
        logger.debug 'DEBUG: asset code appears to be complete'
      else
        logger.debug 'DEBUG: asset code looks like SOTA-spot format'
        asset_suffix = msgs[2]
        unless asset_suffix.include?('-')
          logger.debug "DEBUG: asset suffix with no '-'"
          asset_suffix = asset_suffix.gsub(/([a-zA-Z])([0-9])/, '\1-\2')
        end
        asset_code = asset_code + '/' + asset_suffix
        msgs=[msgs[0],asset_code]+msgs[3..-1]
        #msgs.delete_at(msgs.length - 1)
        logger.info 'DEBUG: concatenated asset code = ' + asset_code
        logger.info 'DEBUG: message = ' + msgs.to_json
      end
      freq = msgs[2]
      mode = msgs[3].upcase
      if posttype == 'spot'
        comments = msgs[4..-1].join(' ')
        logger.info 'DEBUG: comments = ' + msgs.to_json
        al_date = Time.now.in_time_zone('UTC').strftime('%Y-%m-%d')
        al_time = Time.now.in_time_zone('UTC').strftime('%H:%M')
      else
        al_date = msgs[4]
        al_time = msgs[5]
        comments = msgs[6..-1].join(' ')
      end

      @post = Post.new
      debug = comments.upcase['DEBUG'] ? true : false
      # check asset
      assets = Asset.assets_from_code(asset_code)
      # if !assets or assets.count==0 or assets.first[:code]==nil then puts "Asset not known:"+asset_code ;return(false) end
      if !assets || assets.count.zero? || assets.first[:code].nil?
        puts 'Asset not known:' + asset_code + ' ... trying to continue'
        a_code = ''
        a_name = 'Unrecognised location: ' + asset_code
        a_ext = false
      else
        a_code = assets.first[:code]
        a_name = assets.first[:name]
        a_ext = assets.first[:external]
      end

      asset_type = Asset.get_asset_type_from_code(a_code)
      if comments.downcase.include?("/dnl")
        comments=comments.gsub("/dnl","").gsub("/DNL","")
        @post.do_not_lookup = true
      end
      if (posttype == 'spot') && ((asset_type == 'SOTA') || (asset_type == 'summit'))
        puts 'DEBUG: sending to SOTA'
        result = @post.send_to_sota(debug, acctnumber, callsign, a_code, freq, mode, comments + ' (ontheair.nz)')
        puts 'DEBUG: ' + result.to_s
      end

      if user

        # fill in details
        @post.mode = mode.upcase
        @post.callsign = callsign
        @post.freq = freq
        @post.asset_codes = a_code != '' ? [a_code] : []
        @post.created_by_id = user.id
        @post.updated_by_id = user.id
        @post.description = comments + ' (via ' + via + ')'

        @post.referenced_time = (al_date + ' ' + al_time + ' UTC').to_time
        @post.referenced_date = (al_date + ' 00:00:00 UTC').to_time
        @post.updated_at = Time.now
        puts 'DEBUG: assets - ' + a_name
        if posttype == 'spot'
          topic_id = if debug
                       TEST_SPOT_TOPIC
                     else
                       SPOT_TOPIC
                     end
          @post.title = 'SPOT: ' + callsign + ' spotted portable at ' + a_name + '[' + a_code + '] on ' + freq + '/' + mode + ' at ' + Time.now.in_time_zone('Pacific/Auckland').strftime('%Y-%m-%d %H:%M') + 'NZ'
        else
          topic_id = if debug
                       TEST_ALERT_TOPIC
                     else
                       ALERT_TOPIC
                     end
          @post.title = 'ALERT: ' + callsign + ' going portable to ' + a_name + '[' + a_code + '] on ' + freq + '/' + mode + ' at ' + al_date + ' ' + al_time + ' UTC'
        end
        res = @post.save
        if res
          if a_ext == false
            @post.add_map_image
            res = @post.save
          end
          item = Item.new
          item.topic_id = topic_id
          item.item_type = 'post'
          item.item_id = @post.id
          item.save
          item.send_emails
        end
        @topic = Topic.find_by_id(topic_id)
        @post.send_to_all(debug, user, @post.callsign, @post.asset_codes, @post.freq, @post.mode, @post.description, @topic, @post.referenced_date.strftime('%Y-%m-%d'), @post.referenced_time.strftime('%H:%M'), 'UTC')
      end
    end
    respond_to do |format|
      format.js { render json: {result: "success"}.to_json }
      format.json { render json: {result: "success"}.to_json }
      format.html { render json: {result: "success"}.to_json }
    end

  end

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
    @post.duration = 1 if @topic.is_alert
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
        spot = ConsolidatedSpot.find_by(id: params[:spot].to_i)
        if spot
          @post.callsign = spot.activatorCallsign
          @post.freq = spot.frequency
          @post.mode = spot.mode
          @post.asset_codes = spot.code if spot.code
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
          if params[:post][:asset_codes]
            #check fo X,Y
            if params[:post][:asset_codes].match(/-?([0-9\.])+,( )?-?([0-9\.])+/)
              loc_text=params[:post][:asset_codes]
              puts loc_text
              loc_arr=loc_text.split(',')
              puts loc_arr
              x1=loc_arr[0].to_f
              y1=loc_arr[1].to_f
              @post.location="POINT(#{x1} #{y1})"
              @post.loc_source='user'
            else
              @post.asset_codes = params[:post][:asset_codes].upcase.delete('{').delete('}').split(',').map(&:strip)
            end
          end

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
      @post.callsign = @post.callsign.strip if @post.callsign
      @post.mode = @post.mode.strip if @post.mode
      if params[:post][:asset_codes]
        #check fo X,Y
        if params[:post][:asset_codes].match(/-?([0-9\.])+,( )?-?([0-9\.])+/)
          loc_text=params[:post][:asset_codes]
          puts loc_text
          loc_arr=loc_text.split(',')
          puts loc_arr
          x1=loc_arr[0].to_f
          y1=loc_arr[1].to_f
          @post.location="POINT(#{x1} #{y1})"
          @post.loc_source='user'
        else
          @post.asset_codes = params[:post][:asset_codes].upcase.delete('{').delete('}').split(',').map(&:strip)
        end
      end

#      @post.site = ''
#      @post.asset_codes.each do |ac|
#        assets = Asset.assets_from_code(ac)
#        @post.site += (assets && (assets.count > 0) ? (assets.first[:name] || '') : '') + ' [' + ac + '] ' + (assets && (assets.count > 0) && assets.first[:asset] ? '{' + assets.first[:asset].maidenhead + '}; ' : '')
#      end
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
          if ENV['RAILS_ENV'] == 'production'
            item.send_emails unless @post.do_not_publish
          else
            Item.send_emails_now(item.id) unless @post.do_not_publish
          end
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
