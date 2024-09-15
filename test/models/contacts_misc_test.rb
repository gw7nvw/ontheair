require "test_helper"

class ContactMiscTest < ActiveSupport::TestCase

  test "find asset2 by type return correct asset for contact" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'park')
    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code, asset3.code])
    assert contact.find_asset2_by_type('pota park')[:asset]==asset2, "Returns asset2 for pota park"
    assert contact.find_asset2_by_type('park')[:asset]==asset3, "Returns asset3 for park"
    assert contact.find_asset2_by_type('hut')[:asset]==asset1, "Returns asset1 for hut"
  end

  test "find asset2 by type handles multiple assets of same type (just returns 1)" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    asset3=create_test_asset(asset_type: 'park')

    log=create_test_log(user1)
    contact=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset1.code, asset2.code, asset3.code])
    assert (contact.find_asset2_by_type('park')[:asset]==asset2 or 
           contact.find_asset2_by_type('park')[:asset]==asset3), "Returns one of 2 parks"
    assert contact.find_asset2_by_type('hut')[:asset]==asset1, "Returns asset1 for hut"
  end

  test "find contact from p2p works" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    asset3=create_test_asset(asset_type: 'park')

    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset2.code], time: '2022-01-01'.to_time)
    contact2=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset3.code], time: '2022-01-01'.to_time)
    p2ps=user1.get_p2p_all.sort
    assert p2ps.count==2, "returned 2 p2ps"
    assert Contact.find_contact_from_p2p(user1.id,asset1.code, asset2.code, '2022-01-01')==contact1, "finds contact for activator"
    assert Contact.find_contact_from_p2p(user1.id,asset1.code, asset3.code, '2022-01-01')==contact2, "finds contact for activator"
    assert Contact.find_contact_from_p2p(user2.id,asset2.code, asset1.code, '2022-01-01')==contact1, "finds contact from chaser log"
    assert Contact.find_contact_from_p2p(user2.id,asset3.code, asset1.code, '2022-01-01')==contact2, "finds contact from chaser log"
  end

  test "find contact from p2p discriminates by date" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')

    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset2.code], time: '2022-01-01'.to_time)
    log2=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact2=create_test_contact(user1, user2, log_id: log2.id, asset2_codes: [asset2.code], time: '2022-01-02'.to_time)
    p2ps=user1.get_p2p_all.sort
    assert p2ps.count==2, "returned 2 p2ps"

    assert Contact.find_contact_from_p2p(user1.id,asset1.code, asset2.code, '2022-01-01')==contact1, "finds contact for activator"
    assert Contact.find_contact_from_p2p(user1.id,asset1.code, asset2.code, '2022-01-02')==contact2, "finds contact for activator"
    assert Contact.find_contact_from_p2p(user2.id,asset2.code, asset1.code, '2022-01-01')==contact1, "finds contact from chaser log"
    assert Contact.find_contact_from_p2p(user2.id,asset2.code, asset1.code, '2022-01-02')==contact2, "finds contact from chaser log"
  end

  test "find contact from p2p works for 2-fers" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    asset2=create_test_asset(asset_type: 'park')
    asset3=create_test_asset(asset_type: 'park')

    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact1=create_test_contact(user1, user2, log_id: log.id, asset2_codes: [asset2.code, asset3.code], time: '2022-01-01'.to_time)

    p2ps=user1.get_p2p_all.sort
    assert p2ps.count==2, "returned 2 p2ps"
    assert Contact.find_contact_from_p2p(user1.id,asset1.code, asset2.code, '2022-01-01')==contact1, "Returns correct contact for p2p"
    assert Contact.find_contact_from_p2p(user1.id,asset1.code, asset3.code, '2022-01-01')==contact1, "Returns correct contact for p2p"
  end

  test "create log matching contact" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))
    #comntct with just the hut
    contact2=create_test_contact(user1, user2, asset1_codes: [asset1.code], time: '2022-01-01'.to_time)

    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)

    #contact with hut in park
    contact1=create_test_contact(user1, user2, asset1_codes: [asset1.code, asset2.code, asset3.code], time: '2022-01-01'.to_time)
    #contact with just the park
    contact3=create_test_contact(user1, user2, asset1_codes: [asset2.code], time: '2022-01-01'.to_time)

    contact1.find_create_log_matching_contact
    contact1.reload
    assert_not_equal nil, contact1.log_id, "Log added to contact"

    log=contact1.log

    assert_equal contact1.callsign1, log.callsign1, " Log correct"
    assert_equal contact1.date, log.date, " Log correct"
    assert_equal contact1.power1, log.power1, " Log correct"
    assert_equal contact1.is_qrp1, log.is_qrp1, " Log correct"
    assert_equal contact1.is_portable1, log.is_portable1, " Log correct"
    assert_equal contact1.location1, log.location1, " Log correct"
    assert_equal contact1.asset1_codes, log.asset_codes, " Log correct"

    #now test with just the hut (should be added to same log)
    contact2.find_create_log_matching_contact
    contact2.reload
    assert_equal log.id, contact2.log_id, "Log added to contact"
   
    #now test with just the park (should create new log)
    contact3.find_create_log_matching_contact
    contact3.reload
    assert_not_equal log.id, contact3.log_id, "New log for just the park"

    log3=contact3.log

    assert_equal contact3.callsign1, log3.callsign1, " Log correct"
    assert_equal contact3.date, log3.date, " Log correct"
    assert_equal contact3.power1, log3.power1, " Log correct"
    assert_equal contact3.is_qrp1, log3.is_qrp1, " Log correct"
    assert_equal contact3.is_portable1, log3.is_portable1, " Log correct"
    assert_equal contact3.location1, log3.location1, " Log correct"
    assert_equal contact3.asset1_codes, log3.asset_codes, " Log correct"
  end

  test "create log matching contact (unknown assets)" do
    user1=create_test_user
    user2=create_test_user

    #contact with all assets
    contact1=create_test_contact(user1, user2, asset1_codes: ['VKFF-0001', 'VK1/AC-001'], time: '2022-01-01'.to_time)
    #contact with same assets
    contact2=create_test_contact(user1, user2, asset1_codes: ['VKFF-0001', 'VK1/AC-001'], time: '2022-01-01'.to_time)
    #contact with just some assets
    contact3=create_test_contact(user1, user2, asset1_codes: ['VKFF-0001'], time: '2022-01-01'.to_time)

    contact1.find_create_log_matching_contact
    contact1.reload
    assert_not_equal nil, contact1.log_id, "Log added to contact"

    log=contact1.log
    assert_equal contact1.callsign1, log.callsign1, " Log correct"
    assert_equal contact1.date, log.date, " Log correct"
    assert_equal contact1.power1, log.power1, " Log correct"
    assert_equal contact1.is_qrp1, log.is_qrp1, " Log correct"
    assert_equal contact1.is_portable1, log.is_portable1, " Log correct"
    assert_equal contact1.location1, log.location1, " Log correct"
    assert_equal contact1.asset1_codes, log.asset_codes, " Log correct"

    #now test with just the hut (should be added to same log)
    contact2.find_create_log_matching_contact
    contact2.reload
    assert_equal log.id, contact2.log_id, "Log added to contact"
   
    #now test with just the park (should create new log)
    contact3.find_create_log_matching_contact
    contact3.reload
    assert_not_equal log.id, contact3.log_id, "New log for just the park"

    log3=contact3.log

    assert_equal contact3.callsign1, log3.callsign1, " Log correct"
    assert_equal contact3.date, log3.date, " Log correct"
    assert_equal contact3.power1, log3.power1, " Log correct"
    assert_equal contact3.is_qrp1, log3.is_qrp1, " Log correct"
    assert_equal contact3.is_portable1, log3.is_portable1, " Log correct"
    assert_equal contact3.location1, log3.location1, " Log correct"
    assert_equal contact3.asset1_codes, log3.asset_codes, " Log correct"
  end

  test "create activator log matching chaser contact" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))

    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)

    #park to park vontact with chaser in hut
    log=create_test_log(user2, asset_codes: [asset3.code])
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset3.code], asset2_codes: [asset1.code, asset2.code], time: '2022-01-01'.to_time)

    new_contact=contact1.find_create_log_matching_contact(true)
    contact1.reload
    assert_equal log.id, contact1.log_id, "Original contact unchanged"

    #new contact created
    assert_equal contact1.date, new_contact.date, " New reverse contact correct"
    assert_equal contact1.callsign1, new_contact.callsign2, " New reverse contact correct"
    assert_equal contact1.asset1_codes, new_contact.asset2_codes, " New reverse contact correct"
    assert_equal contact1.location1, new_contact.location2, " New reverse contact correct"
    assert_equal contact1.callsign2, new_contact.callsign1, " New reverse contact correct"
    assert_equal contact1.asset2_codes, new_contact.asset1_codes, "New reverse contact correct"
    assert_equal contact1.location2, new_contact.location1, "New reverse contact correct"

    #new log created
    new_log=new_contact.log
    assert_equal contact1.date, new_log.date, " New reverse contact correct"
    assert_equal contact1.callsign2, new_log.callsign1, " New reverse contact correct"
    assert_equal contact1.location2, new_log.location1, " New reverse contact correct"
    assert_equal contact1.asset2_codes, new_log.asset_codes, " New reverse contact correct"
  end

  test "Refute chaser contact with wrong activation details" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', location: create_point(173,-45))

    asset2=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', location: create_point(173.01,-45.01), test_radius: 0.2)

    #park to park vontact with chaser in hut
    log=create_test_log(user2, asset_codes: [asset3.code])
    contact1=create_test_contact(user2, user1, log_id: log.id, asset1_codes: [asset3.code], asset2_codes: [asset1.code, asset2.code], time: '2022-01-01'.to_time)

    contact1.refute_chaser_contact

    assert_equal [], contact1.asset2_codes, "Chaser location cleared"
    assert_equal nil, contact1.location2, "Chaser location cleared"
    assert contact1.loc_desc2["Removed"], "Chaser location descruption updated"
  end
end
