# frozen_string_literal: true

# typed: false
class UserCallsign < ActiveRecord::Base
  validates :user_id, presence: true
  validates :from_date, presence: true
  validate :record_is_unique
  VALID_NAME_REGEX = /\A[a-zA-Z\d\s]*\z/i
  validates :callsign, presence: true, length: { maximum: 50 },
                       format: { with: VALID_NAME_REGEX }

  before_save { self.callsign = callsign.strip.upcase }

  def self.clean(callsign)
    callsign.strip.upcase.encode('UTF-16be', invalid: :replace, replace: '?').encode('UTF-8')
  end

  # Check is callsign is unique for sepcified period
  # -> If unique: PASS
  # -> If not unique:
  #   -> if this is an automatic user creation, FAIL
  #   -> If this is a manual user creation AND the duplicate was auto-created
  #     -> delete auto-created entry in favour of manual one and PASS
  #   -> Else: FAIL
  def record_is_unique
    dups = UserCallsign.find_by_sql [' select * from user_callsigns where callsign=? and (from_date<=? and (to_date>=? or to_date is null)) and id!=?; ', callsign.upcase, to_date || Time.now, from_date || Time.new(1900, 1, 1), id || 0]
    if dups && dups.count.positive?
      dups.each do |dup|
        # can't duplicate a manually created user
        if dup.user.activated
          errors.add(:callsign, 'This callsign is already assigned in this period. Please contact admin@ontheair.nz with details of the period for which you held this callsign so that it can be assigned correctly.')
        elsif !user.activated
          errors.add(:callsign, 'This callsign is already assigned in this period. Please contact admin@ontheair.nz with details of the period for which you held this callsign so that it can be assigned correctly.')
        else
          # automatic user, so delete
          puts 'Delete automatic user ' + callsign
          dup.user.destroy
          dup.destroy
        end
      end
    end
  end

  def user
    User.find_by(id: user_id)
  end
end
