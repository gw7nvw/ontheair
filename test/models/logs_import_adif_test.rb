# typed: strict
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

  test "Log contact imported successfully" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring=ADIF_HEADER+ADIF_ENTRY
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset2.code)

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "Log imports multiple contacts successfully" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset

    entry1=ADIF_ENTRY
    entry2=ADIF_ENTRY
    entry1=entry1.gsub("CALLSIGN2",user2.callsign)
    entry1=entry1.gsub("ASSET2",asset2.code)
    entry2=entry2.gsub("CALLSIGN2",user3.callsign)
    entry2=entry2.gsub("ASSET2",asset3.code)
    logstring=ADIF_HEADER+entry1+entry2
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 2, "two contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 2, "Really is two contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
    contact=contacts[1]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user3.id
    assert_equal contact.callsign2, user3.callsign
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "can handle no header" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring=ADIF_ENTRY
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset2.code)

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090

  end

 test "Newline instead of EOR" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset

    entry1=ADIF_ENTRY
    entry2=ADIF_ENTRY
    entry1=entry1.gsub("CALLSIGN2",user2.callsign)
    entry1=entry1.gsub("ASSET2",asset2.code)
    entry2=entry2.gsub("CALLSIGN2",user3.callsign)
    entry2=entry2.gsub("ASSET2",asset3.code)
    logstring=entry1+entry2
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("<EOR>","\n")

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 2, "two contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 2, "Really is two contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
    contact=contacts[1]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user3.id
    assert_equal contact.callsign2, user3.callsign
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "can handle unknown user2 and unknown asset2" do
    user1=create_test_user
    asset1=create_test_asset
    logstring=ADIF_HEADER+ADIF_ENTRY
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",'VK2IO')
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",'VKFF-0001')

    logs=Log.import('adif',user1,logstring,user1)

    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    user2=User.find_by(callsign: 'VK2IO')
    assert_equal "VK2IO", user2.callsign
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, ['VKFF-0001']
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end


  test "can handle vk assets" do
    user1=create_test_user
    asset1=create_test_vkasset(award: 'WWFF', code_prefix: 'VKFF-0')
    asset2=create_test_vkasset(award: 'SOTA', code: 'VK3/CB-001', location: create_point(148.79, -35.61))

    logstring=ADIF_HEADER+ADIF_ENTRY
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",'VK2IO')
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset2.code)

    logs=Log.import('adif',user1,logstring,user1)

    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    user2=User.find_by(callsign: 'VK2IO')
    assert_equal "VK2IO", user2.callsign
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "rejects contact with no date" do
    user1=create_test_user
    user2=create_test_user

  logstring="
