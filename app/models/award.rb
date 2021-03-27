class Award < ActiveRecord::Base

def baggers
  aus=[]
  aus=AwardUserLink.where(:award_id => self.id)
end

def self.check_awards(user)
  awarded=[]
  awards=Award.where(:is_active => true)
  awards.each do |award|
    if !(user.has_award(award.id)) then
      failcount=0
      if award.huts_minimum>0 then
         hutcount=user.hut_count_filtered(award.user_qrp, award.contact_qrp, award.allow_repeat_visits)
         if hutcount<award.huts_minimum then
            failcount=failcount+1
         end
      end 
      if failcount==0 then
         awarded.push(award) 
      end
    end
  end
  awarded
end

end
