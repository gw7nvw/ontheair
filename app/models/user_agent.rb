class UserAgent < ActiveRecord::Base

  validates :user_agent, uniqueness: { scope: :user_ip }
  WINDOW_SECONDS = 86400

  # A safe, atomic way to increment the hits without race conditions
  def self.track(ua_string, ip_addr, suspicious = 0, request_type)

    if suspicious>0
       logger.info "SUSPISCIOUS!!!!!"
    end

    # Use Rails 4upsert equivalent logic (Find or create, then increment atomically)
    begin
    record = find_or_create_by!(user_agent: ua_string, user_ip: ip_addr)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      # 2. If a concurrent request created it first, catch the error and fetch it
      record = find_by!(user_agent: ua_string, user_ip: ip_addr)
    end
    current_time = Time.now
    cutoff_time = current_time - WINDOW_SECONDS

    html_inc = (request_type == :html) ? 1 : 0
    js_inc   = (request_type == :js) ? 1 : 0

logger.info "RECORD TIME: #{record.updated_at.to_i.to_s}, cutoff: #{cutoff_time.to_i.to_s}"
    if record.updated_at < cutoff_time
      logger.info "EXPUNGING OLD RECORD !!!!!!"
      # Window expired: Reset counters and bring timestamp to now
      record.update_columns(
        access_count: 1,
        suspicious_access_count: 0,
        html_count: html_inc,
        js_count: js_inc,
        confirmed_bot: false,
        suspected_bot: false,
        confirmed_human: false,
        updated_at: current_time
      )
    else
      # Within window: Atomically increment counts AND update timestamp
      where(id: record.id).update_all([
        "access_count = COALESCE(access_count, 0) + 1, 
         suspicious_access_count = COALESCE(suspicious_access_count, 0) + ?, 
         html_count = COALESCE(html_count, 0) + ?,
         js_count = COALESCE(js_count, 0) + ?,
         updated_at = ?", 
        suspicious, html_inc, js_inc, current_time
      ])
    end

    return record

    rescue ActiveRecord::RecordNotUnique
    # Gracefully handle race conditions if two matching agents hit at the microsecond
    retry
  end
end
