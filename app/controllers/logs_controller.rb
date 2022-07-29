class LogsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :create, :new, :upload]

skip_before_filter :verify_authenticity_token, :only => [:save, :savefile]

def show
  @log=Log.find_by_id(params[:id])
  if !@log then 
     redirect_to '/logs'
  end
  @parameters=params_to_query

end

def load

end

def upload
    @upload = Upload.new
    @upload.doc_callsign=current_user.callsign
end

def savefile
    @upload = Upload.new(upload_params)

    #get callsign from form
    if params[:upload][:doc_callsign] then
      puts "Got callsign: "+params[:upload][:doc_callsign]
      callsign=params[:upload][:doc_callsign]
    end
    if current_user.is_admin and params[:callsign] then 
      user=User.find_by(callsign: params[:callsign].upcase)
    else
      user=current_user
    end
    if !callsign then callsign=user.callsign end

    success=@upload.save


    if success then
      logfile=File.read(@upload.doc.path)
      results=Log.import(logfile, user, callsign, params[:upload][:doc_no_create]=="1", params[:upload][:doc_ignore_error]=="1")
      logs=results[:logs]
      errors=results[:errors]
      success=results[:success]
      if errors and errors.count>0 then
        @errors=errors
        puts errors.join('\n')
      end
      if success==false and params[:upload][:doc_ignore_error]!="1" then
        @upload = Upload.new
        render 'upload'
        return
      end

      if results[:good_logs]>0 and logs and logs.count>0 then
        lc=0
        while !logs[lc].id and lc<logs.count do
          lc+=1
        end
        @log=logs[lc]
        flash[:success]="Uploaded "+results[:good_contacts].to_s+" contact(s) into "+results[:good_logs].to_s+" logs. Showing first log" 
        redirect_to '/logs/'+@log.id.to_s
      else  
         @upload = Upload.new
         flash[:error]=logs.map{|log| log.errors.full_messages.join(',')}.join(',')
         render 'upload'
         return
      end
    else
      flash[:error]="Error creating file - "+@upload.errors.full_messages.join(',')
      render 'upload'
    end

end

def index
  if signed_in? then 
    @callsign=current_user.callsign 
    @user=current_user
  end
  if params[:user] and params[:user].length>0 then 
     if params[:user].upcase=='ALL' then 
       @callsign=nil
     else
       @callsign=params[:user].upcase 
       @user=User.find_by(callsign: @callsign.upcase)
     end
  end
  whereclause="true"
  if params[:asset] and params[:asset].length>0 then 
    whereclause="('#{params[:asset].upcase.gsub('_','/')}' = ANY(asset_codes))"
    @asset=Asset.find_by(code: params[:asset].upcase)
    if @asset then @assetcode=@asset.code end
  end

  if @callsign then @fulllogs=Log.find_by_sql [ "select * from logs where user1_id="+@user.id.to_s+" and "+whereclause+" order by date desc" ]
  else @fulllogs=Log.find_by_sql [ "select * from logs where "+whereclause+" order by date desc" ]
  end
  @logs=@fulllogs.paginate(:per_page => 20, :page => params[:page])
  @parameters=params_to_query

end

def save
    status=200
    data=params[:data]
    id=params[:id]
    ids=[]
    log=Log.find_by_id(params[:id])
    loguser=User.find_by_callsign_date(log.callsign1.upcase,log.date)
    if current_user and (current_user.id==loguser.id or current_user.is_admin) then
    
     data.each do |row|
      rid=row[0]
      if rid and rid>=1 then
        cle=Contact.find_by_id(rid)
      else
        cle=Contact.new
        cle.createdBy_id=current_user.id
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
      if cle.asset1_codes==nil then cle.asset1_codes=[''] end
      cle.asset2_codes=row[13]
      if cle.asset2_codes==nil then cle.asset2_codes=[''] end
      cle.location2=row[14]
      cle.x2=row[15]
      cle.y2=row[16]
      cle.log_id=id
      cle.convert_to_utc(current_user)

      if !cle.save then status=500; puts "error" end
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
  @parameters=params_to_query

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
    @tz=Timezone.find_by_id(current_user.timezone)
    @log.date=Time.now.in_time_zone(@tz.name).to_date.to_s
    @log.timezone=@tz.id
  else
    redirect_to '/'
  end
end

def editcontact

  @log=nil
  # get log from contact
  @contact=Contact.find_by_id(params[:id])
  loguser=User.find_by_callsign_date(@contact.callsign1.upcase,@contact.time)

  if current_user and (current_user.id==loguser.id or current_user.is_admin) then
  if  @contact then
    if @contact.log_id then @log=Log.find_by_id(@contact.log_id) end
    #create log if conact has none
    if !@log then
      #copy matching subset of contact columsn to log
      columns=(Contact.column_names & Log.column_names) - ["id", "createdBy_id", "created_at", "updated_at"]
      @log=Log.new( Contact.first(:select => columns.join(",") ).attributes)
      @log.asset_codes=@contact.asset1_codes
      @log.createdBy_id=current_user.id
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
  if @log then @user=User.find_by_callsign_date(@log.callsign1.upcase,@log.date) end

  if @log and current_user and (current_user.id==@user.id or current_user.is_admin) then
    @contacts = Contact.where(log_id: @log.id).order(:time)
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
      @log.createdBy_id=current_user.id
      if @log.save then
        @log.reload
        @id=@log.id
        params[:id]=@id
        @user=User.find_by_callsign_date(@log.callsign1.upcase,@log.date)
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
     loguser=User.find_by_callsign_date(cl.callsign1.upcase,cl.date)
     if loguser.id==current_user.id or current_user.is_admin then
       cl.contacts.each do |cle|
         cle.destroy
       end
       cl.destroy
       flash[:success]="Log deleted"
     end
    
     redirect_to '/logs/'
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
      loguser=User.find_by_callsign_date(@log.callsign1.upcase,@log.date)
      if loguser.id===current_user.id or current_user.is_admin then
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
        flash[:error]="You do not have permissions to take this action"
        redirect_to '/'
      end
    else
      redirect_to '/'
    end
  else 
    flash[:error]="You do not have permissions to take this action"
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

  def upload_params
    params.require(:upload).permit(:doc)
  end

end
