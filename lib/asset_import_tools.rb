# typed: false
module AssetImportTools

def Asset.add_parks
  ps=Park.find_by_sql [ 'select id from parks;' ]
  ps.each do |pid|
    p=Park.find_by_id(pid)
    a=Asset.find_by(asset_type: 'park', code: p.dist_code)
    if !a then  a=Asset.find_by(asset_type: 'park', code: p.code) end
    if !a then a=Asset.new;new=true;logger.debug "New" else new=false end
    a.asset_type="park"
    a.code=p.dist_code
    a.old_code=p.code
    if p.master_id then
       cp=Crownpark.find_by_id(p.master_id)
       if cp then pp=Park.find_by_id(cp.napalis_id)  else pp=nil end
       if pp then a.master_code=pp.dist_code
       else logger.error "ERROR: failed to find park "+p.master_id.to_s+" master for "+p.dist_code+" "+p.name; p.master_id=nil; a.master_code=nil; end
    end
    a.safecode=a.code.gsub('/','_')
    a.url='assets/'+a.safecode
    a.name=p.name.gsub("'","''")
    a.description=(p.description||"").gsub("'","''")
    a.is_active=p.is_active and not p.is_mr
    a.category=(p.owner||"").gsub("'","''")
    a.location=p.location
    if new then a.save end
    ActiveRecord::Base.connection.execute("update assets set code='"+a.code+"', old_code='"+(a.old_code||"")+"',master_code='"+(a.master_code||"")+"', safecode='"+a.safecode+"', url='"+a.url+"', name='"+a.name+"', description='"+(a.description||"")+"', is_active="+a.is_active.to_s+", category='"+(a.category||"")+"', location=(select location from parks where id="+p.id.to_s+"),  boundary=(select boundary from parks where id="+p.id.to_s+") where id="+a.id.to_s+";")
    a.post_save_acions
    logger.debug a.code
  end
  true
end

def Asset.add_huts
  ps=Hut.all
  ps.each do |p|
    a=Asset.find_by(asset_type: 'hut', code: p.code)
    if !a then a=Asset.new end
    a.asset_type="hut"
    a.code=p.code
    a.url='/huts/'+p.id.to_s
    a.name=p.name
    a.description=p.description
    a.is_active=p.is_active
    a.location=p.location
    a.altitude=p.altitude
    a.save
    logger.debug a.code
  end
  true
end

def Asset.add_islands
  ps=Island.all
  ps.each do |p|
    a=Asset.find_by(asset_type: 'island', code: p.code)
    if !a then a=Asset.new end
    a.asset_type="island"
    a.code=p.code_dist
    a.old_code=p.code
    a.url='asset/'+a.code
    a.name=p.name
    a.description=p.info_description
    a.is_active=p.is_active
    a.location=p.WKT
    a.boundary=p.boundary
    a.save
    logger.debug a.code
  end
  true
end

def Asset.add_lakes
  ls=Lake.where(is_active: true)
  ls.each do |l|
     Asset.add_lake(l)
  end
end

def Asset.add_lake(l)
  a=Asset.find_by(asset_type: 'lake', code: l.code)
  if !a then a=Asset.new; logger.debug "New" end
  a.asset_type="lake"
  a.code=l.code
  a.safecode=a.code.gsub('/','_')
  a.url='/assets/'+a.safecode
  a.is_active=true
  a.name=l.name
  a.location=l.location
  a.boundary=l.boundary
  a.ref_id=l.topo50_fid
  a.save
  logger.debug a.code
  a
end

def Asset.add_sota_peak(p)
  a=Asset.find_by(asset_type: 'summit', code: p.summit_code)
  if !a then logger.debug "New peak: "+p.summit_code; a=Asset.new end
  a.asset_type="summit"
  a.code=p.summit_code
  a.safecode=a.code.gsub('/','_')
  a.is_active=true
  a.name=p.name
  a.location=p.location
  a.points=p.points
  a.altitude=p.alt
  if p.valid_to!="0001-01-01 00:00:00" then logger.debug "retured summit: "+a.code; a.valid_to=p.valid_to else a.valid_to=nil end
  if p.valid_from!="0001-01-01 00:00:00" then a.valid_from=p.valid_from end
  if a.changed? and (a.changed-['valid_from']).count>0 then
    logger.debug"Changed: "+a.changed.to_json
    a.save
    logger.debug "Create/Updated: "+a.code
  end
  a
end

def Asset.add_pota_parks
  ps=PotaPark.all
  ps.each do |p|
    Asset.add_pota_park(p)
  end
end

