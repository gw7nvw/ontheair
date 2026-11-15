module TidyUserAgentsJob
  @queue = :ota_scheduled


  def self.perform
    cutoff_time = 1.days.ago

    puts "TIDYUSERAGENTS running"
    # Target only the IDs within a small batch limit
    deleted_rows = UserAgent.where("updated_at < ?", cutoff_time)
                              .delete_all # delete_all executes direct SQL instantly

    #delete non-amateur accounts
#    ActiveRecord::Base.connection.execute("delete from comments where updated_by_id in (select id from users where not callsign ~ '[a-zA-Z0-9]{1,3}\d[a-zA-Z0-9]*[a-zA-Z]+');")
#    ActiveRecord::Base.connection.execute("delete from user_topic_links where user_id in (select id from users where not callsign ~ '[a-zA-Z0-9]{1,3}\d[a-zA-Z0-9]*[a-zA-Z]+');")
#    ActiveRecord::Base.connection.execute("delete from user_notification_links where user_id in (select id from users where not callsign ~ '[a-zA-Z0-9]{1,3}\d[a-zA-Z0-9]*[a-zA-Z]+');")
#    ActiveRecord::Base.connection.execute("delete from users where not callsign ~ '[a-zA-Z0-9]{1,3}\d[a-zA-Z0-9]*[a-zA-Z]+';")


    puts "TIDYUSERAGENTS completed"
  end
end
