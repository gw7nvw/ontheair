# test/unit/email_receiver_test.rb
require 'test_helper'
require_relative '../../lib/email_receiver'

class EmailReceiverTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "should parse incoming inreach spot email and add to consolidated spots" do
    user1=create_test_user
    user1.firstname="test"
    user1.lastname="user"
    user1.save

    asset1=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-')

    # 1. Prepare raw incoming email text
    raw_email = <<~EMAIL
From: "#{user1.firstname.upcase} #{user1.lastname.capitalize}" <no.reply.inreach@garmin.com>
To: spot@ontheair.nz
Subject: SOTA Spot

#{user1.callsign} #{user1.pin} ! #{asset1.code} 3.690 SSB On air in 5 mins inr.ch

View the location or send a reply to MATT Briggs:
https://inreachlink.com/gXEz7VFcBQ2gprFcgnXMmwQ



Do not reply directly to this message.

This message was sent to you using the inReach two-way satellite communicat=
or with GPS. To learn more, visit http://explore.garmin.com/inreach.
    EMAIL

    # 2. Assert that running the parser triggers your model creation instantly!
    # (Swap 'ExternalSpot' below with whatever your self.perform method builds)
    assert_difference 'ConsolidatedSpot.count', 1, "The email failed to create a spot record inline" do
      EmailReceive.new(raw_email)
    end

    # 3. Verify the record properties match the parsed email fields
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal user1.callsign, newest_spot.activatorCallsign
    assert_equal newest_spot.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"callsign" => ["#{user1.callsign}"],"activatorCallsign" => "#{user1.callsign}","code" => ["#{asset1.code}"],"name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"],"frequency" => "3.69","mode" => "SSB","spot_type" => ["WWFF"],"points" => nil,"altM" => nil,"old_spot_type" => [],"band" => "80m","dxcc" => "ZL","continent" => "OC"},
    "Wrong parameters in spot"
    assert_match /#{user1.callsign}: On air in 5 mins \(via InReach\) \(.+\)/, newest_spot.comments.first
  end

  test "should parse incoming sotamat spot email and add to consolidated spots" do
    user1=create_test_user
    user1.firstname="test"
    user1.lastname="user"
    user1.save

    asset1=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-')

    # 1. Prepare raw incoming email text (note any PIN is good, here, users do not want to use real pin via SOTAmat)
    raw_email = <<~EMAIL
From: "#{user1.firstname.upcase} #{user1.lastname.capitalize}" <no.reply.inreach@garmin.com>
To: spot@ontheair.nz
Subject: Predefined 1-way message from SOTAmat user #{user1.callsign}

Some sotamat-related bumph goes here
/bom #{user1.callsign} 1234 ! #{asset1.code} 3.690 SSB On air in 5 mins /eom

More sotamat-related bumph goes here
    EMAIL

    # 2. Assert that running the parser triggers your model creation instantly!
    # (Swap 'ExternalSpot' below with whatever your self.perform method builds)
    assert_difference 'ConsolidatedSpot.count', 1, "The email failed to create a spot record inline" do
      EmailReceive.new(raw_email)
    end

    # 3. Verify the record properties match the parsed email fields
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal user1.callsign, newest_spot.activatorCallsign
    assert_equal newest_spot.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"callsign" => ["#{user1.callsign}"],"activatorCallsign" => "#{user1.callsign}","code" => ["#{asset1.code}"],"name" => ["#{asset1.name} [#{asset1.code}] {RE44nt}"],"frequency" => "3.69","mode" => "SSB","spot_type" => ["WWFF"],"points" => nil,"altM" => nil,"old_spot_type" => [],"band" => "80m","dxcc" => "ZL","continent" => "OC"},
    "Wrong parameters in spot"
    assert_match /#{user1.callsign}: On air in 5 mins \(via SOTAmat\) \(.+\)/, newest_spot.comments.first
  end

  test "should parse incoming inreach alert email and add to consolidated spots" do
    user1=create_test_user
    user1.firstname="test"
    user1.lastname="user"
    user1.save

    asset1=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-')

    t1=2.hours.from_now.change(sec:0)
    # 1. Prepare raw incoming email text
    raw_email = <<~EMAIL
From: "#{user1.firstname.upcase} #{user1.lastname.capitalize}" <no.reply.inreach@garmin.com>
To: alert@ontheair.nz
Subject: SOTA Alert

#{user1.callsign} #{user1.pin} ! #{asset1.code} 3.690 SSB #{t1.strftime("%Y-%m-%d %H:%M")} time +/- inr.ch

View the location or send a reply to MATT Briggs:
https://inreachlink.com/gXEz7VFcBQ2gprFcgnXMmwQ



Do not reply directly to this message.

