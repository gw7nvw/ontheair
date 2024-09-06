module AssetConsoleTools

#Add / reapply region to all assets
def self.add_regions
  count=0
  a=Asset.first_by_id
  while a do
    logger.debug a.code+" "+count.to_s
    count+=1
    a.add_region
    a=Asset.next(a.id)
  end
end

#Add / reapply district to all assets
def self.add_districts
  count=0
  a=Asset.first_by_id
  while a do
    logger.debug a.code+" "+count.to_s
    count+=1
    a.add_district
    a=Asset.next(a.id)
  end
end

#Rebuild asset links for all assets
def self.add_links
  as=Asset.find_by_sql [ " select id,code from assets " ]
  as.each do |aa|
    logger.debug aa.code
    a=Asset.find_by_id(aa.id)
    a.add_links
  end
end

#Remove any links that point to non-existant assets
def self.prune_links
  als=AssetLink.all
  als.each do |al|
    if !al.parent or !al.child then al.destroy end
  end
end

#resave all assets
def self.update_all
  a=Asset.first_by_id
  while a do
     a.save
     a=Asset.next(a.id)
     logger.debug a.code
  end
end

# add loction based on polygon for any assets missing a location
def self.add_centroids
  a=Asset.first_by_id
  while a do
    if !a.location then
      logger.debug a.code
      location=a.calc_location
      if location then a.location=location; a.save; end
    end
    a=Asset.next(a.id)
  end
end

def self.add_sota_activation_zones(force=false)
  count=0
  if force==false then
    as=Asset.where(asset_type: 'summit', boundary: nil)
  else
    as=Asset.where(asset_type: 'summit')
  end
  as.each do |a|
    count+=1
    a.add_sota_activation_zone
    a.get_access
  end
end
def self.add_hema_activation_zones(force=false)
  count=0
  if force==false then
    as=Asset.where(asset_type: 'hump', boundary: nil)
  else
    as=Asset.where(asset_type: 'hump')
  end
  as.each do |a|
    count+=1
    a.add_sota_activation_zone
    a.get_access
  end
end

def self.get_hema_access
  as=Asset.where(asset_type: 'hump')
  as.each do |a|
    logger.debug a.code
    a.get_access
  end
end

def self.get_sota_access
  as=Asset.where(asset_type: 'summit')
  as.each do |a|
    logger.debug a.code
    a.get_access
  end
end

def self.get_lake_access
  as=Asset.where(asset_type: 'lake')
  as.each do |a|
    logger.debug a.code
    a.get_access_with_buffer(500)
  end
end
##################################################
# Step through assets without loading entire list
##################################################
def self.first_by_id
  a=Asset.where("id > ?",0).order(:id).first
end


def self.next(id)
  a=Asset.where("id > ?",id).order(:id).first
end

end
