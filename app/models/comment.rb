# frozen_string_literal: true

# typed: false
class Comment < ActiveRecord::Base
  validates :code, presence: true
  validates :comment, presence: true, length: { minimum: 1 }

  def updated_by_name
    user = User.find_by_id(updated_by_id)
    user ? user.callsign : ''
  end

  def self.for_asset(code)
    Comment.where(code: code)
  end

  def asset
    Asset.find_by(code: code)
  end
end
