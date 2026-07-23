module TidyUserAgentsJob
  @queue = :ota_scheduled


  def self.perform
    cutoff_time = 1.days.ago

    puts "TIDYUSERAGENTS running"
    # Target only the IDs within a small batch limit
    deleted_rows = UserAgent.where('updated_at < ?', cutoff_time)
                              .delete_all # delete_all executes direct SQL instantly

    puts "TIDYUSERAGENTS completed"
  end
end
