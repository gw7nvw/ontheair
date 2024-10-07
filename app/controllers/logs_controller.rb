# frozen_string_literal: true

# typed: false
class LogsController < ApplicationController
  before_action :signed_in_user, only: %i[edit editcontact update new create upload savefile delete save]

  skip_before_filter :verify_authenticity_token, only: %i[save savefile]

  def index
    if signed_in?
      @callsign = current_user.callsign
      @user = current_user
    end

    if params[:user] && !params[:user].empty?
      if params[:user].casecmp('ALL').zero?
        @callsign = nil
        @user = nil
      else
        @callsign = params[:user].upcase
        @user = User.find_by(callsign: @callsign.upcase)
      end
    end

    whereclause = 'true'
    if params[:asset] && !params[:asset].empty?
      whereclause = "('#{params[:asset].upcase.tr('_', '/')}' = ANY(asset_codes))"
      @asset = Asset.find_by(code: params[:asset].tr('_', '/').upcase)
      @assetcode = @asset.code if @asset
    end

    @fulllogs = if @callsign then Log.find_by_sql ['select * from logs where user1_id=' + @user.id.to_s + ' and ' + whereclause + ' order by date desc']
                else Log.find_by_sql ['select * from logs where ' + whereclause + ' order by date desc']
                end
    @logs = @fulllogs.paginate(per_page: 20, page: params[:page])
  end

  def show
    @log = Log.find_by_id(params[:id])
    redirect_to '/logs' unless @log

    respond_to do |format|
      format.html
      format.js
      format.text
      format.adi { send_data log_to_adi(@log), filename: @filename }
    end
  end

  def new
    @no_map = true
    if signed_in?
      @log = Log.new
      @log.callsign1 = current_user.callsign
      @log.asset_codes = nil
      @log.date = Time.now.in_time_zone(@tz.name).to_date
      @log.timezone = @tz.id
    else
      redirect_to '/'
    end
  end

  def create
    if signed_in?
      @log = Log.new(log_params)
      @user = User.find_by_callsign_date(@log.callsign1.upcase, @log.date)
      if (@user.id === current_user.id) || current_user.is_admin
        @log.asset_codes = params[:log][:asset_codes].delete('{').delete('}').split(',')
        @log.createdBy_id = current_user.id
        if @log.save
          @log.reload
          @id = @log.id
          params[:id] = @id
          redirect_to '/logs/' + @id.to_s + '/edit'
        else
          render 'new'
        end
      else
        @log.errors[:callsign1]="You do not have permission to use this callsign on this date"
        render 'new'
      end
    else
      flash[:error]="You do not have permission to create a log"
      redirect_to '/'
    end
  end

  def edit
    @no_map = true
    @log ||= Log.find_by_id(params[:id])
    @user = User.find_by_callsign_date(@log.callsign1.upcase, @log.date) if @log

    if @log && current_user && ((@user && (current_user.id == @user.id)) || current_user.is_admin)
      @log.timezone = @tz.id

      @contacts = Contact.where(log_id: @log.id).order(:time)
      @contacts.each do |c|
        c.timetext = c.localtime(current_user)
        asset2_names = []
        c.asset2_codes.each do |ac|
          a = Asset.find_by(code: ac)
          asset2_names += a ? ['[' + a.code + '] ' + a.name] : [ac]
        end
        c.asset2_names = asset2_names.join("\n")
      end
    else
      flash[:error] = "You do not have permission to use this callsign on this date"
      redirect_to '/'
    end
  end

  #redirects from /contacts/edit
  def editcontact
    @log = nil
    # get log from contact
    @contact = Contact.find_by_id(params[:id])
    loguser = User.find_by_callsign_date(@contact.callsign1.upcase, @contact.time)

    if current_user && ((current_user.id == loguser.id) || current_user.is_admin)
      if @contact
        @log = Log.find_by_id(@contact.log_id) if @contact.log_id
        # create log if conact has none
        unless @log
          # copy matching subset of contact columsn to log
          columns = (Contact.column_names & Log.column_names) - %w[id createdBy_id created_at updated_at]
          @log = Log.new(Contact.first(select: columns.join(',')).attributes)
          @log.asset_codes = @contact.asset1_codes
          @log.createdBy_id = current_user.id
          @log.save
          @contact.log_id = @log.id
          @contact.save
        end
        edit
        render 'edit'
      else
        flash[:error] = 'Contact not found'
        redirect_to '/'
      end
    else
      flash[:error] = 'You do not have permission to use this callsign on this date'
      redirect_to '/'
    end
  end

  def update
    if signed_in?
      unless (@log = Log.find_by_id(params[:id]))
        flash[:error] = 'Log does not exist: ' + @log.id.to_s
        redirect_to '/'
      end

      @log.assign_attributes(log_params)
      loguser = User.find_by_callsign_date(@log.callsign1.upcase, @log.date)
      if (loguser.id === current_user.id) || current_user.is_admin
        @log.asset_codes = params[:log][:asset_codes].delete('{').delete('}').split(',')
        if @log.save
          flash[:success] = 'Log details updated'
          @user = User.find_by(callsign: @log.callsign1)
          @contacts = Contact.where(log_id: @log.id).order(:time)
          redirect_to '/logs/' + @log.id.to_s + '/edit'
        else
          @user = User.find_by(callsign: @log.callsign1)
          @contacts = Contact.where(log_id: @log.id).order(:time)
          redirect_to '/logs/' + @log.id.to_s + '/edit'
        end
      else
        @log.errors[:callsign1]="You do not have permission to use this callsign on this date"
        render 'edit'
      end
    else
      flash[:error] = 'You do not have permissions to take this action'
      redirect_to '/'
    end
  end

  def delete
    if signed_in?
      cl = Log.find_by_id(params[:id])
      if cl
        loguser = User.find_by_callsign_date(cl.callsign1.upcase, cl.date)
        if (loguser.id == current_user.id) || current_user.is_admin
          cl.contacts.each(&:destroy)
          cl.destroy
          flash[:success] = 'Log deleted'
        else
          flash[:error] = 'You do not have permission to use this callsign on this date'
        end
        redirect_to '/logs/'
      end
    else
      redirect_to '/'
    end
  end

  #Log uploads - upload - get / savefile - post
  def upload
    @upload = Upload.new
  end

  def savefile
    @upload = Upload.new(upload_params)
    do_not_lookup = false

    # get callsign from form
    location = params[:upload][:doc_location]
    location = location.upcase if location && !location.empty?

    if params[:upload][:doc_callsign]
      logger.debug 'Got callsign: ' + params[:upload][:doc_callsign]
      callsign = params[:upload][:doc_callsign]
      force_callsign = true
    end
    user = if current_user.is_admin && params[:callsign]
             User.find_by(callsign: params[:callsign].upcase)
           else
             current_user
           end
    callsign ||= user.callsign
    if params[:upload][:doc_do_not_lookup] && (params[:upload][:doc_do_not_lookup] == '1' or params[:upload][:doc_do_not_lookup] == true)
      do_not_lookup = true
    end
    success = @upload.save

    if success
      logfile = File.read(@upload.doc.path)
      results = if @upload.doc.path.match('.csv')
                  Log.import('csv', current_user, logfile, user, callsign, location, params[:upload][:doc_no_create] == '1', params[:upload][:doc_ignore_error] == '1', do_not_lookup, force_callsign)
                else
                  Log.import('adif', current_user, logfile, user, callsign, location, params[:upload][:doc_no_create] == '1', params[:upload][:doc_ignore_error] == '1', do_not_lookup, force_callsign)
                end

      logs = results[:logs]
      errors = results[:errors]
      success = results[:success]
      if errors && (errors.count > 0)
        @errors = errors
        logger.warn errors.join('\n')
      end
      if (success == false) && (params[:upload][:doc_ignore_error] != '1')
        flash[:success] = 'Found ' + results[:good_contacts].to_s + ' valid contact(s) and ' + results[:good_logs].to_s + ' valid logs but did not upload due to other errors.'
        @upload = Upload.new
        render 'upload'
        return
      end

      if (results[:good_logs] > 0) && logs && (logs.count > 0)
        lc = 0
        lc += 1 while !logs[lc].id && (lc < logs.count)
        @log = logs[lc]
        flash[:success] = 'Uploaded ' + results[:good_contacts].to_s + ' contact(s) into ' + results[:good_logs].to_s + ' logs. Showing first log'
        redirect_to '/logs/' + @log.id.to_s
      else
        @upload = Upload.new
        flash[:success] = 'Found ' + results[:good_contacts].to_s + ' valid contact(s) and ' + results[:good_logs].to_s + ' valid logs but did not upload due to other errors.'
        flash[:error] = logs.map { |log| log.errors.full_messages.join(',') }.join(',')
        render 'upload'
        return
      end
    else
      flash[:error] = 'Error creating file - ' + @upload.errors.full_messages.join(',')
      render 'upload'
    end
  end


  #Spreadsheet editor calls
  def load
  end

  def save
    status = 200
    data = params[:data]
    id = params[:id]
    ids = []
    log = Log.find_by_id(params[:id])
    loguser = User.find_by_callsign_date(log.callsign1.upcase, log.date)
    if current_user && ((current_user.id == loguser.id) || current_user.is_admin)

      data.each do |row|
        rid = row[0]
        if rid && (rid >= 1)
          cle = Contact.find_by_id(rid)
        else
          cle = Contact.new
          cle.createdBy_id = current_user.id
        end
        next unless row[2]
        cle.time = format('%05.2f', ((row[1] || '').gsub(/\D/, '').to_f / 100)).tr('.', ':')
        cle.callsign1 = log.callsign1
        cle.date = log.date
        cle.loc_desc1 = log.loc_desc1
        cle.is_qrp1 = log.is_qrp1
        cle.power1 = log.power1
        cle.is_portable1 = log.is_portable1
        cle.timezone = log.timezone
        cle.x1 = log.x1
        cle.y1 = log.y1
        cle.location1 = log.location1
        cle.callsign2 = (row[2] || '').upcase
        cle.is_qrp2 = row[3]
        cle.is_portable2 = row[4]
        cle.mode = row[5]
        cle.frequency = row[6]
        cle.signal2 = row[7]
        cle.signal1 = row[8]
        cle.name2 = row[9]
        cle.loc_desc2 = row[10]
        cle.asset1_codes = log.asset_codes
        cle.asset1_codes = [''] if cle.asset1_codes.nil?
        cle.asset2_codes = row[13]
        logger.debug 'DEBUG asset codes'
        logger.debug cle.asset2_codes
        logger.debug cle.loc_desc2
        if cle.asset2_codes.nil? || (cle.asset2_codes == []) then cle.asset2_codes = [''] end
        cle.location2 = row[14]
        cle.x2 = row[15]
        cle.y2 = row[16]
        cle.log_id = id
        cle.convert_user_timezone_to_utc(current_user)

        unless cle.save then status = 500; puts 'error' end
        ids << cle.id
      end
      # delete entries not in our post
      @contacts = Contact.where(log_id: id)
      @contacts.each do |contact|
        contact.destroy unless ids.include? contact.id
      end
    else
      status = 401
    end
    @contacts = Contact.where(log_id: id).order(:time)
    @contacts.each do |c|
      c.timetext = c.localtime(current_user)
      asset2_names = []
      c.asset2_codes.each do |ac|
        a = Asset.find_by(code: ac)
        asset2_names += a ? ['[' + a.code + '] ' + a.name] : [ac]
      end
      c.asset2_names = asset2_names.join('/n')
    end

    respond_to do |format|
      format.html
      format.js
      format.json { render json: @contacts, status: status, methods: %i[timetext asset2_names] }
    end
  end


  private

  def log_params
    params.require(:log).permit(:id, :callsign1, :user1_id, :power1, :signal1, :transceiver1, :antenna1, :comments1, :location1, :park1, :date, :time, :timezone, :frequency, :mode, :loc_desc1, :x1, :y1, :altitude1, :location1, :is_active, :hut1_id, :park1_id, :island1_id, :is_qrp1, :is_portable1, :summit1_id, :asset_codes, :do_not_lookup)
