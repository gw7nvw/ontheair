# frozen_string_literal: true

# typed: false
class UsersController < ApplicationController
  include ApplicationHelper

  before_action :signed_in_user, only: %i[edit update editgrid district_progress region_progress awards assets p2p]

  def district_progress
    @user = User.find_by(callsign: params[:id].upcase)
    @activations = @user.area_activations('district')
    @chases = @user.area_chases('district')
    @award_classes = AssetType.where("name != 'all' and name !='pota park' and name!='wwff park' and name!='lighthouse'").order(:name)
    @district_assets = District.get_assets_with_type
    @districts = District.all.order(:region_code, :name)
  end

  def region_progress
    @user = User.find_by(callsign: params[:id].upcase)
    @activations = @user.area_activations('region')
    @chases = @user.area_chases('region')
    @award_classes = AssetType.where("name != 'all'").order(:name)
    @region_assets = Region.get_assets_with_type
    @regions = Region.all.order(:name)
  end

  def awards
    @user = User.find_by(callsign: params[:id].upcase)
    @awards = Award.where(count_based: true, is_active: true).sort_by &:name
    @district_awards = AwardUserLink.where(award_type: 'district', user_id: @user.id).sort_by { |a| a.district.name }
    @region_awards = AwardUserLink.where(award_type: 'region', user_id: @user.id).sort_by { |a| a.region.name }
    @districts = District.get_assets_with_type
    @regions = Region.get_assets_with_type
  end

  def assets
    @user = User.find_by(callsign: params[:id].upcase)
    @count_type = safe_param(params[:count_type])
    @asset_type = safe_param(params[:asset_type])

    # include all summit types
    if @asset_type == 'summit'
      @asset_codes = []
      @valid_codes = []
      ats = AssetType.where(has_elevation: true)
      ats.each do |at|
        include_external = at.name == 'summit'
        @asset_codes += @user.assets_by_type(at.name, @count_type, true)

        # filter by min qso requirements
        if @count_type == 'activated'
          @valid_codes += @user.qualified(asset_type: at.name, include_external: include_external)
        else
          @valid_codes = @asset_codes
        end
      end
    else
      @asset_codes = @user.assets_by_type(@asset_type, @count_type, true)

      # filter by min qso requirements
      @valid_codes = if @count_type == 'activated'
                       @user.qualified(asset_type: @asset_type)
                     else
                       @asset_codes
                     end
    end

    @assets = Asset.find_by_sql [' select asset_type, minor, is_active, id, name, code, altitude from assets where code in (?) ', @asset_codes]
  end

  def p2p
    @user = User.find_by(callsign: params[:id].upcase)
    @contacts = @user.get_p2p_all
  end

  def index_prep
    whereclause = 'true'
    if params[:filter]
      @filter = safe_param(params[:filter])
      whereclause = 'is_' + @filter + ' is true'
    end

    @searchtext = safe_param(params[:searchtext] || '')
    if params[:searchtext] && (params[:searchtext] != '')
      whereclause = whereclause + " and (lower(callsign) like '%%" + @searchtext.downcase + "%%' )"
    end

    @fullusers = User.find_by_sql ['select * from users where ' + whereclause + ' order by callsign']
    @users = @fullusers.paginate(per_page: 40, page: params[:page])
  end

  def index
    index_prep
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data users_to_csv(@fullusers), filename: "users-#{Date.today}.csv" }
    end
  end

  def show
    users = User.find_by_sql ["select * from users where callsign='#{params[:id]}' or id=#{params[:id].to_i}"]
    if !users || (users.count < 1)
      users = UserCallsign.where(callsign: params[:id])
      if users && (users.count > 0)
        user = users.first.user
        if user
          redirect_to '/users/' + user.callsign
        else
          flash[:error] = 'Callsign ' + params[:id] + ' not found'
          redirect_to '/'
        end
      else
        flash[:error] = 'Callsign ' + params[:id] + ' not found'
        redirect_to '/'
      end
    elsif users && (users.count > 0)
      @user = users.first
      activationSites = []
      qualifySites = []
      asset_types = AssetType.where("name != 'all'")
      asset_types.each do |at|
        activationSite = @user.activations(asset_type: at.name)
        qualifySites += @user.qualified(asset_type: at.name)
        activationSites += activationSite
      end
      chaseSites = @user.chased
      activationSites -= qualifySites
      @chaseSites = Asset.find_by_sql [' select location from assets where code in (?); ', chaseSites]
      @activationSites = Asset.find_by_sql [' select location from assets where code in (?);', activationSites]
      @qualifySites = Asset.find_by_sql [' select location from assets where code in (?);', qualifySites]
      @callsign = UserCallsign.new
      @callsign.user_id = @user.id
    end
  end

  def new
    @user = User.new
    @user.timezone = Timezone.find_by(name: 'UTC').id
  end

  def create
    password = params[:user][:password]
    password_confirmation = params[:user][:password_confirmation]

    user = User.new(user_params)
    user.password = password
    user.password_confirmation = password_confirmation

    user.callsign = user.callsign.strip
    existing_user = User.find_by(callsign: user.callsign.upcase)

    # register an auto_created user
    @user = if existing_user && !existing_user.activated
              existing_user
            else
              user
            end
    @user.callsign = user.callsign
    @user.firstname = user.firstname.strip
    @user.lastname = user.lastname.strip
    @user.email = user.email.strip
    @user.activated = true
    @user.is_active = true
    @user.is_modifier = false
    @user.activated_at = Time.now
    @user.hide_news_at = Time.now

    @user.read_only = true unless @user.valid_callsign?

    if @user.save
      @user.reload
      sign_in @user

      flash[:success] = if @user.read_only
                          'Welcome to ZL on the Air. Your account has been created as a restricted, non-amatuer user. Contact admin@ontheair if you expected full access'
                        else
                          'Welcome to ZL On the Air'
                        end

      redirect_to '/users/' + @user.callsign
    else
      render 'new'
    end
  end

  def edit
    @referring = params[:referring] if params[:referring]
    @user ||= User.where(callsign: params[:id]).first

    if signed_in? && (current_user.is_admin || (current_user.callsign == params[:id]))
      # edit
    else
      render 'show'
    end
  end

  def update
    if signed_in? && (current_user.is_admin || (current_user.id == params[:id].to_i))
      if params[:delete] == 'Delete'
        callsigns = UserCallsign.where(user_id: params[:id].to_i)
        callsigns.each(&:destroy)
        topics = UserTopicLink.where(user_id: params[:id].to_i)
        topics.each(&:destroy)
        user = User.find_by_id(params[:id].to_i)
        if user && user.destroy
          flash[:success] = 'User deleted, callsign:' + params[:id]
          index_prep
          render 'index'
        else
          edit
          render 'edit'
        end
      else
        password = params[:user][:password]
        password_confirmation = params[:user][:password_confirmation]

        @user = User.find_by_id(params[:id].to_i)

        @user.assign_attributes(user_params)
        if password && !password.empty?
          @user.password = password
          @user.password_confirmation = password_confirmation
        end

        if @user
          @user.firstname = @user.firstname.strip if @user.firstname
          @user.lastname = @user.lastname.strip if @user.lastname
          @user.callsign = @user.callsign.strip
          @user.email = @user.email.strip if @user.email

          # only allow us to change own password unless we are admin
          if (@user.id != current_user.id) && !current_user.is_admin
            @user.password = nil
            @user.password_confirmation = nil
          end

          if @user.save
            flash[:success] = 'User details updated'

            # Handle a successful update.
            if params[:referring] == 'index'
              index_prep
              render 'index'
            else
              show
              render 'show'
            end
          else
            @referring = params[:referring] if params[:referring]
            render 'edit'
          end
        end
      end
    else
      redirect_to '/'
    end
  end

  # Add a user-topic-link (mailer)
  def add
    @user = current_user
    if current_user && current_user.is_admin || current_user.group_admin then @user = User.where(callsign: params[:id]).first end
    @topic = Topic.find_by_id(params[:topic_id])

    if @user && @topic
      utl = UserTopicLink.new
      utl.user_id = @user.id
      utl.topic_id = @topic.id
      utl.mail = true if params[:method] == 'mail'
      utl.notification = true if params[:method] == 'notification'
      utl.save
    else
      flash[:error] = 'Error locating user or topic specified'
    end
    @topics = Topic.where(is_active = true)
    show
    render 'show'
  end

  # Delete a user-topic-link (mailer)
  def delete
    @user = current_user
    if current_user && current_user.is_admin then @user = User.where(callsign: params[:id]).first end
    @topic = Topic.find_by_id(params[:topic_id])

    if @user && @topic
      utls = UserTopicLink.find_by_sql ['select * from user_topic_links where user_id=' + @user.id.to_s + ' and topic_id=' + @topic.id.to_s + " and #{params[:method]} = true"]
      utls.each(&:destroy)
    else
      flash[:error] = 'Error locating user or topic specified'
    end
    @topics = Topic.where(is_active = true)
    show
    render 'show'
  end

  def users_to_csv(items)
    if signed_in? && current_user.is_admin
      require 'csv'
      csvtext = ''
      if items && items.first
        columns = []; items.first.attributes.each_pair { |name, _value| if !name.include?('password') && !name.include?('digest') && !name.include?('token') then columns << name end }
        csvtext << columns.to_csv
        items.each do |item|
          fields = []; item.attributes.each_pair { |name, value| if !name.include?('password') && !name.include?('digest') && !name.include?('token') then fields << value end }
          csvtext << fields.to_csv
        end
     end
      csvtext
   end
  end

  private

  def user_params
    params.require(:user).permit(:callsign, :firstname, :lastname, :email, :timezone, :home_qth, :pin, :acctnumber, :logs_pota, :logs_wwff, :push_app_token, :push_user_token)
  end
end
