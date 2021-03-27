class PotaLogsController < ApplicationController
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

    pls=@user.pota_logs
    pota_log=nil
    pls.each do |pl|
      if pl[:park].id==params[:id].to_i and pl[:date].strftime("%Y%m%d")==params[:date] then pota_log=pl end
    end 
  
    park=Park.find_by(id: params[:id].to_i)
  
    @pota_log=""
    @invalid_contacts=[]
    @contacts=pota_log[:contacts]
    pota_log[:contacts].each do |contact|
      other_park=nil
      if contact.callsign1==@user.callsign then other_callsign=contact.callsign2 else other_callsign=contact.callsign1 end
      if contact.park1 and contact.park1.id==park.id then
        if contact.park2 and contact.park2.pota_park then 
          other_park=contact.park2
        end
      else
        if contact.park1 and contact.park1.pota_park then 
          other_park=contact.park1
        end
      end
      if contact.band.length>0 and contact.adif_mode.length>0 and contact.time and contact.time.strftime("%H%M").length==4 then
        @pota_log+="<call:"+other_callsign.length.to_s+">"+other_callsign
        @pota_log+="<station_callsign:"+@user.callsign.length.to_s+">"+@user.callsign
        @pota_log+="<band:"+contact.band.length.to_s+">"+contact.band
        @pota_log+="<mode:"+contact.adif_mode.length.to_s+">"+contact.adif_mode
        @pota_log+="<qso_date:8>"+params[:date]
        @pota_log+="<time_on:4>"+contact.time.strftime("%H%M")
        @pota_log+="<my_sig_info:"+park.pota_park.reference.length.to_s+">"+park.pota_park.reference
        if other_park then @pota_log+="<sig_info:"+other_park.pota_park.reference.length.to_s+">"+other_park.pota_park.reference end
        @pota_log+="<eor>\n"
      else 
        @invalid_contacts.push(contact)
      end
    end
    @filename=@user.callsign+"@"+park.pota_park.reference+"-"+params[:date]+".adi" 
    callnumber=@user.callsign.gsub(/[^0-9]/, '').first 
    @address=""
    if callnumber then 
      @address="K"+callnumber.to_s+"@parksontheair.com"
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
      UserMailer.pota_log_submission(@user,@park,@logdate,@filename,@pota_log,@address).deliver
      #UserMailer.pota_log_submission(@user,@park,@logdate,@filename,@pota_log,"mattbriggs@yahoo.com").deliver
      @contacts.each do |contact|
        contact.submitted_to_pota=true
        contact.save
      end
 
      flash[:success]="Your log has been sent"
      redirect_to "/pota_logs"
    else
      flash[:error]="You must log in to submit logs"
      redirect_to '/'
    end
end
end
