require "test_helper"

class LogImportAdifTest < ActiveSupport::TestCase
    ADIF_HEADER="
ADIF Export from ADIFMaster v[3.4]
http://www.dxshell.com
Copyright (C) 2005 - 2022 UU0JC, DXShell.com
File generated on 03 Feb, 2023 at 07:11
<ADIF_VER:5>3.1.2
<PROGRAMID:10>ADIFMaster
<PROGRAMVERSION:3>3.4
<EOH>
"
  ADIF_ENTRY="
<BAND:3>40m <CALL>CALLSIGN2 <COUNTRY:11>New Zealand <FREQ:5>7.090 <MODE:3>SSB <SIG:4>WWFF <SIG_INFO>ASSET2 <MY_SIG:4>POTA <MY_SIG_INFO>ASSET1 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <QSO_DATE_OFF:8>20230202 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>221710 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
"


  test "asset inherits child assets when requested" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'hut', location: create_point(174,-44))
    asset4=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)

    logstring=ADIF_HEADER+ADIF_ENTRY
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset3.code)

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes.sort, [asset1.code, asset2.code].sort
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code, asset2.code].sort
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes.sort, [asset3.code, asset4.code].sort
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "asset does not inherit child assets when do_not_lookup requested" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'hut', location: create_point(174,-44))
    asset4=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)

    logstring=ADIF_HEADER+ADIF_ENTRY
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset3.code)

    logs=Log.import('adif',user1,logstring,user1, nil , nil, false, false, true)#do_not_lookup


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code], "Logging party does not imherit"
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code], "Logging party does not imherit"
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset3.code, asset4.code].sort, "Othe rparty does still inherit"
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end
end
