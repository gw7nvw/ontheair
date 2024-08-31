require "test_helper"

class UserAreaActivationTest < ActiveSupport::TestCase

  test "assets from activator log listed by region, type" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'WA', asset_type: 'park')
    asset3=create_test_asset(region: 'OT', district: 'DU', asset_type: 'park')
    asset4=create_test_asset(region: 'OT', district: 'CO', asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
    log3=create_test_log(user1,asset_codes: [asset3.code])
    contact3=create_test_contact(user1,user2,log_id: log3.id, asset1_codes: [asset3.code], time: '2022-01-01 00:00:00'.to_time)
    log4=create_test_log(user1,asset_codes: [asset4.code])
    contact4=create_test_contact(user1,user2,log_id: log4.id, asset1_codes: [asset4.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.area_activations('region')
    assert contacts.count==2, "Expect 2 region activated"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==2
    assert contacts[0][:site_list].sort==[asset1.code, asset2.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='OT', "Expect correct region"
    assert contacts[1][:site_list].count==2
    assert contacts[1][:site_list].sort==[asset3.code, asset4.code].sort
    
    contacts=user2.area_activations('region')
    assert contacts.count==0, "Expect no region activated"

    contacts=user2.area_chases('region')
    assert contacts.count==2, "Expect 2 region chased"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==2
    assert contacts[0][:site_list].sort==[asset1.code, asset2.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='OT', "Expect correct region"
    assert contacts[1][:site_list].count==2
    assert contacts[1][:site_list].sort==[asset3.code, asset4.code].sort
    
    contacts=user1.area_chases('region')
    assert contacts.count==0, "Expect no region chased"
  end

  test "assets from chaser log listed by region, type" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'WA', asset_type: 'park')
    asset3=create_test_asset(region: 'OT', district: 'DU', asset_type: 'park')
    asset4=create_test_asset(region: 'OT', district: 'CO', asset_type: 'park')
    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
    contact3=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset3.code], time: '2022-01-01 00:00:00'.to_time)
    contact4=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset4.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user2.area_activations('region')
    assert contacts.count==2, "Expect 2 region activated"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==2
    assert contacts[0][:site_list].sort==[asset1.code, asset2.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='OT', "Expect correct region"
    assert contacts[1][:site_list].count==2
    assert contacts[1][:site_list].sort==[asset3.code, asset4.code].sort
    
    contacts=user1.area_activations('region')
    assert contacts.count==0, "Expect no region activated"

    contacts=user1.area_chases('region')
    assert contacts.count==2, "Expect 2 region chased"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==2
    assert contacts[0][:site_list].sort==[asset1.code, asset2.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='OT', "Expect correct region"
    assert contacts[1][:site_list].count==2
    assert contacts[1][:site_list].sort==[asset3.code, asset4.code].sort
    
    contacts=user2.area_chases('region')
    assert contacts.count==0, "Expect no region chased"
  end

  test "assets from external activator log listed by region, type" do
    user1=create_test_user
    user2=create_test_user
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'summit', code_prefix: 'ZL3/CB-')
    activation=create_test_external_activation(user1, asset2)
    chase=create_test_external_chase(activation, user2, asset2)
 
    contacts=user1.area_activations('region')
    assert contacts.count==1, "Expect 1 region activated"
    assert contacts[0][:type]=='summit', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset2.code].sort
    
    contacts=user2.area_activations('region')
    assert contacts.count==0, "Expect no region activated"

    contacts=user2.area_chases('region')
    assert contacts.count==1, "Expect 1 region activated"
    assert contacts[0][:type]=='summit', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset2.code].sort
    
    contacts=user1.area_chases('region')
    assert contacts.count==0, "Expect no region chased"
  end

  test "assets broken down by region, type" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut')
    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user2.area_activations('region').sort
    assert contacts.count==2, "Expect 2 region activated"
    assert contacts[0][:type]=='hut', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset2.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='CB', "Expect correct region"
    assert contacts[1][:site_list].count==1
    assert contacts[1][:site_list].sort==[asset1.code].sort
    
    contacts=user1.area_chases('region').sort
    assert contacts.count==2, "Expect 2 region chased"
    assert contacts[0][:type]=='hut', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset2.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='CB', "Expect correct region"
    assert contacts[1][:site_list].count==1
    assert contacts[1][:site_list].sort==[asset1.code].sort
  end

  test "do not include assets not valid at contact date" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park', is_active: false)
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut', valid_to: '2022-01-01'.to_time)
    asset3=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut', valid_from: '2022-01-03'.to_time)
    asset4=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park', valid_from: '2022-01-01'.to_time, valid_to: '2022-01-03'.to_time)
    log=create_test_log(user1, date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], time: '2022-01-02 00:00:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset2.code], time: '2022-01-02 00:00:00'.to_time)
    contact3=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset3.code], time: '2022-01-02 00:00:00'.to_time)
    contact4=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset4.code], time: '2022-01-02 00:00:00'.to_time)
    
    contacts=user2.area_activations('region').sort
    assert contacts.count==1, "Expect 1 region activated"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1, "Expect 1 site"
    assert contacts[0][:site_list].sort==[asset4.code].sort

    contacts=user1.area_chases('region').sort
    assert contacts.count==1, "Expect 1 region chased"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1, "Expect 1 site"
    assert contacts[0][:site_list].sort==[asset4.code].sort
  end

  test "do not include minor by default" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park', minor: true)
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut', minor: false)
    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset2.code])
 
    contacts=user2.area_activations('region').sort
    assert contacts.count==1, "Expect 1 region activated"
    assert contacts[0][:type]=='hut', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1, "Expect minor asset to be excluded"
    assert contacts[0][:site_list].sort==[asset2.code].sort, "Expect minor asset to be excluded"

    contacts=user2.area_activations('region', true).sort
    assert contacts.count==2, "Expect 2 region activated (including minor asset)"
    assert contacts[0][:type]=='hut', "Expect correct asset type"
    assert contacts[0][:name]=='CB', "Expect correct region"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset2.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='CB', "Expect correct region"
    assert contacts[1][:site_list].count==1, "Expect minor asset to be included"
    assert contacts[1][:site_list].sort==[asset1.code].sort, "Expect minor asset to be included"
  end


  test "assets from activator log listed by district, type" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'WA', asset_type: 'park')
    asset3=create_test_asset(region: 'OT', district: 'DU', asset_type: 'park')
    asset4=create_test_asset(region: 'OT', district: 'CO', asset_type: 'park')
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    log2=create_test_log(user1,asset_codes: [asset2.code])
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
    log3=create_test_log(user1,asset_codes: [asset3.code])
    contact3=create_test_contact(user1,user2,log_id: log3.id, asset1_codes: [asset3.code], time: '2022-01-01 00:00:00'.to_time)
    log4=create_test_log(user1,asset_codes: [asset4.code])
    contact4=create_test_contact(user1,user2,log_id: log4.id, asset1_codes: [asset4.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user1.area_activations('district').sort
    assert contacts.count==4, "Expect 4 district activated"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CC', "Expect correct distict"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset1.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='CO', "Expect correct distict"
    assert contacts[1][:site_list].count==1
    assert contacts[1][:site_list].sort==[asset4.code].sort
    assert contacts[2][:type]=='park', "Expect correct asset type"
    assert contacts[2][:name]=='DU', "Expect correct distict"
    assert contacts[2][:site_list].count==1
    assert contacts[2][:site_list].sort==[asset3.code].sort
    assert contacts[3][:type]=='park', "Expect correct asset type"
    assert contacts[3][:name]=='WA', "Expect correct distict"
    assert contacts[3][:site_list].count==1
    assert contacts[3][:site_list].sort==[asset2.code].sort

    contacts=user2.area_activations('district').sort
    assert contacts.count==0, "Expect 0 district activated for chaser"
  end

  test "assets from chaser log listed by district, type" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'WA', asset_type: 'park')
    asset3=create_test_asset(region: 'OT', district: 'DU', asset_type: 'park')
    asset4=create_test_asset(region: 'OT', district: 'CO', asset_type: 'park')
    log=create_test_log(user1)
    contact=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    contact2=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset2.code], time: '2022-01-01 00:00:00'.to_time)
    contact3=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset3.code], time: '2022-01-01 00:00:00'.to_time)
    contact4=create_test_contact(user1,user2,log_id: log.id, asset2_codes: [asset4.code], time: '2022-01-01 00:00:00'.to_time)
 
    contacts=user2.area_activations('district').sort
    assert contacts.count==4, "Expect 4 district activated by activator"
    assert contacts[0][:type]=='park', "Expect correct asset type"
    assert contacts[0][:name]=='CC', "Expect correct distict"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset1.code].sort
    assert contacts[1][:type]=='park', "Expect correct asset type"
    assert contacts[1][:name]=='CO', "Expect correct distict"
    assert contacts[1][:site_list].count==1
    assert contacts[1][:site_list].sort==[asset4.code].sort
    assert contacts[2][:type]=='park', "Expect correct asset type"
    assert contacts[2][:name]=='DU', "Expect correct distict"
    assert contacts[2][:site_list].count==1
    assert contacts[2][:site_list].sort==[asset3.code].sort
    assert contacts[3][:type]=='park', "Expect correct asset type"
    assert contacts[3][:name]=='WA', "Expect correct distict"
    assert contacts[3][:site_list].count==1
    assert contacts[3][:site_list].sort==[asset2.code].sort

    contacts=user1.area_activations('district').sort
    assert contacts.count==0, "Expect 0 district activated for chaser"
  end

  test "assets from external activator log listed by district, type" do
    user1=create_test_user
    user2=create_test_user
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'summit', code_prefix: 'ZL3/CB-')
    activation=create_test_external_activation(user1, asset2)
    chase=create_test_external_chase(activation, user2, asset2)
 
    contacts=user1.area_activations('district')
    assert contacts.count==1, "Expect 1 district activated"
    assert contacts[0][:type]=='summit', "Expect correct asset type"
    assert contacts[0][:name]=='CC', "Expect correct district"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset2.code].sort
    
    contacts=user2.area_activations('district')
    assert contacts.count==0, "Expect no district activated"

    contacts=user2.area_chases('district')
    assert contacts.count==1, "Expect 1 district chased"
    assert contacts[0][:type]=='summit', "Expect correct asset type"
    assert contacts[0][:name]=='CC', "Expect correct district"
    assert contacts[0][:site_list].count==1
    assert contacts[0][:site_list].sort==[asset2.code].sort
    
    contacts=user1.area_chases('region')
    assert contacts.count==0, "Expect no region chased"
  end

end
