require "test_helper"

class ExternalSpotTest < ActiveSupport::TestCase


test "should successfully fetch data from external APIs" do
  ExternalSpot.destroy_all
  ConsolidatedSpot.destroy_all

  VCR.use_cassette("external_spot/fetch_success") do
    # Run the controller action or model method that makes the real HTTP call
    ExternalSpot.fetch
  end

  sota = ExternalSpot.where(spot_type: 'SOTA')
  wwff = ExternalSpot.where(spot_type: 'WWFF')
  pota = ExternalSpot.where(spot_type: 'POTA')
  hema = ExternalSpot.where(spot_type: 'HEMA')
  llota = ExternalSpot.where(spot_type: 'LLOTA')

  assert_equal sota.count, 50, 'Got 50 SOTA records'
  assert_equal sota.first.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-27 06:14:04.280987000 UTC +00:00", "callsign" => "M0MZB", "activatorCallsign" => "M0MZB/P", "code" => "G/SB-010", "name" => "Housedon Hill", "frequency" => "7.12", "mode" => "QRT", "comments" => "[sotl.as]", "spot_type" => "SOTA", "epoch" => "7b8f3c3d-b089-4cbe-9f29-073dd33b2d99", "is_test" => false, "points" => "1", "altM" => "268", "is_pnp" => nil},
    "Got correct 1st SOTA spot"
  assert_equal sota.last.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-26 21:03:57.469136000 UTC +00:00", "callsign" => "KF7LIL", "activatorCallsign" => "KF7LIL", "code" => "W7A/AW-009", "name" => "Pinal Peak", "frequency" => "14.262", "mode" => "QRT", "comments" => "TU Chasers 73!!", "spot_type" => "SOTA", "epoch" => "7b8f3c3d-b089-4cbe-9f29-073dd33b2d99", "is_test" => false, "points" => "10", "altM" => "2393", "is_pnp" => nil}
    "Got correct last SOTA spot"

  assert_equal wwff.count, 64, 'Got 64 WWFF records'
  assert_equal wwff.first.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-27 05:47:50.000000000 UTC +00:00", "callsign" => "I/OK4SU/P", "activatorCallsign" => "I/OK4SU/P", "code" => "IFF-2508", "name" => "Natura 2000 - Lago di Misurina", "frequency" => "7.036", "mode" => "CW", "comments" => "", "spot_type" => "WWFF", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil},
    "Got correct 1st WWFF spot"
  assert_equal wwff.last.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-26 06:36:29.000000000 UTC +00:00", "callsign" => "SP6FRF", "activatorCallsign" => "SP6OPZ/1", "code" => "SPFF-2182", "name" => "Natura 2000 Ostoja Cedynska", "frequency" => "7.144", "mode" => "SSB", "comments" => "POTA: PL-2012 , PGA: GN06", "spot_type" => "WWFF", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil},
    "Got correct last WWFF spot"

  assert_equal pota.count, 9, 'Got 9 POTA records'
  assert_equal pota.first.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-27 06:24:51.000000000 UTC +00:00", "callsign" => "M7KOD", "activatorCallsign" => "M7KOD", "code" => "GB-1012", "name" => "Great Orme Country Park", "frequency" => "14.293", "mode" => "SSB", "comments" => "Beam Africa", "spot_type" => "POTA", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil},
    "Got correct 1st POTA spot"
  assert_equal pota.last.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-27 06:12:08.000000000 UTC +00:00", "callsign" => "JI8LHC", "activatorCallsign" => "JI8LHC/8", "code" => "JP-1015", "name" => "Nopporo Sports Prefectural Park", "frequency" => "7.006", "mode" => "", "comments" => "JCC 0117", "spot_type" => "POTA", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil},
    "Got correct last POTA spot"


  assert_equal hema.count, 10, 'Got 10 HEMA records'
  assert_equal hema.first.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-25 08:44:00.000000000 UTC +00:00", "callsign" => "HEMA_ASSISTANT", "activatorCallsign" => "5B/VK2JI/P", "code" => "5B/HCY-050", "name" => "Gerakómoutti", "frequency" => "14.285", "mode" => "SSB", "comments" => nil, "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil},
    "Got correct 1st HEMA spot"
  assert_equal hema.last.attributes.excluding(["created_at", "updated_at", "id" ]),
    {"time" => "2026-08-23 10:03:00.000000000 UTC +00:00", "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.313", "mode" => "SSB", "comments" => "Qsy", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil},
    "Got correct last HEMA spot"

  #assert_equal llota.count, 10, 'Got 10 LLOTA records'

  #check repull does not trigger duplicates
  assert_no_difference 'ExternalSpot.count' do
    VCR.use_cassette("external_spot/fetch_success") do
      # Run the controller action or model method that makes the real HTTP call
      ExternalSpot.fetch
    end
  end
