class WwffLogsController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :send_email]

def index
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
      if pl[:park].id==params[:id].to_i  then wwff_log=pl end
    end 
  
    park=Park.find_by(id: params[:id].to_i)
  
    @wwff_log=""
    @invalid_contacts=[]
    @contacts=wwff_log[:contacts]
    wwff_log[:contacts].each do |contact|
      other_park=nil
      if contact.callsign1==@user.callsign then other_callsign=contact.callsign2 else other_callsign=contact.callsign1 end
      if contact.park1 and contact.park1.id==park.id then
        if contact.park2 and contact.park2.wwff_park then 
          other_park=contact.park2
        end
      else
        if contact.park1 and contact.park1.wwff_park then 
          other_park=contact.park1
        end
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
        @wwff_log+="<my_sig_info:"+park.wwff_park.code.length.to_s+">"+park.wwff_park.code
        if other_park then @wwff_log+="<sig:4>WWFF" end
        if other_park then @wwff_log+="<sig_info:"+other_park.wwff_park.code.length.to_s+">"+other_park.wwff_park.code end
        @wwff_log+="<eor>\n"
      else 
        @invalid_contacts.push(contact)
      end
    end
    @filename=@user.callsign+"@"+park.wwff_park.code+".adi" 
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
