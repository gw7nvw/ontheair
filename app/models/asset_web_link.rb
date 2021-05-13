class AssetWebLink < ActiveRecord::Base

def web_link_class
  wlc=WebLinkClass.find_by(name: self.link_class)
end

def self.migrate
   a=Asset.first_by_id
   while a do 
      puts a.code
      hl=a.r_field('hutbagger_link')
      if hl and hl.length>0 then AssetWebLink.create(asset_code: a.code, url: hl, link_class: 'hutbagger') end
      hl=a.r_field('tramper_link')
      if hl and hl.length>0 then AssetWebLink.create(asset_code: a.code, url: hl, link_class: 'tramper') end
      hl=a.r_field('routeguides_link')
      if hl and hl.length>0 then AssetWebLink.create(asset_code: a.code, url: hl, link_class: 'routeguides') end
      hl=a.r_field('doc_link')
      if hl and hl.length>0 then AssetWebLink.create(asset_code: a.code, url: hl, link_class: 'doc') end
      hl=a.r_field('general_link')
      if hl then AssetWebLink.create(asset_code: a.code, url: hl, link_class: 'other') end
      a=Asset.next(a.id)
   end
end
end
