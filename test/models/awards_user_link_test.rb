# typed: false
require "test_helper"

class AwardsUserLinkTest < ActiveSupport::TestCase
  test "Award is publicised" do
    user1=create_test_user
    user1.update_column(:activated, true)
    award=Award.find_by(count_based: true, activated: true, programme: 'hut')
    awarded=user1.has_award(award.id)
    assert awarded[:status]==false, "User has not got this award"
    assert_nil awarded[:latest], "No threshold achieved"
    assert awarded[:next]=="Bronze (10)", "Next threshold is 10"

    #ISSUE
    user1.issue_award(award.id,10)

    awarded=user1.has_award(award.id)
    assert awarded[:status]==true, "User has got this award"
    assert awarded[:latest]=="Bronze (10)", "10 threshold achieved"
    assert awarded[:next]=="Silver (30)", "Next threshold is 30"

    #Check notification
    post = Post.last

    assert_equal post.title, 'New award for ' + user1.callsign
    assert_equal post.description, user1.callsign + ' has earned Hut Activator (qualified) award - bronze (10)'


  end
end
