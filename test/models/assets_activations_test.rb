require "test_helper"

class AssetActivationTest < ActiveSupport::TestCase

  test "Activations lists logs with at least 1 contact from this asset" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    #log with a contact
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    #log with a contact
    log2=create_test_log(user1, asset_codes: [asset1.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code])
    #log with no contact
    log3=create_test_log(user1, asset_codes: [asset1.code])
    assert asset1.activation_count==2, "Activations with contacts counted"
  end

  ############ ACTIVATORS ######################
  test "Activators lists users with at least 1 contact from this asset" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    #qactivator log (include)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    #chaser log (include)
    log2=create_test_log(user2)
    contact2=create_test_contact(user2,user3,log_id: log2.id, asset2_codes: [asset1.code])
    #activator log with no contacts (exclude)
    log3=create_test_log(user4, asset_codes: [asset1.code])
    assert asset1.activators==[user1, user3], "Activatiors with contacts from activator or chaser logs included"
  end

  test "External Activators lists users with at least 1 external log from this asset" do
    user1=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    #activator log (include)
    activation=create_test_external_activation(user1,asset1)

    assert asset1.external_activators==[user1], "Activatiors with external log included"
  end

  test "All Activators lists users with external or internally logged contacts" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    #qactivator log (include)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    #chaser log (include)
    log2=create_test_log(user2)
    contact2=create_test_contact(user2,user3,log_id: log2.id, asset2_codes: [asset1.code])
    #external activator log
    activation=create_test_external_activation(user4,asset1)
    #Duplicate internal / external log
    activation=create_test_external_activation(user1,asset1)

    assert asset1.activators_including_external==[user1, user3, user4].sort, "Activatiors with external log included"
  end

  ############ CHASERS ######################
  test "Chasers lists users with at least 1 contact from this asset" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    #activator log (include)
    log=create_test_log(user2,asset_codes: [asset1.code])
    contact1=create_test_contact(user2,user1,log_id: log.id, asset1_codes: [asset1.code])
    #chaser log (include)
    log2=create_test_log(user3)
    contact2=create_test_contact(user3,user2,log_id: log2.id, asset2_codes: [asset1.code])
    assert asset1.chasers==[user1, user3], "Chasers with contacts from activator or chaser logs included"
  end

  test "External Chasers lists users with at least 1 external chaser contact to this asset" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    #external chaser contact (include)
    activation=create_test_external_activation(user1,asset1)
    chase=create_test_external_chase(activation,user2,asset1)


    assert asset1.external_chasers==[user2], "Chasers with external contact included"
  end

  test "All Chasers lists users with external or internally logged contacts" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    #activator log (include)
    log=create_test_log(user2,asset_codes: [asset1.code])
    contact1=create_test_contact(user2,user1,log_id: log.id, asset1_codes: [asset1.code])
    #chaser log (include)
    log2=create_test_log(user3)
    contact2=create_test_contact(user3,user2,log_id: log2.id, asset2_codes: [asset1.code])
    #external chaser log 
    activation=create_test_external_activation(user2,asset1)
    chase=create_test_external_chase(activation,user4,asset1)
    #Duplicate internal / external chaser log
    activation=create_test_external_activation(user2,asset1)
    chase=create_test_external_chase(activation,user1,asset1)

    assert asset1.chasers_including_external==[user1, user3, user4].sort, "Chasers with internal or external contact included"
  end

  test "activated_by correctly shows if asset actibvated by user" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    #activator log (include)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    #chaser log (include)
    log2=create_test_log(user2)
    contact2=create_test_contact(user2,user3,log_id: log2.id, asset2_codes: [asset1.code])
    #external activator log
    activation=create_test_external_activation(user4,asset1)

    assert asset1.activated_by?(user1.callsign)==true, "User1 activator log triggers activeted_by"
    assert asset1.activated_by?(user2.callsign)==false, "User2 has not activated (only chased) this asset"
    assert asset1.activated_by?(user3.callsign)==true, "User3 chaser log triggers activated_by for activator"
    assert asset1.activated_by?(user4.callsign)==true, "user4 external log triggers activeted_by"
  end

  test "chased correctly shows if asset chased by user" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    #activator log (include)
    log=create_test_log(user2,asset_codes: [asset1.code])
    contact1=create_test_contact(user2,user1,log_id: log.id, asset1_codes: [asset1.code])
    #chaser log (include)
    log2=create_test_log(user3)
    contact2=create_test_contact(user3,user2,log_id: log2.id, asset2_codes: [asset1.code])
    #external chaser log
    activation=create_test_external_activation(user2,asset1)
    chase=create_test_external_chase(activation,user4,asset1)

    assert asset1.chased_by?(user1.callsign)==true, "User1 activator log triggers chased_by for chaser"
    assert asset1.chased_by?(user2.callsign)==false, "User2 has not chased (only activated) this asset"
    assert asset1.chased_by?(user3.callsign)==true, "User3 chaser log triggers chased_by for chaser"
    assert asset1.chased_by?(user4.callsign)==true, "user4 external log triggers chased_by for chaser"
  end
end
