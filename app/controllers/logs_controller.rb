class LogsController < ApplicationController
#  before_action :signed_in_user, only: [:edit, :update, :editgrid]
skip_before_filter :verify_authenticity_token, :only => [:save]

def show
end

def load

end

def save
    status=200
    data=params[:data]
    id=params[:id]
    ids=[]
    log=Log.find_by_id(params[:id])
    if current_user and (current_user.callsign==log.callsign1.upcase or current_user.is_admin) then
    
     data.each do |row|
      rid=row[0]
      if rid and rid>=1 then
        cle=Contact.find_by_id(rid)
      else
        cle=Contact.new
      end
      if row[2] then 
      cle.time=("%05.2f" % (((row[1]||"").gsub(/\D/,'').to_f)/100)).gsub('.',':')
      cle.callsign1=log.callsign1
      cle.date=log.date
      cle.loc_desc1=log.loc_desc1
      cle.is_qrp1=log.is_qrp1
      cle.power1=log.power1
      cle.is_portable1=log.is_portable1
      cle.timezone=log.timezone
      cle.x1=log.x1 
      cle.y1=log.y1 
      cle.location1=log.location1 
      cle.callsign2=(row[2]||"").upcase
      cle.is_qrp2=row[3]
      cle.is_portable2=row[4]
      cle.mode=row[5]
      cle.frequency=row[6]
      cle.signal2=row[7]
      cle.signal1=row[8]
      cle.name2=row[9]
      cle.loc_desc2=row[10]
      cle.asset1_codes=log.asset_codes
      cle.asset2_codes=row[13]
      cle.location2=row[14]
      cle.x2=row[15]
      cle.y2=row[16]
      cle.log_id=id
      cle.convert_to_utc(current_user)

      if !cle.save then status=500; puts "error" else 
         puts "good"  
      end
      ids << cle.id
      end
     end
     #delete entries not in our post
     @contacts=Contact.where(log_id: id) 
     @contacts.each do |contact|
       if !(ids.include? contact.id)  then contact.destroy end
     end
  else 
     status=401
  end
  @contacts=Contact.where(log_id: id).order(:time)
  @contacts.each do |c|
    c.timetext=c.localtime(current_user)
    asset2_names=[]
    c.asset2_codes.each do |ac|
      a=Asset.find_by(code: ac)
      if a then asset2_names+=["["+a.code+"] "+a.name] else asset2_names+=[ac] end
    end
    c.asset2_names=asset2_names.join("/n")
  end
 
  respond_to do |format|
    format.html
    format.js
    format.json { render json: @contacts, status: status, methods: [:timetext, :asset2_names] }
  end
       
end

def new
  @no_map=true
  if signed_in? then
    @log=Log.new
   # if params[:hut1] then 
   #    @log.hut1_id=params[:hut1].to_i 
   #    @log.park1_id = @log.hut1.park_id
   # end
   # if params[:park1] then @log.park1_id=params[:park1].to_i end
   # if params[:island1] then @log.island1_id=params[:island1].to_i end
   # if params[:summit1] then @log.summit1_id=params[:summit1]
  #     @log.park1_id = @log.summit1.park_id
  #  end

    @log.callsign1=current_user.callsign
    @log.asset_codes=nil
    tz=Timezone.find_by_id(current_user.timezone)
    @log.date=Time.now.in_time_zone(tz.name).to_date.to_s
  else
    redirect_to '/'
  end
end

def editcontact

  @log=nil
  # get log from contact
  @contact=Contact.find_by_id(params[:id])
  if current_user and (current_user.callsign==@contact.callsign1.upcase or current_user.is_admin) then
  if  @contact then
    if @contact.log_id then @log=Log.find_by_id(@contact.log_id) end
    #create log if conact has none
    if !@log then
      #copy matching subset of contact columsn to log
      columns=(Contact.column_names & Log.column_names) - ["id", "createdBy_id", "created_at", "updated_at"]
      @log=Log.new( Contact.first(:select => columns.join(",") ).attributes)
      @log.asset_codes=@contact.asset1_codes
      @log.save
      @contact.log_id=@log.id
      @contact.save
    end
    edit
    render 'edit'
  else
    flash[:error]="Contact not found"
    redirect_to '/'
  end
 else 
   flash[:error]="You are not authorised to edit this contact"
   redirect_to '/'
 end

