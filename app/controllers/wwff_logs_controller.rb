class WwffLogsController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :send_email]

def index
    @parameters=params_to_query

  callsign=""
  if current_user then callsign=current_user.callsign end
  if params[:user] then callsign=params[:user].upcase end
  users=User.where(callsign: callsign)
  if users then @user=users.first end
  if !@user then
   flash[:error]="User "+callsign+" does not exist"
   redirect_to '/'
  end
end

def show
    @parameters=params_to_query
  if current_user then callsign=current_user.callsign else callsign="" end 
  if params[:user] then callsign=params[:user].upcase end
  if current_user and (current_user.is_admin or current_user.callsign==callsign) then
    users=User.where(callsign: callsign)
    if users then @user=users.first end
    if !@user then
     flash[:error]="User "+callsign+" does not exist"
     redirect_to '/'
    end

    pls=@user.wwff_logs
    wwff_log=nil
    pls.each do |pl|
      if pl[:park][:wwffpark]==params[:id]  then wwff_log=pl end
    end 
  
    park=Asset.find_by(code: params[:id])
  
    @wwff_log=""
    @invalid_contacts=[]
    @contacts=wwff_log[:contacts]
    wwff_log[:contacts].each do |contact|
      other_park=nil
      other_callsign=contact.callsign2
      if pp=contact.find_asset2_by_type('wwff park') then
        other_park_code=pp.code
      elsif p=contact.find_asset2_by_type('park') then
        las=p.linked_assets_by_type('wwff park')
        if las and las.count>0 then other_park_code=las.first.code end
      end

      if contact.band.length>0 and contact.adif_mode.length>0 and contact.time and contact.time.strftime("%H%M").length==4 then
        @wwff_log+="<call:"+other_callsign.length.to_s+">"+other_callsign
        @wwff_log+="<station_callsign:"+@user.callsign.length.to_s+">"+@user.callsign
        @wwff_log+="<operator:"+@user.callsign.length.to_s+">"+@user.callsign
        @wwff_log+="<band:"+contact.band.length.to_s+">"+contact.band
        @wwff_log+="<mode:"+contact.adif_mode.length.to_s+">"+contact.adif_mode
        @wwff_log+="<qso_date:8>"+contact.date.strftime("%Y%m%d")
        @wwff_log+="<time_on:4>"+contact.time.strftime("%H%M")
        @wwff_log+="<my_sig:4>WWFF"
        @wwff_log+="<my_sig_info:"+park.code.length.to_s+">"+park.code
        if other_park_code then @wwff_log+="<sig:4>WWFF" end
        if other_park_code then @wwff_log+="<sig_info:"+other_park_code.length.to_s+">"+other_park_code end
        @wwff_log+="<eor>\n"
      else 
        @invalid_contacts.push(contact)
      end
    end
    @filename=@user.callsign+"@"+park.code+".adi" 
    callnumber=@user.callsign.gsub(/[^0-9]/, '').first 
    @address=""
    if callnumber then 
      @address="k.duffy@xtra.co.nz"
    end
    @logdate=params[:date]
    @park=park
  else 
    flash[:error]="You must log in to submit logs"
    redirect_to '/'
  end
end  
def send_email
  if current_user then callsign=current_user.callsign else callsign="" end 
  if params[:user] then callsign=params[:user].upcase end
  if current_user and (current_user.is_admin or current_user.callsign==callsign) then
      show
      # Sends activation email.
      #UserMailer.wwff_log_submission(@user,@park,@filename,@wwff_log,@address).deliver
      UserMailer.wwff_log_submission(@user,@park,@filename,@wwff_log,@address).deliver
      @contacts.each do |contact|
        contact.submitted_to_wwff=true
        contact.save
      end
 
      flash[:success]="Your log has been sent"
      redirect_to "/wwff_logs"
    else
      flash[:error]="You must log in to submit logs"
      redirect_to '/'
    end
end
end
