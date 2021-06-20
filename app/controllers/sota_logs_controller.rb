class SotaLogsController < ApplicationController
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

    sls=@user.sota_logs
    sota_log=nil
    sls.each do |sl|
      if sl[:summit].code==params[:id].gsub('_','/') and sl[:date].strftime("%Y%m%d")==params[:date] then sota_log=sl end
    end 
  
    summit=Asset.find_by(code: params[:id].gsub('_','/'))
 
    @sota_log=""
    @invalid_contacts=[]
    @contacts=sota_log[:contacts]
    sota_log[:contacts].each do |contact|
      other_summit_code=nil
      other_callsign=contact.callsign2
      if contact.find_asset1_by_type('summit') and contact.find_asset1_by_type('summit')[:code]==summit.code then
        if contact.find_asset2_by_type('summit') then 
          other_summit_code=contact.find_asset2_by_type('summit')[:code]
        end
      end
      if contact.band.length>0 and contact.adif_mode.length>0 and contact.time and contact.time.strftime("%H%M").length==4 then
        @sota_log+="<call:"+other_callsign.length.to_s+">"+other_callsign
        @sota_log+="<station_callsign:"+@user.callsign.length.to_s+">"+@user.callsign
        @sota_log+="<band:"+contact.band.length.to_s+">"+contact.band
        @sota_log+="<mode:"+contact.adif_mode.length.to_s+">"+contact.adif_mode
        @sota_log+="<qso_date:8>"+params[:date]
        @sota_log+="<time_on:4>"+contact.time.strftime("%H%M")
        @sota_log+="<my_sota_ref:"+summit.code.length.to_s+">"+summit.code
        if other_summit_code and other_summit_code.length>0 then @sota_log+="<sota_ref:"+other_summit_code.length.to_s+">"+other_summit_code end
        @sota_log+="<eor>\n"
      else 
        @invalid_contacts.push(contact)
      end
    end
    @filename=@user.callsign+"@"+summit.safecode+"-"+params[:date]+".adi" 
    callnumber=@user.callsign.gsub(/[^0-9]/, '').first 
    @address=""
    if callnumber then 
      @address="K"+callnumber.to_s+"@summitsontheair.com"
    end
    @logdate=params[:date]
    @summit=summit
  else 
    flash[:error]="You must log in to submit logs"
    redirect_to '/'
  end
    respond_to do |format|
      format.html
      format.js
      format.adi { send_data @sota_log, filename: @filename 
           @contacts.each do |contact|
             contact.submitted_to_sota=true
             contact.save
           end
      }
    end

end  


def download
  if current_user then callsign=current_user.callsign else callsign="" end 
  if params[:user] then callsign=params[:user].upcase end
  if current_user and (current_user.is_admin or current_user.callsign==callsign) then
      show
      # Sends activation email.
      UserMailer.sota_log_submission(@user,@summit,@logdate,@filename,@sota_log,@address).deliver
      #UserMailer.sota_log_submission(@user,@summit,@logdate,@filename,@sota_log,"mattbriggs@yahoo.com").deliver
 
      flash[:success]="Your log has been sent"
      redirect_to "/sota_logs"
    else
      flash[:error]="You must log in to submit logs"
      redirect_to '/'
    end
end
end
