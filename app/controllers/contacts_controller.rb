# frozen_string_literal: true

# typed: false
class ContactsController < ApplicationController
  before_action :signed_in_user, only: %i[edit update create new refute confirm]

  def index_prep
    whereclause = 'true'
    # orphan contacts
    @orphans = params[:orphans] ? true : false

    # everything else!
    if params[:filter]
      @filter = params[:filter]
      whereclause = 'is_' + @filter + ' is true'
    end

    if params[:user] && params[:user].casecmp('ALL').zero?
      @callsign = 'ALL'
    else
      if params[:user] && !params[:user].empty?
        @user = User.find_by(callsign: params[:user].upcase)
      else
        @user=current_user
      end
      #fallback of last resort
      @user ||= User.first
      @callsign = @user.callsign
    end

    #QRP
    whereclause += ' and is_qrp1=true and is_qrp2=true' if params[:contact_qrp]

    #All of class for this user's logs
    if params[:class] && (params[:class] != 'all')
      @class=params[:class]
      if params[:activator]
        whereclause = whereclause + " and ('" + @class + "'=ANY(asset1_classes)) and (callsign1='" + @callsign + "')"
        @activator = 'on'
      elsif params[:chaser]
        whereclause = whereclause + " and ('" + @class + "'=ANY(asset2_classes)) and (callsign1='" + @callsign + "')"
        @chaser = 'on'
      else
        whereclause = whereclause + " and (callsign1='" + @callsign + "') and (('" + params[:class] + "'=ANY(asset1_classes)) or ('" + params[:class] + "'=ANY(asset2_classes)))"
      end
    elsif @callsign != 'ALL'
      whereclause = whereclause + " and (callsign1='" + @callsign + "' or callsign2='" + @callsign + "')"
    end

    if params[:asset] && !params[:asset].empty?
      whereclause = whereclause + " and ('" + params[:asset].tr('_', '/') + "'=ANY(asset1_codes) or '" + params[:asset].tr('_', '/') + "'=ANY(asset2_codes))"
      @asset = Asset.find_by(safecode: params[:asset].upcase)
      @assetcode = @asset.code if @asset
    end

    if @orphans then 
      @fullcontacts = @user.orphan_activations 
    else
      @fullcontacts = Contact.find_by_sql ['select * from contacts where ' + whereclause + ' order by date desc, time desc']
    end

    @page_len = params[:pagelen] ? params[:pagelen].to_i : 20

    if params[:user_qrp] && @callsign
      cs = []

      @fullcontacts.each do |contact|
        if ((contact.callsign1.upcase == @callsign) && contact.is_qrp1) ||
           ((contact.callsign2.upcase == @callsign) && contact.is_qrp2)
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
          @contact.asset2_codes = spot.code
        end
      else
        spot = Post.find(-spotid)
        if spot
          @contact.callsign2 = spot.callsign
          @contact.date = Time.now.in_time_zone('UTC').at_beginning_of_minute
          @contact.time = Time.now.in_time_zone('UTC').at_beginning_of_minute
          @contact.frequency = spot.freq
          @contact.mode = spot.mode
          @contact.asset2_codes = spot.asset_codes.join(',')
        end
      end
    end
    @contact.callsign1 = current_user.callsign
  end

  def create
    @contact = Contact.new(contact_params)
    if signed_in?
      user = User.find_by_callsign_date(@contact.callsign1.upcase, @contact.date)
      if (user.id === current_user.id) || current_user.is_admin
        @contact.asset2_codes = params[:contact][:asset2_codes].delete('[').delete(']').delete('"').split(',')
        @contact.createdBy_id = current_user.id
        @log = @contact.create_log
        @log.save
        @contact.log_id = @log.id
        if @contact.save
          flash[:success]="Success!"
          redirect_to '/spots'
        else
          flash[:error]="Failed to save contact"
          render 'new'
        end
      else
        @contact.errors[:callsign1]="You do not have permission to use this callsign on this date"
        render 'new'
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
      return
    end
    if current_user && ((current_user.id == contact.user2_id) || current_user.is_admin)
      contact.refute_chaser_contact
      flash.now[:success] = 'Your location details for this contact have been updated'
    else
      flash[:error] = 'You do not have permissions to refute this contact'
    end
    redirect_to "/contacts/?user=#{contact.callsign2}&orphans=true"
  end

  def confirm
    unless (contact = Contact.find_by_id(params[:id].to_i.abs))
      flash[:error] = 'Contact not found'
      redirect_to '/'
      return
    end
    if current_user && ((current_user.id == contact.user2_id) || current_user.is_admin)
      contact.confirm_chaser_contact
      flash[:success] = 'New activator log entry added for this contact'
    else
      flash[:error] = 'You do not have permissions to confirm this contact'
    end
    redirect_to "/contacts/?user=#{contact.callsign2}&orphans=true"
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