def Asset.add_pota_park(p, existing_asset)
  a=Asset.find_by(asset_type: 'pota park', code: p.reference)
  if !a then a=Asset.new end
  a.asset_type="pota park"
  a.code=p.reference
  a.safecode=p.reference.gsub('/','_')
  a.is_active=true
  if a.id and (a.name!=p.name or a.location!=p.location) then
    logger.warn "Exiting asset needs updating"
    name=p.name.gsub("'","''")
    if existing_asset  then
      ActiveRecord::Base.connection.execute("update assets set code='"+p.reference+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326), boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
    else
      ActiveRecord::Base.connection.execute("update assets set code='"+p.reference+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326) where id="+a.id.to_s+";")
    end
  elsif !a.id then
    logger.debug "Adding data to new asset"
    a.name=p.name
    a.location=p.location
    a.save
    if existing_asset  then
      ActiveRecord::Base.connection.execute("update assets set boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
      a.post_save_actions
    end
  end

  logger.debug a.code
  a
end

def Asset.add_humps
  ps=Hump.where('code is not null')
  ps.each do |p|
    Asset.add_hump(p, nil)
  end
end

def Asset.add_hump(p, existing_asset)
  a=Asset.find_by(asset_type: 'hump', code: p.code)
  if !a then
     a=Asset.new
     logger.debug "Adding new hump"
  end
  a.asset_type="hump"
  a.code=p.code
  a.is_active=true
  a.name=p.name
  if a.name==nil or a.name==="" then
    a.name=a.code
  end
  a.location=p.location
  a.region=p.region
  a.altitude=p.elevation
  if a.name and a.name.length>0 then a.is_active=true else a.is_active=false end
  a.save
  logger.debug a.code
  logger.debug a.name
  a
end

def Asset.add_lighthouses
  ps=Lighthouse.where('code is not null')
  ps.each do |p|
    Asset.add_lighthouse(p, nil)
  end
end

def Asset.add_volcanoes
  ps=Volcano.where('code is not null')
  ps.each do |p|
    Asset.add_volcano(p, nil)
  end
end

def Asset.add_volcano(p, existing_asset)
  a=Asset.find_by(asset_type: 'volcano', code: p.code)
  if !a then
     a=Asset.new
     puts "Adding new volcano"
  end
  a.asset_type="volcano"
#  if a.description=nil or a.description=="" then a.description=(p.status||"").capitalize+" based "+(if p.str_type=="lighthouse" then "lighthouse" else "light/beacon" end)+(if p.status then " ("+p.status+")" else "" end) end
  a.code=p.code
  a.is_active=true
  a.name=p.name
  a.location=p.location
  a.az_radius=p.az_radius
  a.save

  awl=AssetWebLink.find_by(asset_code: a.code)
  if !awl then awl=AssetWebLink.new; puts "New link" end
  awl.asset_code=a.code
  awl.url=p.url
  awl.link_class="other"
  awl.save

  logger.debug a.code
  logger.debug a.name
  a

  a.add_activation_zone(true)
end

def Asset.add_wwff_parks
  ps=WwffPark.all
  ps.each do |p|
    Asset.add_wwff_park(p, nil)
  end
end
def Asset.add_lighthouse(p, existing_asset)
  a=Asset.find_by(asset_type: 'lighthouse', code: p.code)
  if !a then
     a=Asset.new
     logger.debug "Adding new lighthouse"
  end
  a.asset_type="lighthouse"
  if a.description=nil or a.description=="" then a.description=(p.loc_type||"").capitalize+" based "+(if p.str_type=="lighthouse" then "lighthouse" else "light/beacon" end)+(if p.status then " ("+p.status+")" else "" end) end
  a.code=p.code
  a.is_active=true
  a.name=p.name
  a.location=p.location
  a.region=p.region
  if p.mnz_id != nil and p.mnz_id!="" then a.category="Maritime NZ" end
  if a.name and a.name.length>0 then a.is_active=true else a.is_active=false end
  a.save
  logger.debug a.code
  logger.debug a.name
  a
end

def Asset.add_wwff_parks
  ps=WwffPark.all
  ps.each do |p|
    Asset.add_wwff_park(p, nil)
  end
end

def Asset.add_wwff_park(p, existing_asset)
  a=Asset.find_by(asset_type: 'wwff park', code: p.code)
  if !a then a=Asset.new end
  a.asset_type="wwff park"
  a.code=p.code
  a.is_active=true

  if a.id and (a.name!=p.name or a.location!=p.location) then
    logger.debug "Exiting asset needs updating"
    name=p.name.gsub("'","''")
    if existing_asset  then
      ActiveRecord::Base.connection.execute("update assets set code='"+p.code+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326), boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
    else
      ActiveRecord::Base.connection.execute("update assets set code='"+p.code+"', name='"+name+"', is_active=true, location=ST_GeomFromText('POINT(#{p.location.x} #{p.location.y})',4326) where id="+a.id.to_s+";")
    end
  elsif !a.id then
    logger.debug "Adding data to new asset"
    a.name=p.name
    a.location=p.location
    a.save
    if existing_asset  then
      ActiveRecord::Base.connection.execute("update assets set boundary=(select boundary from assets where id="+existing_asset.id.to_s+") where id="+a.id.to_s+";")
      a.post_save_actions
    end
  end
  logger.debug a.code
  a
end

end