<BAND:3>40m <CALL>CALLSIGN2 <COUNTRY:11>New Zealand <FREQ:5>7.090 <GRIDSQUARE:6>RE78kp <MODE:3>SSB <MY_GRIDSQUARE:6>RE56us <SIG:4>WWFF <SIG_INFO>ASSET2 <MY_SIG:4>POTA <MY_SIG_INFO>ASSET1 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
"
    logstring=logstring.gsub('CALLSIGN1', user1.callsign)

    logs=Log.import('adif',user1,logstring,user1)

    assert_equal logs[:success], true, "Sucessful exit"
    assert_not_equal logs[:errors].count, 0, "Errors found"
    assert_includes logs[:errors].to_json, '"Record 1: Save contact 0 failed: no date/time"', "Date error raised"
    assert_equal logs[:good_logs], 0, "No log"
    assert_equal logs[:good_contacts], 0, "no contact"
    assert_equal logs[:logs].count, 0, "Really is no log"
  end

  test "rejects contact for another call" do
    user1=create_test_user
    user2=create_test_user

    logstring=ADIF_ENTRY
    logstring=logstring.gsub('CALLSIGN1', 'ZL1BAD')
    user1=create_test_user
    user2=create_test_user
    logs=Log.import('adif',user1,logstring,user1)

    assert_equal logs[:success], true, "Sucessful exit"
    assert_not_equal logs[:errors].count, 0, "Errors found"
    assert_match /callsign not registered/, logs[:errors].first,  "Callsign error raised"
    assert_equal logs[:good_logs], 0, "No log"
    assert_equal logs[:good_contacts], 0, "no contact"
    assert_equal logs[:logs].count, 0, "Really is no log"
  end

  test "continue after bad contact entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset


    logstring=ADIF_ENTRY
    logstring=logstring.gsub('CALLSIGN1', 'ZL1BAD')
    logstring2=ADIF_ENTRY
    logstring2=logstring2.gsub('CALLSIGN1', user1.callsign)
    logstring=logstring+logstring2
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset2.code)
    logs=Log.import('adif',user1,logstring,user1, nil, nil, false, true) #coontinue_onerror=true
    assert_equal logs[:success], true, "Sucessful exit"
    assert_not_equal logs[:errors].count, 0, "Errors found"
    assert_match /callsign not registered/, logs[:errors].first,  "Callsign error raised"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "One contact"
    assert_equal logs[:logs].count, 1, "Really is one log"

    log=logs[:logs].first
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090

   end

  test "allows contacts for secondary call" do
    user1=create_test_user
    user2=create_test_user
    uc1=create_callsign(user1)
    uc2=create_callsign(user2)

    asset1=create_test_asset
    asset2=create_test_asset

    logstring=ADIF_HEADER+ADIF_ENTRY
    logstring=logstring.gsub("CALLSIGN1",uc1.callsign)
    logstring=logstring.gsub("CALLSIGN2",uc2.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset2.code)

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, uc1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, uc1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, uc2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end
 
  test "allows chaser log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset

  logstring="
<BAND:3>40m <CALL>CALLSIGN2 <COUNTRY:11>New Zealand <FREQ:5>7.090 <GRIDSQUARE:6>RE78kp <MODE:3>SSB <MY_GRIDSQUARE:6>RE56us <SIG:4>WWFF <SIG_INFO>ASSET2 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <QSO_DATE_OFF:8>20230202 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>221710 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
"

    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("ASSET2",asset1.code)

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, []
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, []
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset1.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "rejects contact with no location for either party" do
    user1=create_test_user
    user2=create_test_user

  logstring="
<BAND:3>40m <CALL>CALLSIGN2 <COUNTRY:11>New Zealand <FREQ:5>7.090 <MODE:3>SSB <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <QSO_DATE_OFF:8>20230202 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>221710 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
"
    logstring=logstring.gsub('CALLSIGN1', user1.callsign)

    logs=Log.import('adif',user1,logstring,user1)

    assert_equal logs[:success], true, "Sucessful exit"
    assert_not_equal logs[:errors].count, 0, "Errors found"
    assert_match /no activation location/, logs[:errors].first,  "Errored for no location"
    assert_equal logs[:good_logs], 0, "No log"
    assert_equal logs[:good_contacts], 0, "no contact"
    assert_equal logs[:logs].count, 0, "Really is no log"
  end

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

  test "only known callsigns saved when requested" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset

    entry1=ADIF_ENTRY
    entry2=ADIF_ENTRY
    entry1=entry1.gsub("CALLSIGN2",user2.callsign)
    entry1=entry1.gsub("ASSET2",asset2.code)
    entry2=entry2.gsub("CALLSIGN2",'VK3UNK')
    entry2=entry2.gsub("ASSET2",asset3.code)
    logstring=ADIF_HEADER+entry1+entry2
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)

    logs=Log.import('adif',user1,logstring,user1,nil,nil,true)#do not create


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "can specify callsign and location (none in log)" do
    user1=create_test_user
    user2=create_test_user

  logstring="
