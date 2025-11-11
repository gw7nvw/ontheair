# frozen_string_literal: true

# typed: false
class WwffLogsController < ApplicationController
  before_action :signed_in_user, only: %i[index show send_email]

  def index
    @parameters = params_to_query
    @resubmit = params[:resubmit] == 'true'

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
    @resubmit = params[:resubmit] == 'true'

    @parameters = params_to_query
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    if current_user && (current_user.is_admin || (current_user.callsign == callsign))
      users = User.where(callsign: callsign)
      @user = users.first if users
      unless @user
        flash[:error] = 'User ' + callsign + ' does not exist'
        redirect_to '/'
      end

      pls = @user.wwff_logs(@resubmit)
      wwff_log = nil
      pls.each do |pl|
        wwff_log = pl if pl[:park][:wwffpark] == params[:id]
      end

      puts wwff_log[:contacts].count

      park = Asset.find_by(code: params[:id])

      @wwff_log = ''
      @invalid_contacts = []
      @contacts = wwff_log[:contacts]
      @dups = wwff_log[:dups]
      lastdate = '19000101'
      wwff_log[:contacts].each do |contact|
        other_park = nil
        other_callsign = contact.callsign2
        if pp = contact.find_asset2_by_type('wwff park')
          other_park_code = pp[:code]
        elsif p = contact.find_asset2_by_type('park')
          las = p[:asset].linked_assets_by_type('wwff park') if p[:asset]
          other_park_code = las.first.code if las && (las.count > 0)
        end

        if !contact.band.empty? && !contact.adif_mode.empty? && contact.time && (contact.time.strftime('%H%M').length == 4)
          qsodate = contact.date.strftime('%Y%m%d')
          lastdate = qsodate if qsodate > lastdate
          if contact.is_portable2 && (other_callsign[-2..-1] != '/P') then other_callsign += '/P' end
          @wwff_log += '<call:' + other_callsign.length.to_s + '>' + other_callsign
          @wwff_log += '<station_callsign:' + @user.callsign.length.to_s + '>' + @user.callsign
          @wwff_log += '<operator:' + @user.callsign.length.to_s + '>' + @user.callsign
          @wwff_log += '<band:' + contact.band.length.to_s + '>' + contact.band
          @wwff_log += '<mode:' + contact.adif_mode.length.to_s + '>' + contact.adif_mode
          @wwff_log += '<qso_date:8>' + qsodate
          @wwff_log += '<time_on:4>' + contact.time.strftime('%H%M')
          @wwff_log += '<my_sig:4>WWFF'
          @wwff_log += '<my_sig_info:' + park.code.length.to_s + '>' + park.code
          @wwff_log += '<sig:4>WWFF' if other_park_code
          if other_park_code then @wwff_log += '<sig_info:' + other_park_code.length.to_s + '>' + other_park_code end
          @wwff_log += "<eor>\n"
        else
          errors = ''
          if contact.band.empty? then errors += "Invalid frequency / band: #{contact.frequency} MHz; " end
          if contact.adif_mode.empty? then errors += "Invalid mode: #{contact.mode}; " end
          if !contact.time || (contact.time.strftime('%H%M').length != 4) then errors += "Invalid time: #{contact.time.strftime('%H%M')}; " end
          @invalid_contacts.push(contact: contact, message: errors)
        end
      end
      @filename = @user.callsign + '@' + park.code + '_' + lastdate + '.adi'
      callnumber = @user.callsign.gsub(/[^0-9]/, '').first
      @address = ''
      if callnumber
        @address = 'simmopa@iprimus.com.au'
        # @address="mattbriggs@yahoo.com"
      end
      @logdate = Time.now.in_time_zone('UTC').strftime("%Y-%m-%d")
      @park = park
    else
      flash[:error] = 'You must log in to submit logs'
      redirect_to '/'
    end
  end

  def send_email
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    if current_user && (current_user.is_admin || (current_user.callsign == callsign))
      show
      # Sends activation email.
      # UserMailer.wwff_log_submission(@user,@park,@filename,@wwff_log,@address).deliver
      UserMailer.wwff_log_submission(@user, @park, @filename, @wwff_log, @address).deliver
      @contacts.each do |contact|
        contact.submitted_to_wwff = true
        contact.save
      end
      # also mark duplicates and invalds as sent so as not to retry them next time
      @dups.each do |contact|
        contact.submitted_to_wwff = true
        contact.save
      end
      @invalid_contacts.each do |ic|
        contact = ic[:contact]
        contact.submitted_to_wwff = true
        contact.save
      end

      flash[:success] = 'Your log has been sent'
      redirect_to '/wwff_logs'
    else
      flash[:error] = 'You must log in to submit logs'
      redirect_to '/'
      end
  end

  def download
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    show

    @contacts.each do |contact|
#      contact.submitted_to_wwff = true
      contact.update_column(:submitted_to_wwff, true)
    end
    # also mark duplicates and invalds as sent so as not to retry them next time
    @dups.each do |contact|
      contact.update_column(:submitted_to_wwff, true)
    end
    @invalid_contacts.each do |ic|
      contact = ic[:contact]
      contact.update_column(:submitted_to_wwff, true)
    end

    respond_to do |format|
      format.adi { send_data @wwff_log, filename: @filename }
    end


  end
end
