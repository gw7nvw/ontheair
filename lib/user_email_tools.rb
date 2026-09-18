# frozen_string_literal: true

# typed: false
module UserEmailTools

def self.send_update_email(filename, pnp_status)
  users = User.where(pnp_status: pnp_status)   
  found = false 
  users.each do |user|
    begin
      MigrationMailer.send_notice(filename, user.email).deliver
      sleep 20
    rescue => e
      puts "ERROR sending to #{user.email}: #{e.message}"
      # Still sleep so we don't hammer the server if it's a temporary connection issue
      sleep 30 
    end
  end
  true
end

end
