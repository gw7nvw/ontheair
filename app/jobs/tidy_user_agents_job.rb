module TidyUserAgentsJob
  @queue = :ota_scheduled


  def self.perform
    cutoff_time = 5.days.ago
    batch_size  = 1000 # Small, safe chunk size

    # Loop and delete in batches to prevent long table/index locks
    loop do
      # Target only the IDs within a small batch limit
      deleted_rows = UserAgent.where('updated_at < ?', cutoff_time)
                              .limit(batch_size)
                              .delete_all # delete_all executes direct SQL instantly

      # Break the loop once there are no more old records left to delete
      break if deleted_rows < batch_size

      # Optional: Sleep for a fraction of a second to give the database breathing room
      sleep 0.1 
    end
  end
end
