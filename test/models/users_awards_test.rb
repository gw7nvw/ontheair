require "test_helper"

class UserAwardTest < ActiveSupport::TestCase
  test "issueing and checking threshod awards" do
    user1=create_test_user
    award=Award.find_by(count_based: true, activated: true, programme: 'hut')
    awarded=user1.has_award(award.id)
    assert awarded[:status]==false, "User has not got this award"
    assert awarded[:latest]==nil, "No threshold achieved"
    assert awarded[:next]=="Bronze (10)", "Next threshold is 10"

    #ISSUE
    user1.issue_award(award.id,10)

    awarded=user1.has_award(award.id)
    assert awarded[:status]==true, "User has not got this award"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"
  end

  test "user earns award by passing threshold (chaser)" do
TODO
  end

  test "user earns award by passing threshold (activator)" do
  end

  test "non-qualified activations do not count toward awards" do
  end

  test "user earns award by passing threshold (bagged)" do
  end

  
end
