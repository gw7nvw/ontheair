us=User.where('push_user_token is not null')
us.each do |u|
  pef = u.push_external_filter
  unl = UserNotificationLink.new
  unl.user_id = u.id
  unl.continents = if pef[:continent].class=='string' then [ pef[:continent] ] else pef[:continent] end
  unl.spot_types = pef[:programme]
  unl.modes = pef[:mode]
  unl.bands = pef[:band]
  unl.activator_callsign = pef[:callsign].gsub('%', '*') if pef[:callsign]
  unl.code = pef[:code].gsub('%', '*') if pef[:code]
  puts pef.to_json
  puts unl.to_json
  null_count = unl.to_json.scan(/(?=null)/).count
  if null_count<9 then
     unl.save
     puts "SAVED"
  end
  puts "=========================="
end
