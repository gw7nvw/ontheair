# frozen_string_literal: true

# typed: false
module AssetConsoleTools
  # Add / reapply region to all assets
  def Asset.add_regions
    count = 0
    a = Asset.first_by_id
    while a
      logger.debug a.code + ' ' + count.to_s
      count += 1
      a.add_region
      a = Asset.next(a.id)
    end
  end

  # Add / reapply district to all assets
  def Asset.add_districts
    count = 0
    a = Asset.first_by_id
    while a
      logger.debug a.code + ' ' + count.to_s
      count += 1
      a.add_district
      a = Asset.next(a.id)
    end
  end

  # Rebuild asset links for all assets
  def Asset.add_links
    as = Asset.find_by_sql [' select id,code from assets ']
    as.each do |aa|
      logger.debug aa.code
      a = Asset.find_by_id(aa.id)
      a.add_links
    end
  end

  # Remove any links that point to non-existant assets
  def Asset.prune_links
    als = AssetLink.all
    als.each do |al|
      al.destroy if !al.parent || !al.child
    end
  end

  # resave all assets
  def Asset.update_all
    a = Asset.first_by_id
    while a
      a.save
      a = Asset.next(a.id)
      logger.debug a.code
    end
  end

  # add loction based on polygon for any assets missing a location
  def Asset.add_centroids
    a = Asset.first_by_id
    while a
      unless a.location
        logger.debug a.code
        location = a.calc_location
        if location
          a.location = location
          a.save
        end
      end
      a = Asset.next(a.id)
    end
  end

  def Asset.add_sota_activation_zones(force = false)
    count = 0
    as = if force == false
           Asset.where(asset_type: 'summit', boundary: nil)
         else
           Asset.where(asset_type: 'summit')
         end
    as.each do |a|
      count += 1
      a.add_sota_activation_zone
      a.get_access
    end
  end

  def Asset.add_hema_activation_zones(force = false)
    count = 0
    as = if force == false
           Asset.where(asset_type: 'hump', boundary: nil)
         else
           Asset.where(asset_type: 'hump')
         end
    as.each do |a|
      count += 1
      a.add_sota_activation_zone
      a.get_access
    end
  end

  def Asset.get_hema_access
    as = Asset.where(asset_type: 'hump')
    as.each do |a|
      logger.debug a.code
      a.get_access
    end
  end

  def Asset.get_sota_access
    as = Asset.where(asset_type: 'summit')
    as.each do |a|
      logger.debug a.code
      a.get_access
    end
  end

  def Asset.get_lake_access
    as = Asset.where(asset_type: 'lake')
    as.each do |a|
      logger.debug a.code
      a.get_access_with_buffer(500)
    end
  end

  def add_url_from_description(move=false)
    urls=description.scan(/(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])/) if description
    if urls
      urls.each do |url|
        awl = AssetWebLink.new
        awl.asset_code = code
        awl.url = url[0]+"://"+url[1]+url[2]
        awl.link_class = 'other'
        dup_awl = AssetWebLink.find_by(asset_code: code, url: awl.url)
        puts "Found: "+awl.url
        awl.save unless dup_awl
      end
      description.gsub(/(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])/,'') if move
    end
  end

  ##################################################
  # Step through assets without loading entire list
  ##################################################
  def Asset.first_by_id
    Asset.where('id > ?', 0).order(:id).first
  end

  def Asset.next(id)
    Asset.where('id > ?', id).order(:id).first
  end
end