end

  def upload_params
    params.require(:upload).permit(:doc)
  end

  def post_notification(contest_log)
    if contest_log && contest_log.contest
      details = contest_log.callsign + ' added a log for ' + contest_log.contest.name + '  on ' + contest_log.localdate(current_user)

      hp = HotaPost.new
      hp.title = details
      hp.url = 'qrp.nz/contest_logs/' + contest_log.id.to_s
      hp.save
      hp.reload
      i = Item.new
      i.item_type = 'hota'
      i.item_id = hp.id
      i.save
    end
  end

  def log_to_adi(log)
    @sota_log = ''
    contacts = log.contacts
    contacts.each do |contact|
      @sota_log += '<call:' + contact.callsign2.length.to_s + '>' + contact.callsign2
      @sota_log += '<station_callsign:' + contact.callsign1.length.to_s + '>' + contact.callsign1
      if contact.band then @sota_log += '<band:' + contact.band.length.to_s + '>' + contact.band end
      if contact.frequency then @sota_log += '<freq:' + contact.frequency.to_s.length.to_s + '>' + contact.frequency.to_s end
      if contact.mode then @sota_log += '<mode:' + contact.adif_mode.length.to_s + '>' + contact.adif_mode end
      if contact.date then @sota_log += '<qso_date:8>' + contact.date.strftime('%Y%m%d') end
      @sota_log += '<time_on:4>' + contact.time.strftime('%H%M') if contact.time
      if contact.asset1_codes then @sota_log += '<my_sig_info:' + contact.asset1_codes.join(',').length.to_s + '>' + contact.asset1_codes.join(',') end
      if contact.asset2_codes then @sota_log += '<sig_info:' + contact.asset2_codes.join(',').length.to_s + '>' + contact.asset2_codes.join(',') end
      unless contact.signal2.nil? then @sota_log += '<rst_sent:' + contact.signal2.length.to_s + '>' + contact.signal2 end
      unless contact.signal1.nil? then @sota_log += '<rst_rcvd:' + contact.signal1.length.to_s + '>' + contact.signal1 end
      if contact.name2 then @sota_log += '<name:' + contact.name2.length.to_s + '>' + contact.name2 end
      if contact.loc_desc2 then @sota_log += '<qth:' + contact.loc_desc2.length.to_s + '>' + contact.loc_desc2 end
      if contact.loc_desc1 then @sota_log += '<my_city:' + contact.loc_desc1.length.to_s + '>' + contact.loc_desc1 end
      @sota_log += "<eor>\n"
    end
    @sota_log
  end
end
