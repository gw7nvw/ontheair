# frozen_string_literal: true

# typed: false
class SotaLogsController < ApplicationController
  before_action :signed_in_user, only: %i[index show send_email]

  def index
    callsign = ''
    callsign = current_user.callsign if current_user
    callsign = params[:user].upcase if params[:user]
    users = User.where(callsign: callsign)
    @user = users.first if users
    unless @user
      flash[:error] = 'User ' + callsign + ' does not exist'
      redirect_to '/'
    end
  end

  def show
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    @resubmit = params[:resubmit] ? true : false
    if current_user && (current_user.is_admin || (current_user.callsign == callsign))
      users = User.where(callsign: callsign)
      @user = users.first if users
      unless @user
        flash[:error] = 'User ' + callsign + ' does not exist'
        redirect_to '/'
      end

      if params[:id] == 'chaser'
        @chaser = true
        sls = @user.sota_chaser_contacts(nil, @resubmit)
        sota_log = sls.first
      else
        summit = Asset.find_by(code: params[:id].tr('_', '/'))

        sls = @user.sota_contacts(summit.code)
        summit_code = summit.code
        sota_log = nil
        sls.each do |sl|
          if (sl[:code] == params[:id].tr('_', '/')) && (sl[:date].strftime('%Y%m%d') == params[:date]) then sota_log = sl end
        end

      end

      @sota_log = ''
      @invalid_contacts = []
      @contacts = sota_log[:contacts]
      sota_log[:contacts].each do |contact|
        other_summit_code = nil
        other_callsign = contact.callsign2
        if params[:id] == 'chaser'
          # no S2S in chaser logs, must be in an activation
          summit_code = nil
          other_summit_code = contact.asset2_codes
        end
        if !contact.band.empty? && !contact.adif_mode.empty? && contact.time && (contact.time.strftime('%H%M').length == 4)
          if contact.is_portable2 && (other_callsign[-2..-1] != '/P') then other_callsign += '/P' end
          @sota_log += '<call:' + other_callsign.length.to_s + '>' + other_callsign
          @sota_log += '<station_callsign:' + @user.callsign.length.to_s + '>' + @user.callsign
          @sota_log += '<band:' + contact.band.length.to_s + '>' + contact.band
          @sota_log += '<mode:' + contact.adif_mode.length.to_s + '>' + contact.adif_mode
          #        if params[:date] then
          #          @sota_log+="<qso_date:8>"+params[:date]
          #        else
          @sota_log += '<qso_date:8>' + contact.date.strftime('%Y%m%d')
          #        end
          @sota_log += '<time_on:4>' + contact.time.strftime('%H%M')
          if summit_code
            @sota_log += '<my_sota_ref:' + summit_code.length.to_s + '>' + summit_code
          end
          if other_summit_code && !other_summit_code.empty? then @sota_log += '<sota_ref:' + other_summit_code.length.to_s + '>' + other_summit_code end
          @sota_log += "<eor>\n"
        else
          errors = ''
          if contact.band.empty? then errors += "Invalid frequency / band: #{contact.frequency} MHz; " end
          if contact.adif_mode.empty? then errors += "Invalid mode: #{contact.mode}; " end
          if !contact.time || (contact.time.strftime('%H%M').length != 4) then errors += "Invalid time: #{contact.time.strftime('%H%M')}; " end
          @invalid_contacts.push(contact: contact, message: errors)
        end
      end
      @filename = if summit
                    @user.callsign + '@' + summit.safecode + '-' + params[:date] + '.adi'
                  else
                    @user.callsign + '-chaser.adi'
                  end
      callnumber = @user.callsign.gsub(/[^0-9]/, '').first
      @address = ''
      @address = 'K' + callnumber.to_s + '@summitsontheair.com' if callnumber
      @logdate = params[:date]
      @summit = summit
    else
      flash[:error] = 'You must log in to submit logs'
      redirect_to '/'
    end
    respond_to do |format|
      format.html
      format.js
      format.adi do
        send_data @sota_log, filename: @filename
        @contacts.each do |contact|
          c2 = Contact.find(contact.id)
          # Mark as sent. Use update column to avoid callbacks
          c2.update_column(:submitted_to_sota, true)
        end
      end
    end
  end

  def download
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    if current_user && (current_user.is_admin || (current_user.callsign == callsign))
      show
      # Sends activation email.
      UserMailer.sota_log_submission(@user, @summit, @logdate, @filename, @sota_log, @address).deliver
      # UserMailer.sota_log_submission(@user,@summit,@logdate,@filename,@sota_log,"mattbriggs@yahoo.com").deliver

      flash[:success] = 'Your log has been sent'
      redirect_to '/sota_logs'
    else
      flash[:error] = 'You must log in to submit logs'
      redirect_to '/'
      end
  end
end
