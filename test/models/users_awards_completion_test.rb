# typed: strict
require "test_helper"

class UserAwardCompletionTest < ActiveSupport::TestCase

  test "can create and retire completion awards" do
    user1=create_test_user
    region=Region.find_by(sota_code: 'CB')    
    region2=Region.find_by(sota_code: 'OT')    

    assert user1.has_completion_award('region',region.id,'chaser','hut')==false,       "User has no completion award by default"
    #ISSUE
    user1.issue_completion_award('region',region.id,'chaser','hut')

    assert user1.has_completion_award('region',region.id,'chaser','hut')==true,       "User has completion award"
    assert user1.has_completion_award('region',region2.id,'chaser','hut')==false,       "But no award for another region"
    assert user1.has_completion_award('region',region.id,'chaser','park')==false,       "And no award for another asset type"

    #RETIRE
    user1.retire_completion_award('region',region.id,'chaser','hut')

    assert user1.has_completion_award('region',region.id,'chaser','hut')==false,       "User has no completion award"
    #REISSUE
    user1.issue_completion_award('region',region.id,'chaser','hut')
    assert user1.has_completion_award('region',region.id,'chaser','hut')==true,       "User has completion award"
  end

  test "can create and retire district completion awards" do
    user1=create_test_user
    district=District.find_by(district_code: 'CC')    
    district2=District.find_by(district_code: 'CO')    

    assert user1.has_completion_award('district',district.id,'chaser','hut')==false,       "User has no completion award by default"

    user1.issue_completion_award('district',district.id,'chaser','hut')

    assert user1.has_completion_award('district',district.id,'chaser','hut')==true,       "User has completion award"
    assert user1.has_completion_award('district',district2.id,'chaser','hut')==false,       "But no award for another district"
    assert user1.has_completion_award('district',district.id,'chaser','park')==false,       "And no award for another asset type"

    user1.retire_completion_award('district',district.id,'chaser','hut')

    assert user1.has_completion_award('district',district.id,'chaser','hut')==false,       "User has no completion award"
  end

  test "Activator completion award awarded and revoked based on activator log" do
    region=Region.find_by(sota_code: 'CB')    
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')

    #no award when none of 1 parks activated
    user1.check_completion_awards('region')
    assert user1.has_completion_award('region',region.id,'activator','park')==false, "User has no chaser completion award"
    assert user1.has_completion_award('region',region.id,'chaser','park')==false, "User has no chaser completion award"

    #award issues when 1 / 1 parks activated
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user1.check_completion_awards('region')
    assert user1.has_completion_award('region',region.id,'activator','park')==true, "User has completion award"
    assert user1.has_completion_award('region',region.id,'chaser','park')==false, "User still has no chaser completion award"

    #add another park to region, check award is revoked
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    user1.check_completion_awards('region')
    assert user1.has_completion_award('region',region.id,'activator','park')==false, "User has no completion award"
  end

  test "Activator Completion award awarded and revoked based on chaser log" do
    region=Region.find_by(sota_code: 'CB')    
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')

    #no award when none of 1 parks activated
    user1.check_completion_awards('region')
    assert user1.has_completion_award('region',region.id,'activator','park')==false, "User has no chaser completion award"
    assert user1.has_completion_award('region',region.id,'chaser','park')==false, "User has no chaser completion award"

    #award issues when 1 / 1 parks activated
    log=create_test_log(user2)
    contact=create_test_contact(user2,user1,log_id: log.id, asset2_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user1.check_completion_awards('region')
    assert user1.has_completion_award('region',region.id,'activator','park')==true, "User has completion award"
    assert user1.has_completion_award('region',region.id,'chaser','park')==false, "User still has no chaser completion award"

    #add another park to region, check award is revoked
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    user1.check_completion_awards('region')
    assert user1.has_completion_award('region',region.id,'activator','park')==false, "User has no completion award"
  end

  test "Chaser Completion award awarded and revoked based on activator log" do
    region=Region.find_by(sota_code: 'CB')    
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')

    #no award when none of 1 parks activated
    user2.check_completion_awards('region')
    assert user2.has_completion_award('region',region.id,'chaser','park')==false, "User has no chaser completion award"
    assert user2.has_completion_award('region',region.id,'activator','park')==false, "User has no chaser completion award"

    #award issues when 1 / 1 parks activated
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user2.check_completion_awards('region')
    assert user2.has_completion_award('region',region.id,'chaser','park')==true, "User has completion award"
    assert user2.has_completion_award('region',region.id,'activator','park')==false, "User still has no chaser completion award"

    #add another park to region, check award is revoked
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    user2.check_completion_awards('region')
    assert user2.has_completion_award('region',region.id,'chaser','park')==false, "User has no completion award"
  end

  test "Chaser Completion award awarded and revoked based on chaser log" do
    region=Region.find_by(sota_code: 'CB')    
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')

    #no award when none of 1 parks activated
    user2.check_completion_awards('region')
    assert user2.has_completion_award('region',region.id,'chaser','park')==false, "User has no chaser completion award"
    assert user2.has_completion_award('region',region.id,'activator','park')==false, "User has no chaser completion award"

    #award issues when 1 / 1 parks activated
    log=create_test_log(user2)
    contact=create_test_contact(user2,user1,log_id: log.id, asset2_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user2.check_completion_awards('region')
    assert user2.has_completion_award('region',region.id,'chaser','park')==true, "User has completion award"
    assert user2.has_completion_award('region',region.id,'activator','park')==false, "User still has no chaser completion award"

    #add another park to region, check award is revoked
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    user2.check_completion_awards('region')
    assert user2.has_completion_award('region',region.id,'chaser','park')==false, "User has no completion award"
  end

  test "District completion award awarded and revoked based on comntacts made" do
    district=District.find_by(district_code: 'CC')    
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')

    #no award when none of 1 parks activated
    user1.check_completion_awards('district')
    assert user1.has_completion_award('district',district.id,'activator','park')==false, "User has no completion award"

    #award issues when 1 / 1 parks activated
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user1.check_completion_awards('district')
    assert user1.has_completion_award('district',district.id,'activator','park')==true, "User has completion award"

    #add another park to district, check award is revoked
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    user1.check_completion_awards('district')
    assert user1.has_completion_award('district',district.id,'activator','park')==false, "User has no completion award"
  end

  test "Minor / inactive assets ignored in completion award" do 
    district=District.find_by(district_code: 'CC')    
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
    asset2=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park', minor: true)
    asset3=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park', is_active: false)

    #award issued when 1 / 1 parks activated (minor / inactive parks ignored)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-01 00:00:00'.to_time)
    user1.check_completion_awards('district')
    assert user1.has_completion_award('district',district.id,'activator','park')==true, "User has completion award"
    user2.check_completion_awards('district')
    assert user2.has_completion_award('district',district.id,'chaser','park')==true, "User has completion award"

  end
end
