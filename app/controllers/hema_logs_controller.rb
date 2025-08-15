# frozen_string_literal: true

# typed: false
class HemaLogsController < ApplicationController
  before_action :signed_in_user
  def index
    callsign = ''
    callsign = current_user.callsign if current_user
    callsign = params[:user].upcase if params[:user]
    @user = User.find_by(callsign: callsign)
    unless @user
      flash[:error] = 'User ' + callsign + ' does not exist'
      redirect_to '/'
      return
    end
    unless @user==current_user or current_user.is_admin
      flash[:error] = "You do not have permissions to view HEMA logs for this user"
      redirect_to '/'
      return
    end
    contacts = Contact.where('user1_id=' + @user.id.to_s + " and 'hump'=ANY(asset1_classes)")
    all_ids = contacts.map(&:log_id)
    log_ids = all_ids.uniq
    logs = Log.find_by_sql [' select  * from logs where id in (?) order by date desc', log_ids]
 
    @chaser_contacts = Contact.where('user1_id=' + @user.id.to_s + " and 'hump'=ANY(asset2_classes) and submitted_to_hema_chaser is not true")

    # get submitted status for log
    @logs = []
    logs.each do |log|
      log.asset_codes.each do |code|
        next unless Asset.get_asset_type_from_code(code) == 'hump'
        asset = Asset.find_by(code: code)
        submitted_to_hema = true
        log.contacts.each do |c|
          submitted_to_hema = false unless c.submitted_to_hema
        end

        @logs += [{ id: log.id, name: asset.name, code: code, date: log.date, contacts: log.contacts.count, submitted_to_hema: submitted_to_hema }]
      end
    end
  end

  def show
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    @resubmit = params[:resubmit] ? true : false
    users = User.where(callsign: callsign)
    @user = users.first if users
    unless @user
      flash[:error] = 'User ' + callsign + ' does not exist'
      redirect_to '/'
    end

    @id = params[:id]
    @log = Log.find(params[:id])
    unless @log.user1_id==current_user.id or current_user.is_admin
      flash[:error] = "You do not have permissions to view HEMA logs for this user"
      redirect_to '/'
      return
    end
  end

  def chaser
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    @resubmit = params[:resubmit] ? true : false
    users = User.where(callsign: callsign)
    @user = users.first if users
    unless @user
      flash[:error] = 'User ' + callsign + ' does not exist'
      redirect_to '/'
    end

    if @resubmit
      @chaser_contacts = Contact.where('user1_id=' + @user.id.to_s + " and 'hump'=ANY(asset2_classes)")
    else
      @chaser_contacts = Contact.where('user1_id=' + @user.id.to_s + " and 'hump'=ANY(asset2_classes) and submitted_to_hema_chaser is not true")
    end
    unless @user.id==current_user.id or current_user.is_admin
      flash[:error] = "You do not have permissions to view HEMA logs for this user"
      redirect_to '/'
      return
    end
  end

  def submit_chaser
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    @resubmit = params[:resubmit] ? true : false
    users = User.where(callsign: callsign)
    @user = users.first if users
    unless @user
      flash[:error] = 'User ' + callsign + ' does not exist'
      redirect_to '/'
    end

    if @resubmit
      @chaser_contacts = Contact.where('user1_id=' + @user.id.to_s + " and 'hump'=ANY(asset2_classes)")
    else
      @chaser_contacts = Contact.where('user1_id=' + @user.id.to_s + " and 'hump'=ANY(asset2_classes) and submitted_to_hema_chaser is not true")
    end
    unless @user.id==current_user.id or current_user.is_admin
      flash[:error] = "You do not have permissions to view HEMA logs for this user"
      redirect_to '/'
      return
    end

    cookie = login_to_hema(params[:hema_user], params[:hema_pass])
    unless cookie 
      flash[:error] =  "HEMA Login failed" unless flash[:error]
    else
      count = 0
      @chaser_contacts.each do |contact|
        puts "Sending contact: #{contact.id.to_s}"
        response = send_chase_to_hema(cookie, contact)
        if response[:result] == 'error'
          flash[:error] = "" unless flash[:error]
          flash[:error] += response[:message]+"; "
        else
          contact.update_column :submitted_to_hema_chaser, true
        end
        count += 1
      end
      puts "DONE"
    end
    if !flash[:error] or flash[:error]=="" then
      flash[:success] = "#{count.to_s} chaser contacts submitted to HEMA" 
      redirect_to '/hema_logs'    
    else
      chaser
      render 'chaser'
    end
  end

  def submit
    callsign = current_user ? current_user.callsign : ''
    callsign = params[:user].upcase if params[:user]
    @resubmit = params[:resubmit] ? true : false
    users = User.where(callsign: callsign)
    @user = users.first if users
    unless @user
      flash[:error] = 'User ' + callsign + ' does not exist'
      redirect_to '/'
    end

    @log = Log.find(params[:id])
    unless @log.user1_id==current_user.id or current_user.is_admin
      flash[:error] = "You do not have permissions to view HEMA logs for this user"
      redirect_to '/'
      return
    end
    cookie = login_to_hema(params[:hema_user], params[:hema_pass])

    if cookie
      response = send_to_hema(cookie, @log)
      if response
        @response = response
        body = @response[:body].gsub('activationNew3.jsp?', '/hema_logs/' + @log.id.to_s + '/delete?cookie=' + @response[:cookie] + '&')
        body = body.gsub("'><img src='icons/delete.png'", %q{' data-remote='true' onclick="linkHandler('delete')"><img src='/assets/trash.png'})
        @response[:body] = body
      else
        flash[:error] = 'Error sending to HEMA'
        show()
        render 'show'
      end
    else
      render 'show'
    end
  end

  def delete
    @log = Log.find(params[:id])
    unless @log.user1_id==current_user.id or current_user.is_admin
      flash[:error] = "You do not have permissions to view HEMA logs for this user"
      redirect_to '/'
      return
    end
    summit = params[:summitKey]
    activation = params[:activationKey]
    logentry = params[:dActivationKey]
    cookie = params[:cookie]

    @response = delete_hema_log_entry(cookie, activation, summit, logentry)
    if @response
      body = @response[:body].gsub('activationNew3.jsp?', '/hema_logs/' + @log.id.to_s + '/delete?cookie=' + @response[:cookie] + '&')
      body = body.gsub("'><img src='icons/delete.png'", %q{' data-remote='true' onclick="linkHandler('delete')"><img src='/assets/trash.png'})
      @response[:body] = body
      puts 'done, redisplay submit'
      render 'submit'
    else
      flash[:error] = 'Error sending to HEMA'
      render 'show'
    end
  end

  def finalise
    @log = Log.find(params[:id])
    unless @log.user1_id==current_user.id or current_user.is_admin
      flash[:error] = "You do not have permissions to view HEMA logs for this user"
      redirect_to '/'
      return
    end
    summit = params[:summitKey]
    activation = params[:activationKey]
    cookie = params[:cookie]

    response = confirm_hema_log(cookie, activation, summit)
    # puts response.body
    # puts response.code
    if response
      flash[:success] = 'Log successfully submitted to HEMA'
      @log.contacts.each do |contact|
        contact.submitted_to_hema = true
        contact.save
      end
    else
      flash[:error] = 'Failed to send request to HEMA'
    end
    redirect_to '/hema_logs'
  end
  ##################################===

  def login_to_hema(user, pass)
    creds = nil
    uri = URI('http://www.hema.org.uk/indexDatabase.jsp')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    response = http.request(req)

    # POST request -> logging in
    cookie = response.get_fields('set-cookie')[0].split('; ')[0] + ';'
    
    params = {userID: user, password: pass}.to_query
    uri = URI('http://www.hema.org.uk/indexDatabase.jsp?logonAction=logon&action=')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(
      uri.path + '?logonAction=logon&action=',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk',
      'Referrer' => 'http://www.hema.org.uk/indexDatabase.jsp'
    )
    req.body = params
    response = http.request(req)

    if response.body['Incorrect callsign/password'] then flash[:error] = 'Invalid HEMA callsign / password'
    else
      creds = cookie
    end

    creds
  end

  def send_chase_to_hema(cookie, contact)
    summitcode = nil
    contact.asset2_codes.each do |code|
      summitcode = code if Asset.get_asset_type_from_code(code) == 'hump'
    end

    return { result: "error", message: "Unknown HEMA summit: "+contact.asset2_codes.to_s } unless summitcode

    dxcc = summitcode[0..2]
    region = summitcode[4..6]
    summit = Asset.find_by(code: summitcode)

    return { result: "error", message: "Unknown HEMA summit: "+summitcode } unless summit
   
    summitkey = summit.old_code
    return { result: "error", message: "HEMA summit missing from official HEMA database: "+summitcode } unless summitkey

    modes = { 'AM' => 1, 'FM' => 2, 'CW' => 3, 'SSB' => 4, 'USB' => 4, 'LSB' => 4, 'DATA' => 7, 'OTHER' => 9 }
    mode = contact.mode.upcase
    modekey = modes[mode]
    modekey ||= 7

    bands = {"472khz" => '2', "1.8MHz" => '3' , "3.6MHz"  => '4', "5MHz"  => '5', "7MHz"  => '6', "10MHz"  => '7', "14MHz"  => '8', "18MHz"  => '30', "21MHz"  => '9', "24MHz"  => '10', "28MHz"  => '11', "50MHz"  => '12', "70MHz"  => '13', "144MHz"  => '14', "220MHz"  => '15', "430MHz"  => '16', "900MHz"  => '17', "1.24GHz"  => '18', "2.3GHz"  => '19', "3.4GHz"  => '20', "5.7GHz"  => '21', "10GHz"  => '22', "24GHz"  => '23', "47GHz"  => '24', "76GHz"  => '25', "122GHz"  => '26', "134GHz"  => '27', "136GHz"  => '28', "248GHz"   => '29'}
    bandname = Contact.hema_band_from_frequency(contact.frequency)
    bandkey = bands[bandname]
    bandkey ||= 1

    # create chase
    uri = URI('http://www.hema.org.uk/chaseNew2.jsp?chaseDate=05%2F08%2F2025&timeKey=45&callsignLocal=ZL4NVW&callsignForeign=zl4test&bandKey=1&modeKey=2&summitKey=65700&action=saveNew&comments=test+log')

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(
      uri.path + '?chaseDate=' + contact.date.strftime('%d%%2f%m%%2f%Y') + '&timeKey=9999&callsignLocal=' + contact.callsign1 + '&callsignForeign=' + contact.callsign2 + '&summitKey=' + summitkey + '&bandKey=' + bandkey.to_s + '&modeKey=' + modekey.to_s + '&action=saveNew&comments=',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk'
    )

    response = http.request(req)
    # expect 302 redirect
    if response.code != '302'
      puts 'Unexpected reponse'
      return { result: "error", message: "Bad response code from HEMA", response: response }
    end

    #check for error code
    location = response ['location']
    if location['errorMessage']
      error_message = location.split("errorMessage=")[1]
      return { result: "error", message: error_message, response: response }
    end

    return { result: "success" }
  end

  def send_to_hema(cookie, log)
    summitcode = nil
    log.asset_codes.each do |code|
      summitcode = code if Asset.get_asset_type_from_code(code) == 'hump'
    end

    return unless summitcode

    dxcc = summitcode[0..2]
    region = summitcode[4..6]

    uri = URI('http://www.hema.org.uk/selectSummit.jsp')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(
      uri.path + '?regionCode=' + region + '&action=activationNew&summitKey=0&countryCode=' + dxcc + '&genericKey=0',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk'
    )

    response = http.request(req)
    rows = response.body.split("id='summitKey'")[1].split('</td>')[0].split(/\n/)

    summits = []
    rows.each do |r|
      next unless r['Option value']
      value = r.split("'")[1]
      codename = r.split('>')[1].split('<')[0]
      code = dxcc + '/' + region + '-' + codename[0..2]
      name = codename[6..-1]
      summits += [{ id: value, code: code, name: name }]
    end

    summit = summits.select { |s| s[:code] == summitcode }.first

    puts 'Got summits: ' + summit.to_json
    # create activation
    uri = URI('http://www.hema.org.uk/activationNew2.jsp?activationDate=07%2F07%2F2024&timeStart=9999&timeEnd=9999&callsignLocal=ZL4NVW&summitKey=65764&action=saveNew&comments=')

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(
      uri.path + '?activationDate=' + log.date.strftime('%d%%2f%m%%2f%Y') + '&timeStart=9999&timeEnd=9999&callsignLocal=' + log.callsign1 + '&summitKey=' + summit[:id].to_s + '&action=saveNew&comments=',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk'
    )

    response = http.request(req)
    # expect 302 redirect
    if response.code != '302'
      puts 'Unexpected reposnse'
      return
    end

    puts 'Get redirect to log page'

    location = response['location']
    values = location.split('&')[1..-1]
    pairs = Hash[values.map { |x| [x.split('=')[0], x.split('=')[1]] }]

    uri = URI('http://www.hema.org.uk/activationNew3.jsp')

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(
      uri.path + '?action=new&activationDate=' + log.date.strftime('%d%%2f%m%%2f%Y') + '&callsignLocal=' + log.callsign1 + '&activationKey=' + pairs['activationKey'] + '&summitKey=' + summit[:id].to_s + '&timeStart=9999&timeEnd=9999&bandKey=14&modeKey=2',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk'
    )

    response = http.request(req)

    # get bands
    rows = response.body.split('bandKey')[2].split('/select>')[0][2..-1].split(/\n/)
    bands = []
    rows.each do |r|
      next unless r['Option value']
      value = r.split("'")[1]
      name = r.split('>')[1].split('<')[0]
      bands += [{ id: value, name: name }]
    end

    puts 'got bands: ' + bands.to_json
    # get modes
    rows = response.body.split('modeKey')[2].split('/select>')[0][2..-1].split(/\n/)
    modes = []
    rows.each do |r|
      next unless r['Option value']
      value = r.split("'")[1]
      name = r.split('>')[1].split('<')[0]
      modes += [{ id: value, name: name }]
    end

    puts 'got modes: ' + modes.to_json
    log.contacts.each do |contact|
      band = bands.select { |b| b[:name] == contact.hema_band }.first
      band_id = band ? band[:id] : 14

      contact.mode = 'SSB' if (contact.mode == 'USB') || (contact.mode == 'LSB')
      mode = modes.select { |m| m[:name] == contact.mode }.first
      mode ||= modes.select { |m| m[:name] == 'OTHER' }
      mode_id = mode[:id]

      uri = URI('http://www.hema.org.uk/activationNew3.jsp')

      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(
        uri.path + '?activationKey=' + pairs['activationKey'] + '&summitKey=' + summit[:id].to_s + '&action=new&bandKey=' + band_id.to_s + '&modeKey=' + mode_id.to_s + '&callsignForeign1=' + contact.callsign2 + '&comments1=&callsignForeign2=&comments2=&callsignForeign3=&comments3=&callsignForeign4=&comments4=&callsignForeign5=&comments5=&fiveMore=',
        'Cookie' => cookie,
        'Host' => 'www.hema.org.uk',
        'Origin' => 'http://www.hema.org.uk'
      )

      response = http.request(req)
      puts 'Send contact ' + contact.callsign2
    end

    # finish
    uri = URI('http://www.hema.org.uk/activationNew3.jsp')

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(
      uri.path + '?activationKey=' + pairs['activationKey'] + '&summitKey=' + summit[:id].to_s + '&action=new&bandKey=14&modeKey=2&callsignForeign1=&comments1=&callsignForeign2=&comments2=&callsignForeign3=&comments3=&callsignForeign4=&comments4=&callsignForeign5=&comments5=&finish=',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk'
    )

    response = http.request(req)

    puts 'send finish'

    { body: response.body, cookie: cookie, key: pairs['activationKey'], summit: summit[:id].to_s }
  end

  def delete_hema_log_entry(cookie, key, summit, entry)
    uri = URI('http://www.hema.org.uk/activationNew3.jsp')

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(
      uri.path + '?activationKey=' + key + '&summitKey=' + summit + '&action=delete&dActivationKey=' + entry,
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk'
    )

    response = http.request(req)

    puts 'send delete'
    { body: response.body, cookie: cookie, key: key, summit: summit }
    end

  def confirm_hema_log(cookie, key, summit)
    # save
    uri = URI('http://www.hema.org.uk/activationNew3.jsp')

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(
      uri.path + '?activationKey=' + key + '&summitKey=' + summit + '&action=new&finalise=',
      'Cookie' => cookie,
      'Host' => 'www.hema.org.uk',
      'Origin' => 'http://www.hema.org.uk'
    )

    # enable once we really want to save!!!
    response = http.request(req)
    end
end
