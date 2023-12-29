class UserCallsign < ActiveRecord::Base

validates :user_id, presence: true
validates :from_date, presence: true
validate :record_is_unique
VALID_NAME_REGEX = /\A[a-zA-Z\d\s]*\z/i
validates :callsign,  presence: true, length: { maximum: 50 },
                format: { with: VALID_NAME_REGEX }

before_save { self.callsign = callsign.strip.upcase }

# Check is callsign is unique for sepcified period
# -> If unique: PASS
# -> If not unique:
#   -> if this is an automatic user creation, FAIL
#   -> If this is a manual user creation AND the duplicate was auto-created
#     -> delete auto-created entry in favour of manual one and PASS
#   -> Else: FAIL
def record_is_unique
  dups=UserCallsign.find_by_sql [" select * from user_callsigns where callsign=? and (from_date<=? and (to_date>=? or to_date is null)) and id!=?; ", self.callsign.upcase, self.to_date||Time.now(), self.from_date||Time.new(1900,1,1), self.id ||0]
  if dups and dups.count>0 then
     dups.each do |dup|
       #can't duplicate a manually created user
       if dup.user.activated then
         errors.add(:callsign, "This callsign is already assigned in this period. Please contact admin@ontheair.nz with details of the period for which you held this callsign so that it can be assigned correctly.")
       elsif !self.user.activated then
         errors.add(:callsign, "This callsign is already assigned in this period. Please contact admin@ontheair.nz with details of the period for which you held this callsign so that it can be assigned correctly.")
       else
         #automatic user, so delete
         puts "Delete automatic user "+self.callsign
         dup.user.destroy
         dup.destroy
       end
     end
  end
end

def user
  User.find(self.user_id)
end

end