<BAND:3>40m <COUNTRY:11>New Zealand <FREQ:5>7.090  <MODE:3>SSB <SIG:4>WWFF <SIG_INFO>ASSET2 <NAME:10>J E BONNEY <CALL>CALLSIGN2 <QSO_DATE:8>20230202 <QSO_DATE_OFF:8>20230202 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>221710 <TX_PWR:3>100 <EOR>
"
    logstring=logstring.gsub('CALLSIGN2', user2.callsign)
    logstring=logstring.gsub('ASSET2', 'VKFF-0002')

    logs=Log.import('adif',user1,logstring,user1,  user1.callsign, 'VKFF-0001')

    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, ['VKFF-0001']
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, ['VKFF-0001']
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, ['VKFF-0002']
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "length parameter works ok" do
    user1=create_test_user
    user2=create_test_user

#logstign with extra characters after asset and freq
  logstring="
<BAND:3>40m <CALL>CALLSIGN2 <COUNTRY:11>New Zealand <FREQ:5>7.09011 <GRIDSQUARE:6>RE78kp <MODE:3>SSB <MY_GRIDSQUARE:6>RE56us <SIG:4>WWFF <SIG_INFO:9>VKFF-000223 <MY_SIG:4>POTA <MY_SIG_INFO:9>VKFF-000123 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <QSO_DATE_OFF:8>20230202 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>221710 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
"
    logstring=logstring.gsub('CALLSIGN1', user1.callsign)
    logstring=logstring.gsub('CALLSIGN2', user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)

    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, ['VKFF-0001']
    assert_equal log.date.to_date, '2023-02-02'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, ['VKFF-0001']
    assert_equal contact.date.to_date, '2023-02-02'.to_date
    assert_equal contact.time.to_time, '2023-02-02 22:17'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, ['VKFF-0002']
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090
  end

  test "logs broken down by day and location1" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset

    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <COUNTRY:11>New Zealand <FREQ:7>144.500 <GRIDSQUARE:6>RE78kp <MODE:2>FM <MY_GRIDSQUARE:6>RE56us <SIG:4>WWFF <SIG_INFO>ASSET2 <MY_SIG:4>POTA <MY_SIG_INFO>ASSET1 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20240829 <QSO_DATE_OFF:8>20240829 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>000000 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