This message was sent to you using the inReach two-way satellite communicat=
or with GPS. To learn more, visit http://explore.garmin.com/inreach.
    EMAIL

    # 2. Assert that running the parser triggers your model creation instantly!
    # (Swap 'ExternalSpot' below with whatever your self.perform method builds)
    assert_difference 'Post.count', 1, "The email failed to create an alert record inline" do
      EmailReceive.new(raw_email)
    end

    # 3. Verify the record properties match the parsed email fields
    newest_alert = Post.order(created_at: :desc).first
    assert_equal newest_alert.attributes.excluding(["created_at", "updated_at", "id", "time", "comments", "post_id"]),
      {"title" => "ALERT: #{user1.callsign} going portable to #{asset1.name} [#{asset1.code}] on 3.690/SSB at #{t1.strftime("%Y-%m-%d %H:%M UTC")}", "description" => "time +/- (via InReach)", "created_by_id" => user1.id, "updated_by_id" => user1.id, "filename" => nil, "image_file_name" => nil, "image_content_type" => nil, "image_file_size" => nil, "image_updated_at" => nil, "do_not_publish" => nil, "referenced_datetime" => nil, "referenced_date" => t1.to_date, "referenced_time" => t1, "duration" => nil, "site" => "#{asset1.name} [#{asset1.code}] {RE44nt}", "code" => nil, "mode" => "SSB", "freq" => "3.690", "is_hut" => nil, "is_park" => nil, "is_island" => nil, "is_summit" => nil, "hut" => nil, "park" => nil, "island" => nil, "summit" => nil, "callsign" => user1.callsign, "asset_codes" => [asset1.code], "user_id" => nil, "do_not_lookup" => nil, "location" => nil, "loc_source" => nil}  
    "Wrong parameters in alert"
  end

  test "should parse incoming inreach zlsota email and forward to mailing list" do
    user1=create_test_user
    user1.firstname="test"
    user1.lastname="user"
    user1.save

    t1=2.hours.from_now.change(sec:0)
    # 1. Prepare raw incoming email text
    raw_email = <<~EMAIL
From: "#{user1.firstname.upcase} #{user1.lastname.capitalize}" <no.reply.inreach@garmin.com>
To: zlsota@ontheair.nz
Subject: Inreach message from #{user1.firstname.upcase} #{user1.lastname.capitalize}

Free text email

View the location or send a reply to MATT Briggs:
https://inreachlink.com/gXEz7VFcBQ2gprFcgnXMmwQ



Do not reply directly to this message.

This message was sent to you using the inReach two-way satellite communicat=
or with GPS. To learn more, visit http://explore.garmin.com/inreach.
    EMAIL

    assert_emails 1 do
      EmailReceive.new(raw_email)
    end

    sent_emails = ActionMailer::Base.deliveries

    # 3. Assert the recipients match your subscriber array values perfectly
    assert_equal ["zl-sota@groups.io"], sent_emails.last.to
    assert_match /Free text email/, sent_emails.last.body.encoded
  end

  test "should look up containing parks by default for spots / alerts" do
    user1=create_test_user
    user1.firstname="test"
    user1.lastname="user"
    user1.save

    asset1=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-')
    asset2=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.2, code_prefix: 'ZLFF-')

    # 1. Prepare raw incoming email text
    raw_email = <<~EMAIL
From: "#{user1.firstname.upcase} #{user1.lastname.capitalize}" <no.reply.inreach@garmin.com>
To: spot@ontheair.nz
Subject: SOTA Spot

#{user1.callsign} #{user1.pin} ! #{asset1.code} 3.690 SSB On air in 5 mins inr.ch

View the location or send a reply to MATT Briggs:
https://inreachlink.com/gXEz7VFcBQ2gprFcgnXMmwQ



Do not reply directly to this message.

This message was sent to you using the inReach two-way satellite communicat=
or with GPS. To learn more, visit http://explore.garmin.com/inreach.
    EMAIL

    # 2. Assert that running the parser triggers your model creation instantly!
    # (Swap 'ExternalSpot' below with whatever your self.perform method builds)
    assert_difference 'ConsolidatedSpot.count', 1, "The email failed to create a spot record inline" do
      EmailReceive.new(raw_email)
    end

    # 3. Verify the record properties match the parsed email fields
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal user1.callsign, newest_spot.activatorCallsign
    assert_equal newest_spot.code, [asset1.code, asset2.code],
    "Both contained and containing code listed"
  end

  test "should ignore containing parks when requested" do
    user1=create_test_user
    user1.firstname="test"
    user1.lastname="user"
    user1.save

    asset1=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-')
    asset2=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.2, code_prefix: 'ZLFF-')

    # 1. Prepare raw incoming email text
    raw_email = <<~EMAIL
From: "#{user1.firstname.upcase} #{user1.lastname.capitalize}" <no.reply.inreach@garmin.com>
To: spot@ontheair.nz
Subject: SOTA Spot

#{user1.callsign} #{user1.pin} ! #{asset1.code} 3.690 SSB On air in 5 mins /DNL inr.ch

View the location or send a reply to MATT Briggs:
https://inreachlink.com/gXEz7VFcBQ2gprFcgnXMmwQ



Do not reply directly to this message.

