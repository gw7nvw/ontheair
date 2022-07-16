class Award < ActiveRecord::Base

def baggers
  aus=[]
  aus=AwardUserLink.where(:award_id => self.id)
end


end
