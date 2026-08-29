# typed: false
require "test_helper"

class UserAwardTest < ActiveSupport::TestCase
  test "issuing and checking threshod awards" do
    user1=create_test_user
    award=Award.find_by(count_based: true, activated: true, programme: 'hut')
    awarded=user1.has_award(award.id)
    assert awarded[:status]==false, "User has not got this award"
    assert_nil awarded[:latest], "No threshold achieved"
    assert awarded[:next]=="Bronze (10)", "Next threshold is 10"

    #ISSUE
    user1.issue_award(award.id,10)

    awarded=user1.has_award(award.id)
    assert awarded[:status]==true, "User has not got this award"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"
  end

  test "user earns award by passing threshold (activator, chaser)" do
    user1=create_test_user
    user2=create_test_user
    activator_award=Award.find_by(count_based: true, activated: true, chased: false, programme: 'hut')
    chaser_award=Award.find_by(count_based: true, activated: false, chased: true, programme: 'hut')

    count=0
    asset=[]
    log=[]
    contact=[]

    while count<10 do
      asset[count]=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut')
      log[count]=create_test_log(user1,asset_codes: [asset[count].code])
      contact[count]=create_test_contact(user1,user2,log_id: log[count].id, asset1_codes: [asset[count].code], time: '2022-01-01 00:00:00'.to_time)
      #call manually as these callbacks are disabled in test
      user1.update_score
      user2.update_score
      user1.check_awards
      user2.check_awards
      count+=1
      if count<10 then
        assert user1.has_award(activator_award.id)[:status]==false, "User has not got this award with "+count.to_s+" contacts" 
        assert user2.has_award(chaser_award.id)[:status]==false, "User has not got this award with "+count.to_s+" contacts" 
      end
    end
    awarded=user1.has_award(activator_award.id)
    assert awarded[:status]==true, "User has got this award after "+count.to_s+" contacts"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"

    awarded=user2.has_award(chaser_award.id)
    assert awarded[:status]==true, "User has got this award after "+count.to_s+" contacts"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"
  end

  test "user earns award by passing threshold for activations + chases (bagged)" do
    user1=create_test_user
    user2=create_test_user
    award=Award.find_by(count_based: true, activated: false, chased: false, programme: 'hut')
    count=0
    asset1=[]
    asset2=[]
    log=[]
    contact=[]

    #bagged on both activations and chases, so 5 park to parks needed for level 10 award
    while count<5 do
      asset1[count]=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut')
      asset2[count]=create_test_asset(region: 'CB', district: 'CC', asset_type: 'hut')
      log[count]=create_test_log(user1,asset_codes: [asset1[count].code])
      contact[count]=create_test_contact(user1,user2,log_id: log[count].id, asset1_codes: [asset1[count].code], asset2_codes: [asset2[count].code], time: '2022-01-01 00:00:00'.to_time)
      #call manually as these callbacks are disabled in test
      user1.update_score
      user2.update_score
      user1.check_awards
      user2.check_awards
      count+=1
      if count<5 then
        assert user1.has_award(award.id)[:status]==false, "User has not got this award with "+count.to_s+" park-to-park contacts" 
        assert user2.has_award(award.id)[:status]==false, "User has not got this award with "+count.to_s+" park-to-park contacts" 
      end
    end
    awarded=user1.has_award(award.id)
    assert awarded[:status]==true, "User has got this award after "+count.to_s+" park-to-park contacts"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"

    awarded=user2.has_award(award.id)
    assert awarded[:status]==true, "User has got this award after "+count.to_s+" contacts"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"
  end

  test "non-qualified activations do not count toward awards" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    user4=create_test_user
    user5=create_test_user
    activator_award=Award.find_by(count_based: true, activated: true, chased: false, programme: 'park')
    chaser_award=Award.find_by(count_based: true, activated: false, chased: true, programme: 'park')

    count=0
    asset=[]
    log=[]
    contact=[]
    contact2=[]
    contact3=[]
    contact4=[]

    while count<10 do
      asset[count]=create_test_asset(region: 'CB', district: 'CC', asset_type: 'park')
      log[count]=create_test_log(user1,asset_codes: [asset[count].code], date: '2022-01-01'.to_date)
      contact[count]=create_test_contact(user1,user2,log_id: log[count].id, asset1_codes: [asset[count].code], time: '2022-01-01 00:00:00'.to_time)
      count+=1
    end
    user1.update_score
    user2.update_score
    user1.check_awards
    user2.check_awards

    awarded=user1.has_award(activator_award.id)
    assert awarded[:status]==false, "User has NOT got this award after "+count.to_s+" contacts without qualifying park"
    assert_nil awarded[:latest]
    assert awarded[:next]=="Bronze (10)", "Next threshold is 10"

    awarded=user2.has_award(chaser_award.id)
    assert awarded[:status]==true, "User has got this award after "+count.to_s+" contacts"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"

    #now qualify each park by adding 3 more contacts
    count=0
    while count<10 do
      contact2[count]=create_test_contact(user1,user3,log_id: log[count].id, asset1_codes: [asset[count].code], time: '2022-01-01 00:00:00'.to_time)
      contact3[count]=create_test_contact(user1,user4,log_id: log[count].id, asset1_codes: [asset[count].code], time: '2022-01-01 00:00:00'.to_time)
      contact4[count]=create_test_contact(user1,user5,log_id: log[count].id, asset1_codes: [asset[count].code], time: '2022-01-01 00:00:00'.to_time)
      count+=1
    end
    user1.update_score
    user2.update_score
    user1.check_awards
    user2.check_awards
  
    awarded=user1.has_award(activator_award.id)
    assert awarded[:status]==true, "User has got this award after "+count.to_s+" contacts without qualifying park"
    assert awarded[:latest]=="Bronze (10)", "This threshold is 10"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"
  end
  
end