This message was sent to you using the inReach two-way satellite communicat=
or with GPS. To learn more, visit http://explore.garmin.com/inreach.
    EMAIL

    # 2. Assert that running the parser triggers your model creation instantly!
    # (Swap 'ExternalSpot' below with whatever your self.perform method builds)
    assert_difference 'ConsolidatedSpot.count', 1, "The email failed to create a spot record inline" do
      EmailReceive.new(raw_email)
    end

    # 3. Verify the record properties match the parsed email fields
    newest_spot = ConsolidatedSpot.order(created_at: :desc).first
    assert_equal user1.callsign, newest_spot.activatorCallsign
    assert_equal newest_spot.code, [asset1.code],
    "Only contained code listed"
  end

  # test/unit/email_receiver_test.rb

test "should authenticate user via subject and extract attached ADIF log file text cleanly" do
  user=users(:zl4test)
  uc2=create_callsign(user, {callsign: 'ZL4TEST'})

  # 1. Resolve the path to your log fixture file dynamically
  fixture_path = Rails.root.join('test', 'fixtures', 'files', 'logs', 'zl2dr.adi')
  
  # 2. Read the raw ADIF file contents from disk
  adif_content = File.read(fixture_path)

  # 2. Construct the raw multipart MIME email string mimicking an incoming user upload
  raw_upload_email = <<~EMAIL
    MIME-Version: 1.0
    From: operator@nzart.org.nz
    To: logs@ontheair.nz
    Subject: ZLOTA:#{user.callsign}:#{user.pin}
    Content-Type: multipart/mixed; boundary="adif-upload-boundary"

    --adif-upload-boundary
    Content-Type: text/plain; charset=UTF-8

    Please process my appended weekend operational activator logs.

    --adif-upload-boundary
    Content-Type: application/octet-stream; name="activation_log.adi"
    Content-Disposition: attachment; filename="activation_log.adi"

    #{adif_content}
    --adif-upload-boundary--
  EMAIL

  assert_difference 'Log.count', 1, "The email failed to create a log record" do
    EmailReceive.new(raw_upload_email)
  end
  # 3. Verify the record properties match the parsed email fields
  log = Log.order(created_at: :desc).first

      #log created
    assert_equal user.id, log.user1_id, "User ID"
    assert_equal ['NZ-0001', 'ZL3/CB-001'].sort, log.asset_codes.sort, "Asset codes"
    assert_equal ['pota park', 'summit'].sort, log.asset_classes.sort, "Asset classes"
    assert_equal user.callsign, log.callsign1, "Callsign"
    assert_equal true, log.is_portable1, "Portable"

    #contacts created
    assert_equal 2, log.contacts.count, "Correct # contacts"
    contacts=log.contacts.order(:time)

    #1st entry correct
    assert_equal "10m", contacts[0].band, "Band"
    assert_equal 28.39, contacts[0].frequency, "Freq"
    assert_equal 'SSB', contacts[0].mode, "Mode"
    assert_equal "K6ARK", contacts[0].callsign2, "Callsign"
    assert_equal "2023-11-04", contacts[0].date.strftime("%Y-%m-%d"), "Date"
    assert_equal "01:32", contacts[0].time.strftime("%H:%M"), "Time"
    assert_equal "55", contacts[0].signal1, "Signal1"
    assert_equal "55", contacts[0].signal2, "Signal1"
    assert_equal ["W6/SD396"], contacts[0].asset2_codes, "Asset2_codes"
    assert_equal ['NZ-0001', 'ZL3/CB-001'], contacts[0].asset1_codes.sort, "Asset1_codes"
    assert_equal "ESTIMATED RSTS BY EAR-OMETER ON G90", contacts[0].comments1, "Comment1"

    #rest of entries exist
    assert_equal "VK4MWL", contacts[1].callsign2, "Callsign"

  end

test "should authenticate user via subject and reject log if not matching" do
  user=users(:zl4test)
  uc2=create_callsign(user, {callsign: 'ZL4TEST'})

  # 1. Resolve the path to your log fixture file dynamically
  fixture_path = Rails.root.join('test', 'fixtures', 'files', 'logs', 'zl2dr.adi')

  # 2. Read the raw ADIF file contents from disk
  adif_content = File.read(fixture_path)

  # 2. Construct the raw multipart MIME email string mimicking an incoming user upload
  raw_upload_email = <<~EMAIL
    MIME-Version: 1.0
    From: operator@nzart.org.nz
    To: logs@ontheair.nz
    Subject: ZLOTA:#{user.callsign}:4444
    Content-Type: multipart/mixed; boundary="adif-upload-boundary"

    --adif-upload-boundary
    Content-Type: text/plain; charset=UTF-8

    Please process my appended weekend operational activator logs.

    --adif-upload-boundary
    Content-Type: application/octet-stream; name="activation_log.adi"
    Content-Disposition: attachment; filename="activation_log.adi"

    #{adif_content}
    --adif-upload-boundary--
  EMAIL

  assert_difference 'Log.count', 0, "The email created a log record when it should have been rejected" do
    EmailReceive.new(raw_upload_email)
  end
end
end


