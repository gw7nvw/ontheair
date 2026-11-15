utls=UserTopicLink.where(topic_id: SPOT_TOPIC, mail: true)
bad_ids=[]
utls.each do |utl|
  u = User.find_by(id: utl.user_id)
  if !u
    bad_ids << utl.user_id
    next
  end
  unl = UserNotificationLink.new
  unl.notification_type=NOTIFICATION_EMAIL
  unl.user_id = u.id
  unl.continents = ["OC"]
  unl.activator_callsign = u.callsign[0..1]+"*"
  puts unl.to_json
  unl.save
  puts "=========================="
end
bad_ids