end

test "should truncate overlength comments on save" do
  es = ExternalSpot.new({"time" => "2026-08-23 10:03:00.000000000 UTC +00:00", "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.313", "mode" => "SSB", "comments" => "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil})
  es.save

  assert_equal es.comments, "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345", "Comments truncated to 254 characters"
end
test "should upcase mode on save" do
  es = ExternalSpot.new({"time" => "2026-08-23 10:03:00.000000000 UTC +00:00", "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.313", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil})
  es.save

  assert_equal es.mode, "SSB", "Mode uppercase"
end

test "should create new consolidated spot" do
  t = Time.now
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.31312", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  cs=ConsolidatedSpot.last
  assert_equal cs.activatorCallsign, 'MW0KCB', "Callsign is stripped of suffix"
  assert_equal cs.mode, "SSB", "Mode uppercased"
  assert_equal cs.frequency, "14.3131", "Frequency saved and rounded"
  assert_equal cs.points, "6", "Points saved"
  assert_equal cs.altM, "1213", "Altitude saved"
  assert_equal cs.time, [t.strftime("%Y-%m-%d %H:%M:%S UTC")], "Time saved"
  assert_equal cs.code, ["GW/HNW-044"], "Code saved"
  assert_equal cs.callsign, ["M0KCB"], "Spotter call"
  assert_equal cs.name, ["Moel Fodiar"], "Site name"
  assert_equal cs.comments, ["[HEMA] M0KCB: Test spot (#{t.strftime("%H:%M:%S")})"], "comments"
  assert_equal cs.spot_type, ['HEMA'], "Spot type"
end

test "should create addditional entry in previous consolidated spot" do
  t1 = 1.minute.ago
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t1, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.31312", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  t2 = Time.now
  assert_difference 'ConsolidatedSpot.count', 0 do
    es = ExternalSpot.create({"time" => t2, "callsign" => "M1KCB", "activatorCallsign" => "MW0KCB", "code" => "GFF-0001", "name" => "Fodiar Park", "frequency" => "14.31313", "mode" => "SSB", "comments" => "Test parkspot", "spot_type" => "WWFF", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil})
  end
  cs=ConsolidatedSpot.last
  assert_equal cs.activatorCallsign, 'MW0KCB', "Callsign is stripped of suffix"
  assert_equal cs.mode, "SSB", "Mode uppercased"
  assert_equal cs.frequency, "14.3131", "Frequency saved and rounded"
  assert_equal cs.points, "6", "Points saved"
  assert_equal cs.altM, "1213", "Altitude saved"
  assert_equal cs.time, [t1.strftime("%Y-%m-%d %H:%M:%S UTC"), t2.strftime("%Y-%m-%d %H:%M:%S UTC")], "Time saved"
  assert_equal cs.code, ["GW/HNW-044", "GFF-0001"], "Code saved"
  assert_equal cs.callsign, ["M0KCB", "M1KCB"], "Spotter call"
  assert_equal cs.name, ["Moel Fodiar", "Fodiar Park"], "Site name"
  assert_equal cs.comments, ["[HEMA] M0KCB: Test spot (#{t1.strftime("%H:%M:%S")})", "[WWFF] M1KCB: Test parkspot (#{t2.strftime("%H:%M:%S")})"], "comments"
  assert_equal cs.spot_type, ['HEMA', 'WWFF'], "Spot type"
end

test "should purge old spots" do
  es = ExternalSpot.create({"time" => 2.weeks.ago, "callsign" => "M1KCB", "activatorCallsign" => "MW0KCB", "code" => "GFF-0001", "name" => "Fodiar Park", "frequency" => "14.31313", "mode" => "SSB", "comments" => "Test parkspot", "spot_type" => "WWFF", "epoch" => nil, "is_test" => nil, "points" => nil, "altM" => nil, "is_pnp" => nil})
  assert_equal ExternalSpot.count, 1, "Spot present before purge"
  ExternalSpot.delete_old_spots
  assert_equal ExternalSpot.count, 0, "Spot not present before purge"
end

test "New frequency should trigger new consolidated spot" do
  t1 = 1.minute.ago
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t1, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.31312", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  t2 = Time.now
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t2, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "21.31312", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  cs=ConsolidatedSpot.last
  assert_equal cs.activatorCallsign, 'MW0KCB', "Callsign is stripped of suffix"
  assert_equal cs.mode, "SSB", "Mode uppercased"
  assert_equal cs.frequency, "21.3131", "Frequency saved and rounded"
  assert_equal cs.points, "6", "Points saved"
  assert_equal cs.altM, "1213", "Altitude saved"
  assert_equal cs.time, [t2.strftime("%Y-%m-%d %H:%M:%S UTC")], "Time saved"
  assert_equal cs.code, ["GW/HNW-044"], "Code saved"
  assert_equal cs.callsign, ["M0KCB"], "Spotter call"
  assert_equal cs.name, ["Moel Fodiar"], "Site name"
  assert_equal cs.comments, ["[HEMA] M0KCB: Test spot (#{t2.strftime("%H:%M:%S")})"], "comments"
  assert_equal cs.spot_type, ['HEMA'], "Spot type"
end

test "New mode should trigger new consolidated spot" do
  t1 = 1.minute.ago
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t1, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.31312", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  t2 = Time.now
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t2, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.3131", "mode" => "cw", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  cs=ConsolidatedSpot.last
  assert_equal cs.activatorCallsign, 'MW0KCB', "Callsign is stripped of suffix"
  assert_equal cs.mode, "CW", "Mode uppercased"
  assert_equal cs.frequency, "14.3131", "Frequency saved and rounded"
  assert_equal cs.points, "6", "Points saved"
  assert_equal cs.altM, "1213", "Altitude saved"
  assert_equal cs.time, [t2.strftime("%Y-%m-%d %H:%M:%S UTC")], "Time saved"
  assert_equal cs.code, ["GW/HNW-044"], "Code saved"
  assert_equal cs.callsign, ["M0KCB"], "Spotter call"
  assert_equal cs.name, ["Moel Fodiar"], "Site name"
  assert_equal cs.comments, ["[HEMA] M0KCB: Test spot (#{t2.strftime("%H:%M:%S")})"], "comments"
  assert_equal cs.spot_type, ['HEMA'], "Spot type"

end

test "Delay of MAX_SPOT_CONSOLIDATION_TIME should trigger new consolidated spot for a new site" do
  t1 = 16.minutes.ago
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t1, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.3131", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
    cs=ConsolidatedSpot.last
    cs.update_column(:updated_at, 16.minutes.ago)
  end
  t2 = Time.now
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t2, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GFF-0001", "name" => "Fodiar Park", "frequency" => "14.3131", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "WWFF", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  cs=ConsolidatedSpot.last
  assert_equal cs.activatorCallsign, 'MW0KCB', "Callsign is stripped of suffix"
  assert_equal cs.mode, "SSB", "Mode uppercased"
  assert_equal cs.frequency, "14.3131", "Frequency saved and rounded"
  assert_equal cs.points, "6", "Points saved"
  assert_equal cs.altM, "1213", "Altitude saved"
  assert_equal cs.time, [t2.strftime("%Y-%m-%d %H:%M:%S UTC")], "Time saved"
  assert_equal cs.code, ["GFF-0001"], "Code saved"
  assert_equal cs.callsign, ["M0KCB"], "Spotter call"
  assert_equal cs.name, ["Fodiar Park"], "Site name"
  assert_equal cs.comments, ["[WWFF] M0KCB: Test spot (#{t2.strftime("%H:%M:%S")})"], "comments"
  assert_equal cs.spot_type, ['WWFF'], "Spot type"
end

test "Delay of MAX_SPOT_LIFETIME should trigger new consolidated spot for thre same site" do
  t1 = 61.minutes.ago
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t1, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.3131", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
    cs=ConsolidatedSpot.last
    cs.update_column(:updated_at, 61.minutes.ago)
  end
  t2 = Time.now
  assert_difference 'ConsolidatedSpot.count', 1 do
    es = ExternalSpot.create({"time" => t2, "callsign" => "M0KCB", "activatorCallsign" => "MW0KCB/P", "code" => "GW/HNW-044", "name" => "Moel Fodiar", "frequency" => "14.3131", "mode" => "ssb", "comments" => "Test spot", "spot_type" => "HEMA", "epoch" => nil, "is_test" => nil, "points" => "6", "altM" => "1213", "is_pnp" => nil})
  end
  cs=ConsolidatedSpot.last
  assert_equal cs.activatorCallsign, 'MW0KCB', "Callsign is stripped of suffix"
  assert_equal cs.mode, "SSB", "Mode uppercased"
  assert_equal cs.frequency, "14.3131", "Frequency saved and rounded"
  assert_equal cs.points, "6", "Points saved"
  assert_equal cs.altM, "1213", "Altitude saved"
  assert_equal cs.time, [t2.strftime("%Y-%m-%d %H:%M:%S UTC")], "Time saved"
  assert_equal cs.code, ["GW/HNW-044"], "Code saved"
  assert_equal cs.callsign, ["M0KCB"], "Spotter call"
  assert_equal cs.name, ["Moel Fodiar"], "Site name"
  assert_equal cs.comments, ["[HEMA] M0KCB: Test spot (#{t2.strftime("%H:%M:%S")})"], "comments"
  assert_equal cs.spot_type, ['HEMA'], "Spot type"
end

end

