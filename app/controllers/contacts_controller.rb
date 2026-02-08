
# typed: false
class ContactsController < ApplicationController
  before_action :signed_in_user, only: %i[edit update create new refute confirm]

  def index_prep
    whereclause = 'true'
    # orphan contacts
    @orphans = params[:orphans] ? true : false

    @zlota_logs=true if params[:zlota_logs]=='true'
    @download=true if params[:download]=='true'

    # everything else!
    if params[:filter]
      @filter = params[:filter]
      whereclause = 'is_' + @filter + ' is true'
    end

    if params[:user] && params[:user].casecmp('ALL').zero?
      @callsign = 'ALL'
    else
      if params[:user] && !params[:user].empty?
#        @user = User.find_by(callsign: params[:user].upcase)
        @user = User.find_by_callsign_date(params[:user].upcase, Time.now())
        @callsign = params[:user].upcase
      else
        @user=current_user
      end
      #fallback of last resort
      @user ||= User.first
      @callsign ||= @user.callsign
    end

    #QRP
    whereclause += ' and is_qrp1=true and is_qrp2=true' if params[:contact_qrp]

    if params[:date] && !params[:date].empty?
      whereclause = whereclause + " and (date = '#{params[:date]}')"
    end

    if params[:asset] && !params[:asset].empty?
      whereclause = whereclause + " and ('" + params[:asset].tr('_', '/') + "'=ANY(asset1_codes) or '" + params[:asset].tr('_', '/') + "'=ANY(asset2_codes))"
      @asset = Asset.find_by(safecode: params[:asset].upcase)
      @assetcode = @asset.code if @asset
    elsif params[:whochased] && !params[:whochased].empty?
      @whochased=true
      whereclause = whereclause + " and ('" + params[:whochased].tr('_', '/') + "'=ANY(asset2_codes) and (callsign2='" + @callsign + "'))"
    elsif  params[:class] && (params[:class] != 'all')
      @class=params[:class]
      asset_type=AssetType.find_by(name: @class)
      if asset_type then
        class_prefix=asset_type.like_pattern
      else 
        class_prefix='%'
      end
      if params[:activator]
        our_call_field1 = 'callsign1'
        our_call_field2 = 'callsign2'
        whereclause = whereclause + " and ('" + @class + "'=ANY(asset1_classes)) and (callsign1='" + @callsign + "')"
        @activator = 'on'
        @count_type="activator"
      elsif params[:chaser]
        our_call_field1 = 'callsign2'
        our_call_field2 = 'callsign1'
        whereclause = whereclause + " and ((('" + @class + "'=ANY(asset2_classes)) and (callsign1='" + @callsign + "')) or (('" + @class + "'=ANY(asset1_classes)) and (callsign2='" + @callsign + "')))"
        @chaser = 'on'
        @count_type="chaser"
      else
        whereclause = whereclause + " and (callsign1='" + @callsign + "') and (('" + params[:class] + "'=ANY(asset1_classes)) or ('" + params[:class] + "'=ANY(asset2_classes)))"
      end
    elsif @callsign != 'ALL'
      whereclause = whereclause + " and (callsign1='" + @callsign + "' or callsign2='" + @callsign + "')"
    end

    if @orphans then 
      @fullcontacts = @user.orphan_activations 
    else
      @fullcontacts = Contact.find_by_sql ['select * from contacts where ' + whereclause + ' order by date desc, time desc']
    end
    if @zlota_logs==true and ((!params[:chaser] and !params[:activator]) or (params[:chaser] and params[:activator]) or !@class) then
      flash[:success]="Please select a class, and specify either chaser or activator logs"
      @fullcontacts=nil
    end
    if @zlota_logs==true and @download==true and @callsign and @callsign!='ALL' and @class and (params[:chaser] or params[:activator]) then
      #filter for only this programme
      cs1 = Contact.find_by_sql ["select c.*, a.name as my_ref_name from (select id, date, time, frequency, band, mode, callsign1, callsign2, power1, signal1, comments1, loc_desc1, location1, is_qrp1, is_portable1, name1, power2, signal2, comments2, loc_desc2, location2, is_qrp2, is_portable2, name2, unnest(asset1_codes) as my_reference, asset1_codes, asset2_codes from contacts where id in (?) and #{our_call_field1} = ?) as c left join assets a on a.code = c.my_reference where my_reference like '#{class_prefix}'",@fullcontacts.map{|c| c.id}, @callsign]
      cs2 = Contact.find_by_sql ["select c.*, a.name as my_ref_name from (select id, date, time, frequency, band, mode, callsign1, callsign2, power1, signal1, comments1, loc_desc1, location1, is_qrp1, is_portable1, name1, power2, signal2, comments2, loc_desc2, location2, is_qrp2, is_portable2, name2, unnest(asset2_codes) as my_reference, asset1_codes, asset2_codes from contacts c where id in (?) and #{our_call_field2} = ?) as c left join assets a on a.code = c.my_reference where my_reference like '#{class_prefix}'",@fullcontacts.map{|c| c.id}, @callsign]
#      cs2 = Contact.find_by_sql ["select * from (select date, time, frequency, band, callsign2 as callsign1, callsign1 as callsign2, power2 as power1, signal2 as signal1, comments2 as comments1, loc_desc2 as loc_desc1, location2 as location1, is_qrp2 as is_qrp1, is_portable2 as is_portable1, name2 as name1, power1 as power2, signal1 as signal2, comments1 as comments2, loc_desc1 as loc_desc2, location1 as location2, is_qrp1 as is_qrp2, is_portable1 as is_portable2, name1 as name2, unnest(asset2_codes) as asset1_code, asset2_codes as asset1_codes, asset1_codes as asset2_codes from contacts where id in (?) and #{our_call_field2} = ?) as foo where asset1_code like '#{class_prefix}'",@fullcontacts.map{|c| c.id}, @callsign]
       @fullcontacts = cs1 + cs2 
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
        spot = ConsolidatedSpot.find(spotid)
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
    if @zlota_logs then
      items.sort_by!{ |i| i.my_reference+i.time.to_s }
    end
    if signed_in?
      require 'csv'
      csvtext = ''
      if items && items.first
        if params[:simple] == 'true'
          if @zlota_logs then
            columns = %w[id time callsign1 callsign2 my_reference my_ref_name frequency mode signal1 signal2 asset1_codes asset2_codes]
          else
            columns = %w[id time callsign1 callsign2 frequency mode signal1 signal2 asset1_codes asset2_codes]
          end
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