<BAND:3>40m <CALL>CALLSIGN3 <COUNTRY:11>New Zealand <FREQ:5>7.090 <GRIDSQUARE:6>RE78kp <MODE:3>SSB <MY_GRIDSQUARE:6>RE56us <SIG:4>WWFF <SIG_INFO>ASSET3 <MY_SIG:4>POTA <MY_SIG_INFO>ASSET2 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20240829 <QSO_DATE_OFF:8>20240829 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>060000 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
<BAND:3>40m <CALL>CALLSIGN2 <COUNTRY:11>New Zealand <FREQ:6>14.090 <GRIDSQUARE:6>RE78kp <MODE:3>SSB <MY_GRIDSQUARE:6>RE56us <SIG:4>WWFF <SIG_INFO>ASSET3 <MY_SIG:4>POTA <MY_SIG_INFO>ASSET2 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20240830 <QSO_DATE_OFF:8>20240830 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>060000 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
<BAND:3>40m <CALL>CALLSIGN3 <COUNTRY:11>New Zealand <FREQ:5>7.090 <GRIDSQUARE:6>RE78kp <MODE:2>AM <MY_GRIDSQUARE:6>RE56us <SIG:4>WWFF <SIG_INFO>ASSET3 <MY_SIG:4>POTA <MY_SIG_INFO>ASSET2 <NAME:10>J E BONNEY <OPERATOR>CALLSIGN1 <QSO_DATE:8>20240830 <QSO_DATE_OFF:8>20240830 <QTH:10>RD3 WINTON <RST_RCVD:2>55 <RST_SENT:2>59 <TIME_ON:6>070000 <TX_PWR:3>100 <STATION_CALLSIGN>CALLSIGN1 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("CALLSIGN3",user3.callsign)
    logstring=logstring.gsub("ASSET1",asset1.code)
    logstring=logstring.gsub("ASSET2",asset2.code)
    logstring=logstring.gsub("ASSET3",asset3.code)

    logs=Log.import('adif',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 3, "Three log"
    assert_equal logs[:good_contacts], 4, "four contact"
    assert_equal logs[:logs].count, 3, "Really is three log"
    log=logs[:logs].first
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-29'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts[0]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-29'.to_date
    assert_equal contact.time, '2024-08-29 00:00'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.mode, 'FM'
    assert_equal contact.frequency, 144.500

    log=logs[:logs][1]
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset2.code], "New location, new log"
    assert_equal log.date, '2024-08-29'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts[0]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset2.code]
    assert_equal contact.date, '2024-08-29'.to_date
    assert_equal contact.time, '2024-08-29 06:00'.to_time
    assert_equal contact.user2_id, user3.id
    assert_equal contact.callsign2, user3.callsign
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7.090

    log=logs[:logs][2]
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset2.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 2, "Really is two contact"
    contact=contacts[0]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset2.code]
    assert_equal contact.date, '2024-08-30'.to_date, "New date, new log"
    assert_equal contact.time, '2024-08-30 06:00'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 14.090
    contact=contacts[1]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset2.code], "Same asset, same log"
    assert_equal contact.date, '2024-08-30'.to_date, "Same day, same log"
    assert_equal contact.time, '2024-08-30 07:00'.to_time
    assert_equal contact.user2_id, user3.id
    assert_equal contact.callsign2, user3.callsign
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.mode, 'AM'
    assert_equal contact.frequency, 7.090
  end

  #altitude->altitiude2
  test "parameter combinations and formats: altitude" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <ALTITUDE:3>173 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 173, contact.altitude2
  end

  #freq, band->freq, band
  test "parameter combinations and formats: frequency, band" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 7.0, contact.frequency
    assert_equal "40m", contact.band

    #just freq
    logstring="
<FREQ:5>7.090 <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 7.09, contact.frequency
    assert_equal "40m", contact.band

    #frequency preferred to band
    logstring="
<FREQ:5>7.090 <BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 7.09, contact.frequency
    assert_equal "40m", contact.band

    #frequency preferred to band (try reverse order)
    logstring="
<BAND:3> 40m <FREQ:5>7.090 <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 7.09, contact.frequency
    assert_equal "40m", contact.band
  end

  #call->callsign2
  test "parameter combinations and formats: call" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <ALTITUDE:3>173 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal user2.callsign, contact.callsign2
  end

  # city+ region+state+country+qth, -> loc_desc2
  test "parameter combinations and formats: qth" do
    user1=create_test_user
    user2=create_test_user
    #all params
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <CITY>Sheffield <STATE>South Island <COUNTRY>NZ <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal "Sheffield, South Island, NZ", contact.loc_desc2

    #just some params and use QTH in place of CITY
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <QTH>Sheffield <COUNTRY>NZ<EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal "Sheffield, NZ", contact.loc_desc2
  end

  test "parameter combinations and formats (lat, lon, maidenhead)" do
  #(lat_lon),gridsquare -> location2
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <LAT>S045 30.0 <LON>E173 30.0<EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'POINT (173.5 -45.5)', contact.location2.to_s
    assert_equal "user", contact.loc_source2

    #MAIDENHEAD
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <GRIDSQUARE>RE45 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'POINT (168.0 -45.0)', contact.location2.to_s
    assert_equal "user", contact.loc_source2

    #lat,lon preferred
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <LAT>S045 30.0 <LON>E173 30.0 <GRIDSQUARE>RE45 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'POINT (173.5 -45.5)', contact.location2.to_s
    assert_equal "user", contact.loc_source2

  end

  #mode
  test "parameter combinations and formats (mode)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'SSB', contact.mode
end


