require "test_helper"

class LogImportCsvTest < ActiveSupport::TestCase

  test "Log contact imported successfully" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="V2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
    assert_equal contact.mode, 'FM'
    assert_equal contact.frequency, 144
  end

  test "Log imports multiple contacts successfully" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset

    logstring= "V2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment\nV2,"+user1.callsign+","+asset1.code+",30/08/24,2305,7MHz,SSB,"+user3.callsign+","+asset3.code+",This is a comment2"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 2, "two contacts"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 2, "Really is two contact"
    contact=contacts[0]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
    contact=contacts[1]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:05'.to_time
    assert_equal contact.user2_id, user3.id
    assert_equal contact.callsign2, user3.callsign
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.comments1, "This is a comment2"
  end

  test "Can handle YYYY-mm-dd as well as dd-mm-yy" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="V2,"+user1.callsign+","+asset1.code+",2024/08/01,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)
    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "One contacts"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first
    assert_equal log.date, '2024-08-01'.to_date
    contact=log.contacts.first
    assert_equal contact.date, '2024-08-01'.to_date
    assert_equal contact.time, '2024-08-01 23:04'.to_time
  end

  test "Can handle minimum values" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset

    logstring="V2,"+user1.callsign+","+asset1.code+",2024/08/01,,144MHz,FM,"+user2.callsign+",,"
    logs=Log.import('csv',user1,logstring,user1)
    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "One contacts"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first
    contact=log.contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-01'.to_date
    assert_equal contact.time, '2024-08-01 00:00'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, []
    assert_equal contact.comments1, nil
  end
 
  test "can handle header row" do 
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="version,mycall,my_qth,date,time,band,mode,other_call,other_qth,comments\nV2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
  end

  test "can handle MSDOS linefeeds" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset

    logstring="version,mycall,my_qth,date,time,band,mode,other_call,other_qth,comments\r\nV2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment\r\nV2,"+user1.callsign+","+asset1.code+",30/08/24,2305,144MHz,FM,"+user3.callsign+","+asset3.code+",This is a comment2"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 2, "Two contacts"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 2, "Really is two contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
    contact=contacts[1]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:05'.to_time
    assert_equal contact.user2_id, user3.id
    assert_equal contact.callsign2, user3.callsign
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.comments1, "This is a comment2"
  end

  test "can crete new user2" do
    user1=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    last_user_id=User.last.id
    logstring="V2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,vk3aaa,"+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, User.last.id
    assert_not_equal contact.user2_id, last_user_id, 'new user has been created'
    assert_equal contact.callsign2, 'VK3AAA'
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
  end

  test "can handle vk assets" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_vkasset(award: 'WWFF', code_prefix: 'VKFF-0')
    asset2=create_test_vkasset(award: 'SOTA', code: 'VK3/CB-001', location: create_point(148.79, -35.61))

    logstring="V2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
  end

  test "can handle unknown assets" do
    user1=create_test_user
    user2=create_test_user

    logstring="V2,"+user1.callsign+",KFF-0001,30/08/24,2304,144MHz,FM,"+user2.callsign+",GM/SE-001,This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, ["KFF-0001"]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, ["KFF-0001"]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, ["GM/SE-001"]
    assert_equal contact.comments1, "This is a comment"
  end

  test "rejects contact with no date" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="V2,"+user1.callsign+","+asset1.code+",,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_not_equal logs[:errors].count, 0, "Error(s) reportred"
    assert_equal logs[:good_logs], 0, "No good logs"
    assert_equal logs[:good_contacts], 0, "no good contacts"
    assert_equal logs[:logs].count, 0, "No log"
  end

  test "rejects contact for another call" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="V2,ZL4BAD,"+asset1.code+",2024-08-01,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors].count, 1, "Error reportred"
    assert_equal logs[:good_logs], 0, "No good logs"
    assert_equal logs[:good_contacts], 0, "no good contacts"
    assert_equal logs[:logs].count, 0, "No logs"
  end

  test "continue after bad contact entry" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="V2,ZL4BAD,"+asset1.code+",2024-08-01,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment\nV2,"+user1.callsign+","+asset1.code+",2024-08-01,2305,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment2"
    logs=Log.import('csv',user1,logstring,user1,nil,nil,false,true) #continue on error=true


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors].count, 1, "Error reportred"
    assert_equal logs[:good_logs], 1, "One good logs"
    assert_equal logs[:good_contacts], 1, "One good contacts"
    log=logs[:logs][0]
    assert_not_equal log.id, nil, "First log is saved"
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-01'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-01'.to_date
    assert_equal contact.time, '2024-08-01 23:05'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment2"
  end

  test "allows contacts for secondary call" do
    user1=create_test_user
    user2=create_test_user
    uc1=create_callsign(user1)
    uc2=create_callsign(user2)
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="V2,"+uc1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+uc2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, uc1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, uc1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, uc2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
  end
 
  test "allows chaser log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset

    logstring="V2,"+user1.callsign+",,30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset1.code+",This is a comment\nV2,"+user1.callsign+",,30/08/24,2305,7MHz,AM,"+user2.callsign+","+asset1.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 2, "two contacts"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, []
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 2, "Really is two contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, []
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset1.code]
    assert_equal contact.comments1, "This is a comment"
    assert_equal contact.mode, 'FM'
    assert_equal contact.frequency, 144
    contact=contacts[1]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, []
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:05'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset1.code]
    assert_equal contact.comments1, "This is a comment"
    assert_equal contact.mode, 'AM'
    assert_equal contact.frequency, 7
  end

  test "rejects contact with no location for either party" do
    user1=create_test_user
    user2=create_test_user

    logstring="V2,"+user1.callsign+",,2024/08/01,2304,144MHz,FM,"+user2.callsign+",,This is a comment"
    logs=Log.import('csv',user1,logstring,user1)

    assert_equal logs[:success], true, "Sucessful exit"
    assert_not_equal logs[:errors].count, 0, "Error(s) reportred"
    assert_equal logs[:good_logs], 0, "No good logs"
    assert_equal logs[:good_contacts], 0, "no good contacts"
    assert_equal logs[:logs].count, 0, "No log"
  end

  test "asset inherits child assets when requested" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'hut', location: create_point(174,-44))
    asset4=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)

    logstring="V2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset3.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code, asset2.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code, asset2.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset3.code, asset4.code]
    assert_equal contact.comments1, "This is a comment"
    assert_equal contact.mode, 'FM'
    assert_equal contact.frequency, 144
  end

  test "asset does not inherit child assets when do_not_lookup requested" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    asset2=create_test_asset(asset_type: 'park', location: create_point(173,-45), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'hut', location: create_point(174,-44))
    asset4=create_test_asset(asset_type: 'park', location: create_point(174,-44), test_radius: 0.1)

    logstring="V2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset3.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1,nil , nil, false, false, true)#do_not_lookup

    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code], "Did not inherit child code"
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code], "Did not inherit child code"
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset3.code, asset4.code], "chaser does inherit"
    assert_equal contact.comments1, "This is a comment"
    assert_equal contact.mode, 'FM'
    assert_equal contact.frequency, 144
  end

  test "only known callsigns saved when requested" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    logstring="V2,"+user1.callsign+","+asset1.code+",30/08/24,2304,144MHz,FM,VK2IO,"+asset2.code+",This is a comment\nV2,"+user1.callsign+","+asset1.code+",30/08/24,2305,144MHz,AM,"+user2.callsign+","+asset2.code+",This is a comment2"
    logs=Log.import('csv',user1,logstring,user1,nil,nil,true)#do not create

    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first

    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, user1.callsign
    assert_equal log.asset_codes, [asset1.code]
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset1.code]
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:05'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment2"
    assert_equal contact.mode, 'AM'
    assert_equal contact.frequency, 144
  end

  test "can specify callsign and location (none in log)" do
    user1=create_test_user
    uc1=create_callsign(user1)
    user2=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset

    #log with no user or location
    logstring="V2,,,30/08/24,2304,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment"
    logs=Log.import('csv',user1,logstring,user1, uc1.callsign, 'vkff-0001')

    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 1, "One log"
    assert_equal logs[:good_contacts], 1, "one contact"
    assert_equal logs[:logs].count, 1, "Really is one log"
    log=logs[:logs].first
    assert_equal log.user1_id, user1.id
    assert_equal log.callsign1, uc1.callsign
    assert_equal log.asset_codes, ['VKFF-0001']
    assert_equal log.date, '2024-08-30'.to_date
    contacts=log.contacts
    assert_equal contacts.count, 1, "Really is one contact"
    contact=contacts.first
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, uc1.callsign
    assert_equal contact.asset1_codes, ['VKFF-0001']
    assert_equal contact.date, '2024-08-30'.to_date
    assert_equal contact.time, '2024-08-30 23:04'.to_time
    assert_equal contact.user2_id, user2.id
    assert_equal contact.callsign2, user2.callsign
    assert_equal contact.asset2_codes, [asset2.code]
    assert_equal contact.comments1, "This is a comment"
    assert_equal contact.mode, 'FM'
    assert_equal contact.frequency, 144
  end

  test "logs broken down by day and location1" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    asset3=create_test_asset

    logstring= 
      "V2,"+user1.callsign+","+asset1.code+",29/08/24,0000,144MHz,FM,"+user2.callsign+","+asset2.code+",This is a comment\n"+
      "V2,"+user1.callsign+","+asset2.code+",29/08/24,0600,7MHz,SSB,"+user3.callsign+","+asset3.code+",This is a comment2\n"+
      "V2,"+user1.callsign+","+asset2.code+",30/08/24,0600,14MHz,SSB,"+user2.callsign+","+asset3.code+",This is a comment3\n"+
      "V2,"+user1.callsign+","+asset2.code+",30/08/24,0700,7MHz,AM,"+user3.callsign+","+asset3.code+",This is a comment4\n"
    logs=Log.import('csv',user1,logstring,user1)


    assert_equal logs[:success], true, "Sucessful exit"
    assert_equal logs[:errors], [], "No errors"
    assert_equal logs[:good_logs], 3, "Three log"
    assert_equal logs[:good_contacts], 4, "two contacts"
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
    assert_equal contact.comments1, "This is a comment"
    assert_equal contact.mode, 'FM'
    assert_equal contact.frequency, 144

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
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.comments1, "This is a comment2"
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 7

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
    assert_equal contact.comments1, "This is a comment3"
    assert_equal contact.mode, 'SSB'
    assert_equal contact.frequency, 14
    contact=contacts[1]
    assert_equal contact.user1_id, user1.id
    assert_equal contact.callsign1, user1.callsign
    assert_equal contact.asset1_codes, [asset2.code], "Same asset, same log"
    assert_equal contact.date, '2024-08-30'.to_date, "Same day, same log"
    assert_equal contact.time, '2024-08-30 07:00'.to_time
    assert_equal contact.user2_id, user3.id
    assert_equal contact.callsign2, user3.callsign
    assert_equal contact.asset2_codes, [asset3.code]
    assert_equal contact.comments1, "This is a comment4"
    assert_equal contact.mode, 'AM'
    assert_equal contact.frequency, 7
  end
end
