class ConsolidatedSpot < ActiveRecord::Base

  def self.delete_old_spots
    oneweekago=Time.at(Time.now.to_i - 60 * 60 * 24 * 7).in_time_zone('UTC').to_s
    ActiveRecord::Base.connection.execute("delete from consolidated_spots where updated_at < '#{oneweekago}'")
  end

end