test "parameter combinations and formats (name)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <NAME>FRED <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'FRED', contact.name2
  end
  #notes -> comments2
  test "parameter combinations and formats (notes)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <NOTES>This is a comment <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'This is a comment', contact.comments2
  end

  test "parameter combinations and formats (pota_ref, sota_ref, wwff_ref, sig_info)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <POTA_REF>AU-0001 <WWFF_REF>VKFF-0001 <SOTA_REF>VK1/AC-001 <SIG_INFO>VK-GRY1 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal ['AU-0001', 'VKFF-0001', 'VK1/AC-001', 'VK-GRY1'].sort, contact.asset2_codes.sort, "All programme references included"

    #2-FER
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <POTA_REF>AU-0002, AU-0001 <WWFF_REF>VKFF-0001 <SOTA_REF>VK1/AC-001 <SIG_INFO>VK-GRY1 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal ['AU-0001', 'AU-0002',  'VKFF-0001', 'VK1/AC-001', 'VK-GRY1'].sort, contact.asset2_codes.sort, "All programme references included"

  end

  #rig 
  test "parameter combinations and formats (rig)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <RIG>Kenwood TS440 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'Kenwood TS440', contact.transceiver2
  end

  #rst_sent
  test "parameter combinations and formats (rst_sent)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <RST_SENT>59 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal '59', contact.signal2
  end

  #rx_pwr -> power2
  test "parameter combinations and formats (rx_pwr)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <RX_PWR>100 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 100, contact.power2
  end

  #time_on, time_off -> time
  test "parameter combinations and formats (time_on, time_off)" do
    user1=create_test_user
    user2=create_test_user

    #TIME OFF - HHMM
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE_OFF:8>20230202 <TIME_OFF>1012 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal '2023-02-02 10:12', contact.time.strftime('%Y-%m-%d %H:%M')
    assert_equal '2023-02-02', contact.date.strftime('%Y-%m-%d')

    #Can handle HHMMSS
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE_OFF:8>20230202 <TIME_OFF>101214 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal '2023-02-02 10:12', contact.time.strftime('%Y-%m-%d %H:%M')
    assert_equal '2023-02-02', contact.date.strftime('%Y-%m-%d')

    #Date/Time ON preferred
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE>20230201 <QSO_DATE_OFF:8>20230202 <TIME_ON>2358 <TIME_OFF>101214 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal '2023-02-01 23:58', contact.time.strftime('%Y-%m-%d %H:%M')
    assert_equal '2023-02-01', contact.date.strftime('%Y-%m-%d')

  end

  #station_callsign, operator, owner_callsign,  eq_call -> callsign1
  test "parameter combinations and formats (station_callsign, operator, owner_callsign,  eq_call)" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user

    #STATION_CALLSIGN (preferred)
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <STATION_CALLSIGN>CALLSIGN1 <OPERATOR>CALLSIGN3 <OWNER_CALLSIGN>CALLSIGN3 <EQ_CALL>CALLSIGN3 <QSO_DATE:8>20230202 <TIME_ON:6>221710 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("CALLSIGN3",user3.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal user1.callsign, contact.callsign1

    #OPERATOR
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <OWNER_CALLSIGN>CALLSIGN3 <EQ_CALL>CALLSIGN3 <QSO_DATE:8>20230202 <TIME_ON:6>221710 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("CALLSIGN3",user3.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal user1.callsign, contact.callsign1

    #OWNER_CALLSIGN
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OWNER_CALLSIGN>CALLSIGN1 <EQ_CALL>CALLSIGN3 <QSO_DATE:8>20230202 <TIME_ON:6>221710 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("CALLSIGN3",user3.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal user1.callsign, contact.callsign1

    #EQ_CALL
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <EQ_CALL>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("CALLSIGN3",user3.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal user1.callsign, contact.callsign1

    #STATION_CALLSIGN (preferred)
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <EQ_CALL>CALLSIGN3 <OWNER_CALLSIGN>CALLSIGN3 <OPERATOR>CALLSIGN3 <STATION_CALLSIGN>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 </EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)
    logstring=logstring.gsub("CALLSIGN3",user3.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal user1.callsign, contact.callsign1
  end

  #rst_rcvd - rst1
  #comment -> comment1
  #tx_pwr -> power1
  #my_altitude -> altitude1
  #my_antenna -> antenna1
  #my_rig -> transceiver1
  test "parameter combinations and formats (#rst_rcvd, #comment, #tx_pwr, #my_altitude, #my_antenna, #my_rig)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <RST_RCVD>59 <COMMENT>This is a comment <TX_PWR>100 <MY_ALTITUDE>372 <MY_RIG>Yaesu FT818</EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal '59', contact.signal1
    assert_equal 'This is a comment', contact.comments1
    assert_equal 100, contact.power1
    assert_equal 372, contact.altitude1, "My altitude"
    assert_equal 'Yaesu FT818', contact.transceiver1
  end

  #my_city+my_state+my_country -> loc_desc1
  test "parameter combinations and formats: my_qth" do
    user1=create_test_user
    user2=create_test_user
    #all params
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <MY_CITY>Sheffield <MY_STATE>South Island <MY_COUNTRY>NZ <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal "Sheffield, South Island, NZ", contact.loc_desc1

    #just some params
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <MY_CITY>Sheffield <MY_COUNTRY>NZ<EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal "Sheffield, NZ", contact.loc_desc1
  end

  #(my_lat+my_lon), my_gridsquare -> location1
  test "parameter combinations and formats (my_lat, my_lon, my_gridsquare)" do
  #(lat_lon),gridsquare -> location2
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <MY_LAT>S045 30.0 <MY_LON>E173 30.0<EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'POINT (173.5 -45.5)', contact.location1.to_s
    assert_equal "user", log.loc_source

    #MAIDENHEAD
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <MY_GRIDSQUARE>RE45 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'POINT (168.0 -45.0)', contact.location1.to_s
    assert_equal "user", log.loc_source

    #lat,lon preferred
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <MY_SIG_INFO>ZLFF-0001 <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <MY_LAT>S045 30.0 <MY_LON>E173 30.0 <MY_GRIDSQUARE>RE45 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal 'POINT (173.5 -45.5)', contact.location1.to_s
    assert_equal "user", log.loc_source

  end
  #my_pota_ref+ mY-sig_info+ my_sota_ref+ my_wwff_ref -> asset1_codes
  test "parameter combinations and formats (my_pota_ref, my_sota_ref, my_wwff_ref, my_sig_info)" do
    user1=create_test_user
    user2=create_test_user
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <MY_POTA_REF>AU-0001 <MY_WWFF_REF>VKFF-0001 <MY_SOTA_REF>VK1/AC-001 <MY_SIG_INFO>VK-GRY1 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal ['AU-0001', 'VKFF-0001', 'VK1/AC-001', 'VK-GRY1'].sort, contact.asset1_codes.sort, "All programme references included"

    #2-FER
    logstring="
<BAND:3>40m <CALL>CALLSIGN2 <MODE:3>SSB <MY_SIG:4>POTA <OPERATOR>CALLSIGN1 <QSO_DATE:8>20230202 <TIME_ON:6>221710 <MY_POTA_REF>AU-0002, AU-0001 <MY_WWFF_REF>VKFF-0001 <MY_SOTA_REF>VK1/AC-001 <MY_SIG_INFO>VK-GRY1 <EOR>
"
    logstring=logstring.gsub("CALLSIGN1",user1.callsign)
    logstring=logstring.gsub("CALLSIGN2",user2.callsign)

    logs=Log.import('adif',user1,logstring,user1)
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal ['AU-0001', 'AU-0002',  'VKFF-0001', 'VK1/AC-001', 'VK-GRY1'].sort, contact.asset1_codes.sort, "All programme references included"

  end
   
end
