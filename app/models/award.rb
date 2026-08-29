# frozen_string_literal: true

# typed: true
class Award < ActiveRecord::Base
  def baggers
    AwardUserLink.where(award_id: id)
  end
end
