class AssetLink < ActiveRecord::Base

def self.find_by_parent(code)
  als1=AssetLink.where(parent_code: code)
  als2=AssetLink.where(child_code: code)
  als2.each do |al| al.reverse end
  als1+als2
end

def reverse
  temp=self.child_code
  self.child_code=self.parent_code
  self.parent_code=temp
end 

def parent
  Asset.find_by(code: self.parent_code)
end

def child
  Asset.find_by(code: self.parent_code)
end

def self.prune
   AssetLink.all.each do |al|
     c=al.child
     p=al.parent
     if !c or !p or c.is_active==false or p.is_active==false then puts "PRUNE: "+al.id.to_s; al.destroy end
   end
end

end
