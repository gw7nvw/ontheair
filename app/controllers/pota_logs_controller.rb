class PotaLogsController < ApplicationController
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

    pls=@user.pota_logs
    pota_log=nil
    pls.each do |pl|
      if pl[:park][:potapark]==params[:id] and pl[:date].strftime("%Y%m%d")==params[:date] then pota_log=pl end
    end 
  
    park=Asset.find_by(code: params[:id])
  
    @pota_log=""
    @invalid_contacts=[]
    @duplicate_contacts=[]
    @contacts=pota_log[:contacts]
    callsigns=[]
    pota_log[:contacts].each do |contact|
      other_park=nil
      other_callsign=contact.callsign2
      if pp=contact.find_asset2_by_type('pota park') then
        other_park_code=pp[:code]
      elsif p=contact.find_asset2_by_type('park') then
        if p[:asset] then las=p[:asset].linked_assets_by_type('pota park') end
        if las and las.count>0 then other_park_code=las.first.code end
      end

      if contact.band.length>0 and contact.adif_mode.length>0 and contact.time and contact.time.strftime("%H%M").length==4 and not ((callsigns.include? other_callsign) and (not other_park_code))  then
        callsigns.push(other_callsign)
        @pota_log+="<call:"+other_callsign.length.to_s+">"+other_callsign
        @pota_log+="<station_callsign:"+@user.callsign.length.to_s+">"+@user.callsign
        @pota_log+="<band:"+contact.band.length.to_s+">"+contact.band
        @pota_log+="<mode:"+contact.adif_mode.length.to_s+">"+contact.adif_mode
        @pota_log+="<qso_date:8>"+params[:date]
        @pota_log+="<time_on:4>"+contact.time.strftime("%H%M")
        @pota_log+="<my_sig_info:"+park.code.length.to_s+">"+park.code
        if other_park_code then @pota_log+="<sig_info:"+other_park_code.length.to_s+">"+other_park_code end
        @pota_log+="<eor>\n"
      else 
        if ((callsigns.include? other_callsign) and (not other_park_code)) then 
          @duplicate_contacts.push(contact)
        else 
          errors=""
          if contact.band.length==0 then errors+="Invalid frequency / band: #{contact.frequency} MHz; " end
          if contact.adif_mode.length==0 then errors+="Invalid mode: #{contact.mode}; " end
          if !contact.time or contact.time.strftime("%H%M").length!=4 then errors+="Invalid time: #{contact.time.strftime("%H%M")}; " end
          @invalid_contacts.push({contact: contact, message: errors})
        end
      end
    end
    @filename=@user.callsign+"@"+park.code+"-"+params[:date]+".adi" 
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