end

def edit
  
  @no_map=true
  if !@log then @log = Log.find_by_id(params[:id]) end
  if @log and current_user and (current_user.callsign==@log.callsign1.upcase or current_user.is_admin) then
    @user=User.find_by(callsign: @log.callsign1)
    @contacts = Contact.where(log_id: @log.id).order(:time)
    #@contacts = [Contact.first]
    @contacts.each do |c|  
      c.timetext=c.localtime(current_user)
      asset2_names=[]
      c.asset2_codes.each do |ac|
        a=Asset.find_by(code: ac)
        if a then asset2_names+=["["+a.code+"] "+a.name] else asset2_names+=[ac] end
      end      
      c.asset2_names=asset2_names.join("\n")
    
   #     c.hut2_tn=c.hut2_name
   #   c.park2_tn=c.park2_name
   #   c.island2_tn=c.island2_name
   #   c.summit2_tn=c.summit2_name
    end
  else
    flash[:error]="Unable to edit requested log"
    redirect_to '/'
  end  
#  if !@contacts or @contacts.count==0 then @contacts=[ContestLogEntry.new] end
end

def create
  if signed_in?  then
    if params[:commit] then
      @log = Log.new(log_params)
      @log.asset_codes=params[:log][:asset_codes].gsub('{','').gsub('}','').split(',')

      if @log.save then
        @log.reload
        @id=@log.id
        params[:id]=@id
        @user=User.find_by(callsign: @log.callsign1)
        redirect_to '/logs/'+@id.to_s+'/edit'
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

def delete
  if signed_in?  then
   cl=Log.find_by_id(params[:id])
   if cl then 
     if cl.callsign1==current_user.callsign or current_user.is_admin then
       cl.contacts.each do |cle|
         cle.destroy
       end
       cl.destroy
       flash[:success]="Log deleted"
     end
    
     redirect_to '/contacts/'
   end
  else
    redirect_to '/'
  end
end

def update
  if signed_in?  then
    if params[:commit] then
      if !(@log = Log.find_by_id(params[:id]))
          flash[:error] = "Log does not exist: "+@log.id.to_s
          redirect_to '/'
      end
      @log.assign_attributes(log_params)
      @log.asset_codes=params[:log][:asset_codes].gsub('{','').gsub('}','').split(',')

      if @log.save then
        flash[:success] = "Log details updated"
        @user=User.find_by(callsign: @log.callsign1)
        @contacts = Contact.where(log_id: @log.id).order(:time)
        redirect_to '/logs/'+@log.id.to_s+'/edit'
      else
        @user=User.find_by(callsign: @log.callsign1)
        @contacts = Contact.where(log_id: @log.id).order(:time)
        redirect_to '/logs/'+@log.id.to_s+'/edit'
      end
    else
      redirect_to '/'
    end
  else
    redirect_to '/'
  end

end

  def post_notification(contest_log)
    if contest_log and contest_log.contest then
      details=contest_log.callsign+" added a log for "+contest_log.contest.name+"  on "+contest_log.localdate(current_user)

      hp=HotaPost.new
      hp.title=details
      hp.url="qrp.nz/contest_logs/"+contest_log.id.to_s
      hp.save
      hp.reload
      i=Item.new
      i.item_type="hota"
      i.item_id=hp.id
      i.save
    end
  end


private
  def log_params
      params.require(:log).permit(:id, :callsign1, :user1_id, :power1, :signal1, :transceiver1, :antenna1, :comments1, :location1, :park1, :date, :time, :timezone,  :frequency, :mode, :loc_desc1,:x1, :y1, :altitude1, :location1,  :is_active, :hut1_id, :park1_id, :island1_id, :is_qrp1, :is_portable1, :summit1_id, :asset_codes)
end

end
