# frozen_string_literal: true

# typed: false
class ContactsController < ApplicationController
  before_action :signed_in_user, only: %i[edit update create new]

  def index_prep
    whereclause = 'true'
    # orphan contacts
    @orphans = params[:orphans] ? true : false

    # everything else!
    if params[:filter]
      @filter = params[:filter]
      whereclause = 'is_' + @filter + ' is true'
    end
    whereclause += ' and is_qrp1=true and is_qrp2=true' if params[:contact_qrp]
    if params[:class] && (params[:class] != 'all')
      if params[:activator]
        whereclause = whereclause + " and ('" + params[:class] + "'=ANY(asset1_classes))"
        @activator = 'on'
      elsif params[:chaser]
        whereclause = whereclause + " and ('" + params[:class] + "'=ANY(asset2_classes))"
        @chaser = 'on'
      else
        whereclause = whereclause + " and ('" + params[:class] + "'=ANY(asset1_classes) or '" + params[:class] + "'=ANY(asset2_classes))"
      end
    end
    if params[:user] && !params[:user].empty?
      if params[:user].casecmp('ALL').zero?
        @callsign = 'ALL'
      else
        whereclause = whereclause + " and (callsign1='" + params[:user].upcase + "' or callsign2='" + params[:user].upcase + "')"
        @user = User.find_by(callsign: params[:user])
        @user ||= current_user
        @user ||= User.first
        @callsign = params[:user].upcase
      end
    elsif current_user
      whereclause = whereclause + " and (user1_id='" + current_user.id.to_s + "' or user2_id='" + current_user.id.to_s + "')"
      @user = current_user
      @callsign = @user.callsign
    end
    if params[:asset] && !params[:asset].empty?
      whereclause = whereclause + " and ('" + params[:asset].tr('_', '/') + "'=ANY(asset1_codes) or '" + params[:asset].tr('_', '/') + "'=ANY(asset2_codes))"
      @asset = Asset.find_by(code: params[:asset].upcase)
      @assetcode = @asset.code if @asset
    end
    @fullcontacts = if !@orphans
                      Contact.find_by_sql ['select * from contacts where ' + whereclause + ' order by date desc, time desc']
                    else
                      @user.orphan_activations
                    end

    # back compatibility
    params[:class] = params[:type] if params[:type]

    if params[:class] && (params[:class] != 'all')
      @class = params[:class]
      as = []
      cs = []
      @fullcontacts.each do |contact|
        contact = contact.reverse if contact.callsign2 == @user.callsign
        assets = Asset.assets_from_code(contact.asset1_codes.join(','))
        assets.each do |a|
          if a[:asset] && (a[:type] == @class)
            contact.asset1_codes = [a[:code]]
            as.push(contact)
          end
        end
        assets = Asset.assets_from_code(contact.asset2_codes.join(','))
        assets.each do |a|
          if a[:asset] && (a[:type] == @class)
            contact.asset2_codes = [a[:code]]
            cs.push(contact)
          end
        end
      end
      if params[:activator]
        @fullcontacts = as
        @activator = 'on'
      elsif params[:chaser]
        @fullcontacts = cs
        @chaser = 'on'
      else
        @fullcontacts = cs + as
      end
      @fullcontacts = @fullcontacts.uniq
    end

    @page_len = params[:pagelen] ? params[:pagelen].to_i : 20

    if params[:user_qrp] && (params[:user] || signed_in?)
      callsign = params[:user] ? params[:user].upcase : current_user.callsign.upcase
      cs = []

      @fullcontacts.each do |contact|
        if ((contact.callsign1.upcase == callsign) && contact.is_qrp1) ||
           ((contact.callsign2.upcase == callsign) && contact.is_qrp2)
          cs.push(contact)
        end
      end
      @fullcontacts = cs
    end
    @contacts = (@fullcontacts || []).paginate(per_page: @page_len, page: params[:page])
  end

  def new
    @contact = Contact.new
    if params[:spot]
      spotid = params[:spot].to_i
      if spotid > 0
        spot = ExternalSpot.find(spotid)
        if spot
          @contact.callsign2 = spot.activatorCallsign
          @contact.date = Time.now.in_time_zone('UTC').at_beginning_of_minute
          @contact.time = Time.now.in_time_zone('UTC').at_beginning_of_minute
          @contact.frequency = spot.frequency
          @contact.mode = spot.mode
          @contact.asset2_codes = [spot.code]
        end
      else
        spot = Post.find(-spotid)
        if spot
          @contact.callsign2 = spot.callsign
          @contact.date = Time.now.in_time_zone('UTC').at_beginning_of_minute
          @contact.time = Time.now.in_time_zone('UTC').at_beginning_of_minute
          @contact.frequency = spot.freq
          @contact.mode = spot.mode
          @contact.asset2_codes = spot.asset_codes
        end
      end
    end
    @contact.callsign1 = current_user.callsign
  end

  def create
    if signed_in?
      if params[:commit]
        @contact = Contact.new(contact_params)
        puts ':' + params[:contact][:asset2_codes] + ':'
        @contact.asset2_codes = params[:contact][:asset2_codes].delete('[').delete(']').delete('"').split(',')
        @contact.createdBy_id = current_user.id
        @log = @contact.create_log
        @log.save
        @contact.log_id = @log.id
        if @contact.save
          @contact.reload
          @id = @contact.id
          params[:id] = @contact
          @user = User.find_by_callsign_date(@contact.callsign1.upcase, @contact.date)
          redirect_to '/spots'
        else
          render 'new'
        end
      else
        redirect_to '/'
      end
    else
      redirect_to '/'
    end
  end

  def index
    index_prep
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data contacts_to_csv(@fullcontacts), filename: "contacts-#{Date.today}.csv" }
    end
  end

  def show
    redirect_to '/' unless (@contact = Contact.find_by_id(params[:id].to_i.abs))
  end

  def refute
    unless (contact = Contact.find_by_id(params[:id].to_i.abs))
      redirect_to '/'
    end
    if current_user && ((current_user.id == contact.user2_id) || current_user.is_admin)
      contact.refute_chaser_contact
      flash[:success] = 'Your location details for this contact have been updated'
    else
      flash[:error] = 'You do not have permissions to refute this contact'
    end
    params[:orphans] = true
    params[:user] = contact.callsign2
    index_prep
    render 'index'
  end

  def confirm
    unless (contact = Contact.find_by_id(params[:id].to_i.abs))
      redirect_to '/'
    end
    if current_user && ((current_user.id == contact.user2_id) || current_user.is_admin)
      contact.confirm_chaser_contact
      flash[:success] = 'New activator log entry added for this contact'
    else
      flash[:error] = 'You do not have permissions to confirm this contact'
    end
    params[:orphans] = true
    params[:user] = contact.callsign2
    index_prep
    render 'index'
  end

  def contacts_to_csv(items)
    if signed_in?
      require 'csv'
      csvtext = ''
      if items && items.first
        if params[:simple] == 'true'
          columns = %w[id time callsign1 asset1_codes callsign2 asset2_codes frequency mode]
        else
          columns = []; items.first.attributes.each_pair { |name, _value| if !name.include?('password') && !name.include?('digest') && !name.include?('token') then columns << name end }
          columns += %w[place_codes1 place_codes2]
        end
        csvtext << columns.to_csv
        items.each do |item|
          if params[:simple] == 'true'
            fields = []; columns.each { |column| fields << item[column] }
          else
            fields = []; item.attributes.each_pair { |name, value| if !name.include?('password') && !name.include?('digest') && !name.include?('token') then fields << value end }
            fields += [item.asset1_codes, item.asset2_codes]

          end
          csvtext << fields.to_csv
        end
     end
      csvtext
   end
  end

  private

  def contact_params
    params.require(:contact).permit(:id, :callsign1, :user1_id, :power1, :signal1, :transceiver1, :antenna1, :comments1, :location1, :park1, :callsign2, :user2_id, :power2, :signal2, :transceiver2, :antenna2, :comments2, :hut2, :park2, :date, :time, :timezone, :frequency, :mode, :loc_desc1, :loc_desc2, :x1, :y1, :altitude1, :location1, :x2, :y2, :altitude2, :location2, :is_active, :hut1_id, :hut2_id, :park1_id, :park2_id, :island1_id, :island2_id, :is_qrp1, :is_qrp2, :is_portable1, :is_portable2, :summit1_id, :summit2_id, :asset2_codes)
  end

  def post_notification(contact)
    if contact
      details1 = contact.location1_text
      details2 = contact.location2_text
      details1 = '...' if !details1 || (details1.length < 2)
      details2 = '...' if !details2 || (details2.length < 2)
      details = contact.callsign1 + ' and ' + contact.callsign2 + ' logged a contact between ' + details1 + ' and ' + details2 + ' on ' + contact.localdate(current_user)

      hp = HotaPost.new
      hp.title = details
      hp.url = 'ontheair.nz/contacts/' + contact.id.to_s
      hp.save
      hp.reload
      i = Item.new
      i.item_type = 'hota'
      i.item_id = hp.id
      i.save
    end
  end

  def convert_location_params1
    if @contact.x1 && @contact.y1

      # convert to WGS84 (EPSG4326) for database
      fromproj4s = Projection.find_by_id(2193).proj4
      toproj4s = Projection.find_by_id(4326).proj4

      fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
      toproj = RGeo::CoordSys::Proj4.new(toproj4s)

      xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, @contact.x1, @contact.y1)

      params[:location1] = xyarr[0].to_s + ' ' + xyarr[1].to_s
      @contact.location1 = 'POINT(' + params[:location1] + ')'

    else
      @contact.location1 = nil
     end
  end

  def convert_location_params2
    if @contact.x2 && @contact.y2

      # convert to WGS84 (EPSG4326) for database
      fromproj4s = Projection.find_by_id(2193).proj4
      toproj4s = Projection.find_by_id(4326).proj4

      fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
      toproj = RGeo::CoordSys::Proj4.new(toproj4s)

      xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, @contact.x2, @contact.y2)

      params[:location2] = xyarr[0].to_s + ' ' + xyarr[1].to_s
      @contact.location2 = 'POINT(' + params[:location2] + ')'

    else
      @contact.location2 = nil
     end
  end
end
