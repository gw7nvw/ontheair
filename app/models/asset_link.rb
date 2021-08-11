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
  Asset.find_by(code: self.child_code)
end

def self.prune
   AssetLink.all.each do |al|
     c=al.child
     p=al.parent
     if !c or !p or c.is_active==false or p.is_active==false then puts "PRUNE: "+al.id.to_s; al.destroy end
   end
end

def self.add_pota_links
  pps=PotaPark.all
  pps.each do |pp|
    p=Park.find_by_id(pp.park_id)
    if p then a=Asset.find_by(code: p.dist_code) else a=nil end
    ap=Asset.find_by(code: pp.reference)
    if a  and ap then 
      al=AssetLink.new
      al.parent_code=a.code
      al.child_code=pp.reference
      dup=AssetLink.where(parent_code: a.code, child_code: pp.reference)
      if !dup or dup.count==0 then
        al.save
        puts "Link #{p.name} with #{a.name}"
      else
        puts "Already Linked #{p.name} with #{a.name}"
      end
      al=AssetLink.new
      al.child_code=a.code
      al.parent_code=pp.reference
      dup=AssetLink.where(child_code: a.code, parent_code: pp.reference)
      if !dup or dup.count==0 then
        al.save
      end
   end
  end
end



def self.add_wwff_links
  pps=WwffPark.all
  pps.each do |pp|
    p=Park.find_by_id(pp.napalis_id)
    if p then a=Asset.find_by(code: p.dist_code) else a=nil end
    ap=Asset.find_by(code: pp.code)
    if a  and ap then 
      al=AssetLink.new
      al.parent_code=a.code
      al.child_code=pp.code
      dup=AssetLink.where(parent_code: a.code, child_code: pp.code)
      if !dup or dup.count==0 then
        al.save
        puts "Link #{p.name} with #{a.name}"
      else
        puts "Already Linked #{p.name} with #{a.name}"
      end
      al=AssetLink.new
      al.child_code=a.code
      al.parent_code=pp.code
      dup=AssetLink.where(child_code: a.code, parent_code: pp.code)
      if !dup or dup.count==0 then
        al.save
      end
   end
  end
end

end
