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
end
