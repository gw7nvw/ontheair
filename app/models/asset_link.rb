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

end
