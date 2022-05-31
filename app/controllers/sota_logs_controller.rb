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
  if params[:resubmit] then @resubmit=true else @resubmit=false end
  if current_user and (current_user.is_admin or current_user.callsign==callsign) then
    users=User.where(callsign: callsign)
    if users then @user=users.first end
    if !@user then
     flash[:error]="User "+callsign+" does not exist"
     redirect_to '/'
    end

    if params[:id]=="chaser" then
      @chaser=true
      sls=@user.sota_chaser_contacts(nil, @resubmit)
      puts sls.count
      sota_log=sls.first
      puts sota_log.to_json
    else
      summit=Asset.find_by(code: params[:id].gsub('_','/'))

      sls=@user.sota_contacts(summit.code)
      sota_log=nil
      sls.each do |sl|
        if sl[:summit].code==params[:id].gsub('_','/') and sl[:date].strftime("%Y%m%d")==params[:date] then sota_log=sl end
      end

    end 
  
 
    @sota_log=""
    @invalid_contacts=[]
    @contacts=sota_log[:contacts]
    sota_log[:contacts].each do |contact|
      other_summit_code=nil
      other_callsign=contact.callsign2
      if params[:id]=="chaser" then 
        if contact.find_asset1_by_type('summit') then 
          summit_code=contact.find_asset1_by_type('summit')[:code]
        end

        if contact.find_asset2_by_type('summit') then 
          other_summit_code=contact.find_asset2_by_type('summit')[:code]
        end
      else
        if contact.find_asset1_by_type('summit') and contact.find_asset1_by_type('summit')[:code]==summit.code then
          summit_code=summit.code
          if contact.find_asset2_by_type('summit') then 
            other_summit_code=contact.find_asset2_by_type('summit')[:code]
          end
        end
      end
      if contact.band.length>0 and contact.adif_mode.length>0 and contact.time and contact.time.strftime("%H%M").length==4 then
        if contact.is_portable2 and other_callsign[-2..-1]!="/P" then other_callsign+="/P" end
        @sota_log+="<call:"+other_callsign.length.to_s+">"+other_callsign
        @sota_log+="<station_callsign:"+@user.callsign.length.to_s+">"+@user.callsign
        @sota_log+="<band:"+contact.band.length.to_s+">"+contact.band
        @sota_log+="<mode:"+contact.adif_mode.length.to_s+">"+contact.adif_mode
        if params[:date] then
          @sota_log+="<qso_date:8>"+params[:date]
        else
          @sota_log+="<qso_date:8>"+contact.date.strftime("%Y%m%d")
        end
        @sota_log+="<time_on:4>"+contact.time.strftime("%H%M")
        if summit_code then
          @sota_log+="<my_sota_ref:"+summit_code.length.to_s+">"+summit_code
        end
        if other_summit_code and other_summit_code.length>0 then @sota_log+="<sota_ref:"+other_summit_code.length.to_s+">"+other_summit_code end
        @sota_log+="<eor>\n"
      else 
        errors=""
        if contact.band.length==0 then errors+="Invalid frequency / band: #{contact.frequency} MHz; " end
        if contact.adif_mode.length==0 then errors+="Invalid mode: #{contact.mode}; " end
        if !contact.time or contact.time.strftime("%H%M").length!=4 then errors+="Invalid time: #{contact.time.strftime("%H%M")}; " end
        @invalid_contacts.push({contact: contact, message: errors})
      end
    end
    if summit then
      @filename=@user.callsign+"@"+summit.safecode+"-"+params[:date]+".adi" 
    else
      @filename=@user.callsign+"-chaser.adi" 
    end
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
