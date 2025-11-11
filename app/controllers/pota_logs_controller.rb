# frozen_string_literal: true

# typed: false
class PotaLogsController < ApplicationController
  before_action :signed_in_user, only: %i[index show send_email download]

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
    unless @user==current_user or current_user.is_admin
      flash[:error] = "You do not have permissions to view POTA logs for this user"
      redirect_to '/'
      return
    end
  end

  def show
    code = (params[:id] || '').tr('_', '/')
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    users = User.where(callsign: callsign)
    @user = users.first if users
    unless @user
     flash[:error] = 'User ' + callsign + ' does not exist'
      redirect_to '/'
    end
    unless @user==current_user or current_user.is_admin
      flash[:error] = "You do not have permissions to view POTA logs for this user"
      redirect_to '/'
      return
    end

    pls = @user.pota_contacts(code)
    pota_log = nil
    pls.each do |pl|
      if (pl[:code] == code) && (pl[:date].strftime('%Y%m%d') == params[:date]) then pota_log = pl end
    end

    park = Asset.find_by(code: params[:id])

    @pota_log = ''
    @invalid_contacts = []
    @duplicate_contacts = []
    @contacts = pota_log[:contacts]
    callsigns = []
    pota_log[:contacts].each do |contact|
      other_park = nil
      other_callsign = contact.callsign2
      if pp = contact.find_asset2_by_type('pota park')
        other_park_code = pp[:code]
      elsif p = contact.find_asset2_by_type('park')
        las = p[:asset].linked_assets_by_type('pota park') if p[:asset]
        other_park_code = las.first.code if las && (las.count > 0)
      end

      unique_details = other_callsign + '|' + contact.band + '|' + contact.mode
      if !contact.band.empty? && !contact.adif_mode.empty? && contact.time && (contact.time.strftime('%H%M').length == 4) && !((callsigns.include? unique_details) && !other_park_code)
        callsigns.push(unique_details)
        if contact.is_portable2 && (other_callsign[-2..-1] != '/P') then other_callsign += '/P' end
        @pota_log += '<call:' + other_callsign.length.to_s + '>' + other_callsign
        @pota_log += '<station_callsign:' + @user.callsign.length.to_s + '>' + @user.callsign
        @pota_log += '<band:' + contact.band.length.to_s + '>' + contact.band
        @pota_log += '<mode:' + contact.adif_mode.length.to_s + '>' + contact.adif_mode
        @pota_log += '<qso_date:8>' + params[:date]
        @pota_log += '<time_on:4>' + contact.time.strftime('%H%M')
        @pota_log += '<my_sig_info:' + park.code.length.to_s + '>' + park.code
        if other_park_code then @pota_log += '<sig_info:' + other_park_code.length.to_s + '>' + other_park_code end
        @pota_log += "<eor>\n"
      else
        if (callsigns.include? unique_details) && !other_park_code
          @duplicate_contacts.push(contact)
        else
          errors = ''
          if contact.band.empty? then errors += "Invalid frequency / band: #{contact.frequency} MHz; " end
          if contact.adif_mode.empty? then errors += "Invalid mode: #{contact.mode}; " end
          if !contact.time || (contact.time.strftime('%H%M').length != 4) then errors += "Invalid time: #{contact.time.strftime('%H%M')}; " end
          @invalid_contacts.push(contact: contact, message: errors)
        end
      end
    end
    @filename = @user.callsign + '@' + park.code + '-' + params[:date] + '.adi'
    callnumber = @user.callsign.gsub(/[^0-9]/, '').first
    @address = ''
    @address = 'K' + callnumber.to_s + '@parksontheair.com' if callnumber
    @logdate = params[:date]
    @park = park
  end

  def download
    show
    if @contacts 
      @contacts.each do |contact|
        contact.update_column(:submitted_to_pota, true)

      end
      @duplicate_contacts.each do |contact|
        contact.update_column(:submitted_to_pota, true)
      end

      respond_to do |format|
        format.adi { send_data @pota_log, filename: @filename }
      end
    end
  end

  def send_email
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    if current_user && (current_user.is_admin || (current_user.callsign == callsign))
      show
      if @contacts
        # Sends activation email.
        if ENV['RAILS_ENV'] == 'production'
          UserMailer.pota_log_submission(@user, @park, @logdate, @filename, @pota_log, @address).deliver
        else
        # UserMailer.pota_log_submission(@user,@park,@logdate,@filename,@pota_log,"mattbriggs@yahoo.com").deliver
        end
        @contacts.each do |contact|
          contact.submitted_to_pota = true
          contact.save
        end
        @duplicate_contacts.each do |contact|
          contact.submitted_to_pota = true
          contact.save
        end
      end
      flash[:success] = 'Your log has been sent'
      redirect_to '/pota_logs'
    else
      flash[:error] = 'You do not have permissions to send POTA logs for this user'
      redirect_to '/'
      end
  end
end
