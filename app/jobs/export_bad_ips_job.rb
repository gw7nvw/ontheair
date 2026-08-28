# app/jobs/export_bad_ips_job.rb
class ExportBadIpsJob
  @queue = :ota_scheduled

  def self.perform
    file_path = '/tmp/bad_ips.txt'
    
    # Pluck directly to avoid loading thousands of ActiveRecord objects into memory
    ips = UserAgent.where('confirmed_bot = true and updated_at >= ?', 24.hours.ago).pluck(:user_ip)
    
    File.open(file_path, 'w') do |file|
      ips.each { |ip| file.puts ip }
    end
  end
end
