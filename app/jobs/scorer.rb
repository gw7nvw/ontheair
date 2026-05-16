# frozen_string_literal: true

# typed: true
class Scorer
  @queue = :ontheair

  def self.perform
    puts 'SCORER: Got called'
    # sleep 1
    us = User.where(outstanding: true)
    if us and us.count>0
      u=us.first
      puts 'SCORER: Got user ' + u.callsign
      u.update_column(:outstanding, false)
      u.update_score
      u.check_awards
      u.check_completion_awards('region')
      u.check_completion_awards('district')
      u.update_column(:outstanding, false)
    end
  end
end
