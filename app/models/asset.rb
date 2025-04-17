# typed: true
class Asset < ActiveRecord::Base
  include AssetGisTools
  include AssetConsoleTools

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  before_validation { assign_calculated_fields }
  after_save { post_save_actions }

  SIOTA_REGEX = /^VK-[a-zA-Z]{3}\d{1}/
  POTA_REGEX = /^[a-zA-Z0-9]{1,2}-\d{4,5}/
  WWFF_REGEX = /^\d{0,1}[a-zA-Z]{1,2}[fF]{2}-\d{4}/
  SOTA_REGEX = /^\d{0,1}[a-zA-Z]{1,2}\d{0,1}\/[a-zA-Z]{2}-\d{3}/
  HEMA_REGEX = /^\d{0,1}[a-zA-Z]{1,2}\d{0,1}\/H[a-zA-Z]{2}-\d{3}/

  SOTA_ASSET_URL = 'https://www.sotadata.org.uk/en/summit/'
  WWFF_ASSET_URL = 'https://wwff.co/directory/?showRef='
  POTA_ASSET_URL = 'https://pota.app/#/park/'
  HEMA_ASSET_URL = 'http://www.hema.org.uk/fullSummit.jsp?summitKey='
  SIOTA_ASSET_URL = 'https://www.silosontheair.com/silos/#'

  ################################################################
  # Pre- and Post save callbacks
  ################################################################

  # After save (things that need an asset id, generally)
  def post_save_actions
    # do this here rather then before save to keep it pure PostGIS: no slow RGeo
    add_area
    add_altitude
    add_links
    add_simple_boundary
    self.reload
    add_activation_zone(true)
  end

  # After validation but before save
  def assign_calculated_fields
    self.valid_from = Time.new('1900-01-01') unless valid_from
    self.minor = false if minor != true

    self.district = add_district if !district or district.blank?
    self.region = add_region if !region or region.blank? 

    if code.nil? || (code == '')
      if self.type.use_volcanic_field then 
        self.code = Asset.get_next_code(asset_type, field_code)
      else
        self.code = Asset.get_next_code(asset_type, region)
      end
    end
    self.safecode = code.tr('/', '_') 

    self.url = 'assets/' + safecode

    self.az_radius=1.0*self.type.dist_buffer/1000 if az_radius==nil and self.type.dist_buffer
  end

  def add_links(flush = true)
    if flush == true
      las = AssetLink.where(contained_code: code)
      Rails.logger.warn "DEBUG: deleting #{las.count} old parent links"
      las.destroy_all
      las = AssetLink.where(containing_code: code)
      Rails.logger.warn "DEBUG: deleting #{las.count} old child links"
      las.destroy_all
    end

    return unless is_active
    area_query='true';

    # check assets contained by us, then assets containign us
    ['we are contained by', 'we contain'].each do |link_type|
      if link_type == 'we are contained by'
        within_query = 'ST_Within(a.location, b.az_boundary)'
        area_query = 'b.az_area>a.az_area*0.9' if az_area 
      else
        within_query = 'ST_Within(b.location, a.az_boundary)'
        area_query = 'a.az_area>b.az_area*0.9' if az_area
      end
      linked_assets = Asset.find_by_sql ["
        select b.code as code, at.has_boundary as has_boundary, at.use_az as use_az, b.az_area as az_area
          from assets a
        inner join assets b
          on b.is_active=true and " + within_query + "
        inner join asset_types at
          on at.name=b.asset_type
        where
          b.id!=a.id
          and (b.az_area is null or " + area_query + ")
          and a.id = " + id.to_s]
      logger.debug code + ' might ' + link_type + ' ' + linked_assets.to_json
      linked_assets.each do |linked_asset|
        matched = false

        # get the parameters the right way round for containing vs contained
        if link_type == 'we contain'
          contained_asset_code = linked_asset['code']
          containing_asset_code = code
        else
          containing_asset_code = linked_asset['code']
          contained_asset_code = code
        end
        # for assets with az_boundary, ensure >=90% overlap
        if az_area && (az_area > 0) && linked_asset['az_area'] && (linked_asset['az_area'] > 0)
          overlap = ActiveRecord::Base.connection.execute(" select ST_Area(ST_intersection(a.az_boundary, b.az_boundary)) as overlap, ST_Area(b.az_boundary) as area from assets a join assets b on b.code='#{contained_asset_code}' where a.code='#{containing_asset_code}'; ")
          prop_overlap = overlap.first['overlap'].to_f / overlap.first['area'].to_f
          logger.debug "DEBUG: overlap #{prop_overlap} " + linked_asset['code']
          matched = true if prop_overlap > 0.9

        # for point assets, accept point contained in polygon
        else
          matched = true
          logger.debug 'DEBUG: Point: ' + linked_asset['code']
        end

        # Fore all matched assets, if this combo does not already exist, create it
        next unless matched == true
        logger.debug containing_asset_code + ' contains ' + contained_asset_code
        dup = AssetLink.where(contained_code: contained_asset_code, containing_code: containing_asset_code)
        next unless (!dup || dup.count.zero?) && (linked_asset['code'] != code)
        al = AssetLink.new
        al.contained_code = contained_asset_code
        al.containing_code = containing_asset_code
        al.save
      end # for linked assets
    end # for contained, containing
  end

  # add region - done directly in database so safe as an after-save callback
  def add_region
    location ? (region = Region.find_by_sql ["select id, sota_code, name from regions where ST_Within(ST_GeomFromText('" + location.as_text + %q{', 4326), "boundary");}]) : (logger.error 'ERROR: place without location. Name: ' + name + ', id: ' + id.to_s)
    if id && region && (region.count > 0) && (self.region != region.first.sota_code)
      logger.debug 'updating region to ' + region.first.to_json
      ActiveRecord::Base.connection.execute("update assets set region='" + region.first.sota_code + "' where id=" + id.to_s)
    end

    if region && (region.count > 0) && (self.region != region.first.sota_code)
      return region.first.sota_code
    end
  end

  # add district - done directly in database so safe as an after-save callback
  def add_district
    location ? (district = District.find_by_sql ["select id, district_code, name from districts where ST_Within(ST_GeomFromText('" + location.as_text + %q{', 4326), "boundary");}]) : (logger.error 'ERROR: place without location. Name: ' + name + ', id: ' + id.to_s)
    if id && district && (district.count > 0) && (self.district != district.first.district_code)
      ActiveRecord::Base.connection.execute("update assets set district='" + district.first.district_code + "' where id=" + id.to_s)
    end

    if district && (district.count > 0) && (self.district != district.first.district_code)
      return district.first.district_code
    end
  end

  #############################################################
  # LINKED TABLES
  #############################################################

  # all photos for this asset
  def photos
    AssetPhotoLink.where(asset_code: code)
  end

  # all contacts referring to this asset
  def contacts
    Contact.find_by_sql ["select * from contacts c where '" + code + "' = ANY(asset1_codes) or '" + code + "' = ANY(asset2_codes);"]
  end

  def geology
    VolcanicField.find_by(code: field_code)
  end

  # all logs referring to this asset
  def logs
    Log.find_by_sql ["select * from logs l where '" + code + "' = ANY(asset_codes);"]
  end

  # all web links for this asset
  def web_links
    AssetWebLink.where(asset_code: code)
  end

  # hutbagger page for this asset
  def hutbagger_link
    AssetWebLink.find_by(asset_code: code, link_class: 'hutbagger')
  end

  # Returns string containing code and name: [<code>] <name
  def codename
    '[' + code + '] ' + name
  end

  # AssetType
  def type
    type = AssetType.find_by(name: asset_type)
    type ||= AssetType.find_by(name: 'all')
    type
  end

  def linked_assets
    assets = nil
    als = AssetLink.find_by_parent(code)
    if als
      codes = als.map(&:containing_code)
      assets = Asset.where(code: codes)
    end
    assets
  end

  def linked_assets_by_type(asset_type)
    assets = nil
    als = AssetLink.find_by_parent(code)
    if als
      codes = als.map(&:containing_code)
      assets = Asset.where(code: codes, asset_type: asset_type)
    end
    assets
  end

  # Traditional owners of land containing this asset.
  # if many, proide as comma-separated list
  # If we are near the boundary, hedge our bets and say 'in or near'
  def traditional_owners
    trad_owners=nil
    if (!!NzTribalLands rescue false) then
      buffer = 5000 # say in or near if we are withing this distance of boundary (meters)
      if type.has_boundary && area && (area > 0)
        tos1 = NzTribalLand.find_by_sql ["select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{id} where ST_Within(a.boundary, tl.wkb_geometry) "]
        tos2 = NzTribalLand.find_by_sql ["select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{id} where ST_DWithin(ST_Transform(a.boundary,2193), ST_Transform(tl.wkb_geometry,2193), #{buffer});"]
      else
        tos1 = NzTribalLand.find_by_sql ["select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{id} where ST_Within(a.location, tl.wkb_geometry) "]
        tos2 = NzTribalLand.find_by_sql ["select tl.id, tl.name, tl.ogc_fid from nz_tribal_lands tl join assets a on a.id=#{id} where ST_DWithin(ST_Transform(a.location,2193), ST_Transform(tl.wkb_geometry,2193), #{buffer});"]
  
      end
      ids1 = tos1.map(&:id)
      ids2 = tos2.map(&:id)
      if ids2 && (ids2.count > 0)
        names = []
        if ids1.sort != ids2.sort
          tos2.each { |t| names.push(t['name']) }
          trad_owners = 'In or near ' + names.join(', ') + ' country'
        else
          tos1.each { |t| names.push(t['name']) }
          trad_owners = names.join(', ') + ' country'
        end
      else
        trad_owners = nil
      end
    end
    trad_owners
  end

  ####################################################################
  # Virtual calculated fields

  def self.maidenhead_to_lat_lon(maidenhead)
    maidenhead = maidenhead[0..5]
    # pad 4 digit maidenhead to 6
    maidenhead += 'aa' if maidenhead.length == 4
    abc = 'abcdefghijklmnopqrstuvwxyz'
    long20 = abc.upcase.index(maidenhead[0]).to_f
    lat10 = abc.upcase.index(maidenhead[1]).to_f
    long2 = maidenhead[2].to_f
    lat1 = maidenhead[3].to_f
    longm = abc.index(maidenhead[4]).to_f
    latm = abc.index(maidenhead[5]).to_f

    long = long20 * 20 + long2 * 2 + longm / 12
    lat = lat10 * 10 + lat1 + latm / 24
    long -= 180
    lat -= 90
    { x: long, y: lat }
  end

  # Return 6-digit maidenhead locator from location
  def maidenhead
    if location
      mhl = '######'
      abc = 'abcdefghijklmnopqrstuvwxyz'
      lat = location.y
      long = location.x
      long += 180
      lat += 90

      long20 = (long / 20).to_i
      lat10 = (lat / 10).to_i
      long2 = ((long - (long20 * 20)) / 2).to_i
      lat1 = (lat - (lat10 * 10)).to_i
      longm = ((long - (long20 * 20 + long2 * 2)) * 12).to_i
      latm = ((lat - (lat10 * 10 + lat1)) * 24).to_i
      mhl[0] = abc[long20].upcase
      mhl[1] = abc[lat10].upcase
      mhl[2] = long2.to_s
      mhl[3] = lat1.to_s
      mhl[4] = abc[longm]
      mhl[5] = abc[latm]
    else
      mhl = ''
    end
    mhl
  end

  # simplified boundary with downscaling big assets (and detail/accuracy for small assets)
  def boundary_simple
    pp = Asset.find_by_sql ['select id, ST_NPoints(boundary) as numpoints from assets where id=' + id.to_s]
    if pp
      lenfactor = Math.sqrt((pp.first['numpoints'] || 0) / 10_000)
      rnd = 0.000002 * 10**lenfactor
      boundarys = Asset.find_by_sql ['select id, ST_AsText(ST_Simplify("boundary", ' + rnd.to_s + ')) as "boundary" from assets where id=' + id.to_s]
      boundary = boundarys.first.boundary
      boundary
    end
  end

  # simplified az boundary with downscaling big assets (and detail/accuracy for small assets)
  def az_boundary_simple
    pp = Asset.find_by_sql ['select id, ST_NPoints(az_boundary) as numpoints from assets where id=' + id.to_s]
    if pp
      lenfactor = Math.sqrt((pp.first['numpoints'] || 0) / 10_000)
      rnd = 0.000002 * 10**lenfactor
      boundarys = Asset.find_by_sql ['select id, ST_AsText(ST_Simplify("az_boundary", ' + rnd.to_s + ')) as "boundary" from assets where id=' + id.to_s]
      boundary = boundarys.first.boundary
      boundary
    end
  end

  # name of distirct (without getting it's boundary)
  def district_name
    r = District.find_by(district_code: district)
    r ? r.name : ''
  end

  # name of region (without getting it's boundary)
  def region_name
    r = Region.find_by(sota_code: region)
    r.name.gsub('Region', '') if r
  end

  # NZTM coordinates: x
  def x
    if(Projection.find_by_id(2193)) then srs=2193 else srs=4326 end
    if location
      fromproj4s = Projection.find_by_id(4326).proj4
      toproj4s = Projection.find_by_id(srs).proj4

      fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
      toproj = RGeo::CoordSys::Proj4.new(toproj4s)

      xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, location.x, location.y)
      xyarr[0]
    end
  end

  # NZTM coordinates: y
  def y
    if(Projection.find_by_id(2193)) then srs=2193 else srs=4326 end
    if location
      fromproj4s = Projection.find_by_id(4326).proj4
      toproj4s = Projection.find_by_id(srs).proj4

      fromproj = RGeo::CoordSys::Proj4.new(fromproj4s)
      toproj = RGeo::CoordSys::Proj4.new(toproj4s)

      xyarr = RGeo::CoordSys::Proj4.transform_coords(fromproj, toproj, location.x, location.y)
      xyarr[1]
    end
  end

  def first_activated
    cs = Contact.find_by_sql [' select * from contacts where ? = ANY(asset1_codes) or ? = ANY(asset2_codes) order by date, time limit 1 ', code, code]
    if cs && (cs.count > 0)
      c = cs.first
      c = c.reverse if c.asset2_codes.include?(code)
    else
      c = nil
    end

    if (asset_type == 'summit') || (asset_type == 'pota park')
      as = ExternalActivation.find_by_sql ["select * from external_activations where summit_code='" + code + "' order by date asc limit 1"]
      if as && as[0] && (c.nil? || (as[0].date < c.date))
        c = Contact.new
        c.callsign1 = as[0].callsign
        c.date = as[0].date
        c.time = as[0].date
        c.callsign2 = ''
        c.id = -99
        # find first chase
        if as[0].external_activation_id then acs = ExternalChase.find_by_sql ["select * from external_chases where external_activation_id=#{as[0].external_activation_id} order by time asc limit 1"] end
        if acs && (acs.count > 0)
          ac = acs.first
          c.callsign2 = ac.callsign
        end
      end
    end

    c
  end

  ############################################################
  # DETAILS OF ACTIVATIONS, CHASES ETC FOR THIS ASSET
  ############################################################
  def activation_count
    logs = self.logs
    count = 0
    logs.each do |log|
      count += 1 if log.contacts.count > 0
    end
    count
  end

  def activators
    cals1 = Contact.where('? = ANY(asset1_codes)', code)
    callsigns1 = cals1.map { |cal| User.find_by_callsign_date(cal.callsign1, cal.date).try(:callsign) }
    cals2 = Contact.where('? = ANY(asset2_codes)', code)
    callsigns2 = cals2.map { |cal| User.find_by_callsign_date(cal.callsign2, cal.date).try(:callsign) }
    callsigns = callsigns1 + callsigns2
    User.where(callsign: callsigns).order(:callsign)
  end

  def external_activators
    cals = ExternalActivation.where(summit_code: code)
    callsigns = cals.map { |cal| cal.callsign if cal }
    User.where(callsign: callsigns).order(:callsign)
  end

  def activators_including_external
    users = external_activators + activators
    users.uniq.sort_by(&:callsign)
  end

  def chasers
    cals = Contact.where('? = ANY(asset1_codes)', code)
    callsigns1 = cals.map { |cal| User.find_by_callsign_date(cal.callsign2, cal.date).try(:callsign) }
    cals2 = Contact.where('? = ANY(asset2_codes)', code)
    callsigns2 = cals2.map { |cal| User.find_by_callsign_date(cal.callsign1, cal.date).try(:callsign) }
    callsigns = callsigns1 + callsigns2
    User.where(callsign: callsigns).order(:callsign)
  end

  def external_chasers
    cals = ExternalChase.where(summit_code: code)
    callsigns = cals.map(&:callsign)
    User.where(callsign: callsigns).order(:callsign)
  end

  def chasers_including_external
    users = external_chasers + chasers
    users.uniq.sort_by(&:callsign)
  end

  #############################################################
  # Lookthrough to underlying asset type specific tables
  # - Used as different asset types have different patrameters
  # - AssetType.tablename defines table underlying each asset type
  # - AssetType.fields lists fields to be displayed for each asset type
  #############################################################

  # Return underlying table containing info about this asset
  def table
    type.table_name.safe_constantize
  end

  # Return underlying record containing info about this asset
  def record
    type.table_name.safe_constantize.find_by(type.index_name => code)
  end

  # Return value of field <name> from the underlying table for this asset
  def r_field(name)
    record[name] if record && record.respond_to?(name)
  end

  #################################################################
  # SIMPLE QUERIES
  #################################################################
  # return true if this asset activated by given callsign
  def activated_by?(callsign)
    if callsign && (callsign != '') && (callsign != '*')
      callsign = callsign.upcase

      cs = Contact.find_by_sql [' select id from contacts where (callsign1 = ? and ? = ANY(asset1_codes)) or (callsign2 = ? and ? = ANY(asset2_codes)) limit 1 ', callsign, code, callsign, code]

      if (asset_type == 'summit') || (asset_type == 'pota park')
        as = ExternalActivation.find_by_sql ["select * from external_activations where summit_code='" + code + "' and callsign = '" + callsign + "' limit 1"]
      end

      (as && (as.count > 0)) || (cs && (cs.count > 0))
    else
      cs = Contact.find_by_sql [' select id from contacts where (? = ANY(asset1_codes)) or (? = ANY(asset2_codes)) limit 1 ', code, code]

      if (asset_type == 'summit') || (asset_type == 'pota park')
        as = ExternalActivation.find_by_sql ["select * from external_activations where summit_code='" + code + "' limit 1"]
      end
      (as && (as.count > 0)) || (cs && (cs.count > 0)) ? true : false
    end
  end

  # return true if this asset chased by given callsign
  def chased_by?(callsign)
    if callsign && (callsign != '') && (callsign != '*')
      callsign = callsign.upcase
      cs = Contact.find_by_sql [' select id from contacts where (callsign2 = ? and ? = ANY(asset1_codes)) or (callsign1 = ? and ? = ANY(asset2_codes)) limit 1 ', callsign, code, callsign, code]

      if (asset_type == 'summit') || (asset_type == 'pota park')
        as = ExternalChase.find_by_sql ["select * from external_chases where summit_code='" + code + "' and callsign = '" + callsign + "' limit 1"]
      end

      (as && (as.count > 0)) || (cs && (cs.count > 0))
    else
      cs = Contact.find_by_sql [' select id from contacts where (? = ANY(asset1_codes)) or (? = ANY(asset2_codes)) limit 1 ', code, code]

      if (asset_type == 'summit') || (asset_type == 'pota park')
        as = ExternalChase.find_by_sql ["select * from external_chases where summit_code='" + code + "' limit 1"]
      end

      (as && (as.count > 0)) || (cs && (cs.count > 0)) ? true : false
    end
  end

  # turn code into a URL-safe version
  def get_safecode
    code.tr('/', '_')
  end

  # Turn URL-safe 'safecode' into a code
  def self.decode_safecode(safecode)
    safecode.tr('_', '/')
  end

  ########################################################
  # Assets containing this asset
  ########################################################

  # Asset list for all assets containing us
  def contained_by_assets
    Asset.find_by_sql [" select a.* from asset_links al inner join assets a on a.code=al.containing_code where al.contained_code = '#{code}' and a.is_active=true "]
  end

  # Asset names for all assets containing us
  def contained_by_names
    Asset.find_by_sql [" select a.name, a.code, a.safecode from asset_links al inner join assets a on a.code=al.containing_code where al.contained_code = '#{code}' and a.is_active=true "]
  end

  # Asset types for all assets containing us
  def contained_by_classes
    als = AssetLink.where(contained_code: code)
    acs = als.map { |al| al.child.asset_type }
    acs.uniq
  end

  # return assets containing this asset that match specified type
  def contained_by_by_type(asset_type)
    als = AssetLink.where(contained_code: code)
    codes = als.map(&:containing_code)
    Asset.where(code: codes, asset_type: asset_type, is_active: true)
  end

  ########################################################
  # Assets contained by this asset
  ########################################################

  # Asset list (assets we contain)
  def contains_assets
    Asset.find_by_sql [" select a.* from asset_links al inner join assets a on a.code=al.contained_code where al.containing_code = '#{code}' and a.is_active=true "]
  end

  # Asset type list (assets we contain)
  def contains_classes
    als = AssetLink.where(containing_code: code)
    acs = als.map { |al| if al.parent then al.parent.asset_type else 'unknown' end }
    acs.uniq
  end

  ######################################################
  # GET INFO ABOUT ASSET FROM CODE
  ######################################################

  # Provide infomation about the asset that a code refers to
  # Checks:
  # - Assets table
  # - VkAssets table
  # - then calculates info based on the code from fixed rules
  #   for any other codes
  # Input: codes: [code]
  # Returns:
  #   assets: [{
  #           asset: Asset
  #           name: Name of asset (or code if we do not know name)
  #           url: URL of this asset as locally as possible (here=>PnP=>award programme)
  #           external: true if not hosted on ontheair
  #           code: code
  #           type: AssetType
  #           title: Award programme name
  #         }]

  def self.assets_from_code(codes)
    assets = []
    if codes
      code_arr = codes.split(',')
      code_arr.each do |code|
        if code and code.match(/[a-zA-Z]/) then
          code = code.delete('[').delete(']')
          code = code.lstrip
          asset = { asset: nil, code: nil, name: nil, url: nil, external: nil, type: nil }
          next unless code
          code = code.upcase
          a = Asset.find_by(code: code.split(' ')[0])
          a ||= Asset.find_by(old_code: code.split(' ')[0])
          va = VkAsset.find_by(code: code.split(' ')[0])
  
          # Assets listed on ontheair.nz - look up in db
          if a
            asset[:asset] = a
            asset[:url] = a.url
            a[:url] = a[:url][1..-1] if a[:url][0] == '/'
            asset[:name] = a.name
            asset[:codename] = a.codename
            asset[:external] = false
            asset[:code] = a.code
            asset[:type] = a.asset_type
            asset[:external_url] = a.external_url unless code =~ /ZL^[a-zA-Z]-./
            a.type ? (asset[:title] = a.type.display_name) : (logger.error 'ERROR: cannot find type ' + a.asset_type)
            asset[:url] = '/' + asset[:url] if asset[:url][0] != '/'
  
          # Assets in VK pulled in from PnP - look up in VK db tables
          elsif va
            asset[:asset] = va
            asset[:url] = '/vkassets/' + va.get_safecode
            asset[:name] = va.name
            asset[:codename] = va.codename
            asset[:external] = false
            asset[:code] = va.code
            asset[:type] = va.award
            asset[:type] = 'summit' if asset[:type] == 'SOTA'
            asset[:type] = 'pota park' if asset[:type] == 'POTA'
            asset[:type] = 'wwff park' if asset[:type] == 'WWFF'
            asset[:external_url] = va.external_url
  
            asset[:title] = va.site_type
  
          # Otherwise - we guess based on the reference
          elsif (thecode = code.match(HEMA_REGEX))
            # HEMA
            logger.debug 'HEMA'
            asset[:name] = code
            asset[:url] = 'http://hema.org.uk'
            asset[:external] = true
            asset[:code] = thecode.to_s
            asset[:type] = 'hump'
            asset[:title] = 'HEMA'
  
          elsif (thecode = code.match(SIOTA_REGEX))
            # SiOTA
            logger.debug 'SiOTA'
            asset[:name] = code
            asset[:url] = SIOTA_ASSET_URL + thecode.to_s
            asset[:external] = true
            asset[:code] = thecode.to_s
            asset[:type] = 'silo'
            asset[:title] = 'SiOTA'
  
          elsif (thecode = code.match(POTA_REGEX))
            # POTA
            logger.debug 'POTA'
            asset[:url] = POTA_ASSET_URL + thecode.to_s
            asset[:title] = 'POTA'
            asset[:name] = code
            asset[:external] = true
            asset[:code] = thecode.to_s
            asset[:type] = 'pota park'
  
          elsif (thecode = code.match(WWFF_REGEX))
            # WWFF
            logger.debug 'WWFF'
            logger.debug thecode
            asset[:url] = WWFF_ASSET_URL + thecode.to_s
            asset[:name] = code
            asset[:external] = true
            asset[:code] = thecode.to_s
            asset[:type] = 'wwff park'
            asset[:title] = 'WWFF'
  
          elsif (thecode = code.match(SOTA_REGEX))
            # SOTA
            logger.debug 'SOTA'
            asset[:name] = code
            asset[:url] = SOTA_ASSET_URL + thecode.to_s
            asset[:external] = true
            asset[:code] = thecode.to_s
            asset[:type] = 'summit'
            asset[:title] = 'SOTA'
          end
          assets.push(asset) if asset[:code]
          # if code provided
        end # if code
      end # for each code in codes
    end # if codes provided

    assets
  end

  # Asset type
  def self.get_asset_type_from_code(code)
    a = Asset.assets_from_code(code)
    a && a.first && a.first[:type] ? a.first[:type] : 'all'
  end

  # Provide an external URL for this internal asset, if we know of one
  # Should be the link to the asset page for this asset on the website
  # of the governing award programme
  # Returns: url: Url
  def external_url
    url = nil
    code = self.code.lstrip
    asset_type = self.asset_type
    if asset_type == 'pota park'
      # POTA
      url = POTA_ASSET_URL + code
    elsif asset_type == 'wwff park'
      # WWFF
      url = WWFF_ASSET_URL + code
    elsif asset_type == 'summit'
      # SOTA
      url = SOTA_ASSET_URL + code
    elsif (asset_type == 'hump') && old_code && (old_code.to_i > 0)
      # HEMA
      url = HEMA_ASSET_URL + old_code
    end
    url
  end

  # Return the activity class used by PnP for a given asset code / reference
  # Uses Asset table for known assets
  # Looks up the reference against naming rules if not in our database
  def self.get_pnp_class_from_code(code)
    aa = Asset.assets_from_code(code)
    pnp_class = 'QRP'
    if aa
      a = aa.first
      if a
        if a && a[:type] && (a[:external] == false)
          ac = AssetType.find_by(name: a[:type])
          pnp_class = ac.pnp_class
        elsif a[:title][0..3] == 'WWFF' then pnp_class = 'WWFF'
        elsif a[:title][0..3] == 'POTA' then pnp_class = 'POTA'
        elsif a[:title][0..3] == 'HEMA' then pnp_class = 'HEMA'
        elsif a[:title][0..4] == 'SiOTA' then pnp_class = 'SiOTA'
        end
      end
    end
    pnp_class
  end

  ##################################################################
  # HELPERS
  #
  # Providing common services for assets to other models
  #
  ##################################################################

  # Replaces codes with master_code if one exists
  # for a repaced asset
  # Input: [codes]
  # Returns: [codes]
  def self.find_master_codes(codes)
    newcodes = []
    codes.each do |code|
      a = Asset.find_by(code: code)

      if a && (a.is_active == false)
        code = a.master_code if a.master_code
      end
      newcodes += [code]
    end
    newcodes.uniq
  end

  # Extract asset coodes from a textual description field
  # Input: string
  # Returns: [codes]
  def self.check_codes_in_text(location_text)
    assets = Asset.assets_from_code(location_text)
    asset_codes = []
    assets.each do |asset|
      if asset && asset[:code]
        if asset_codes == []
          asset_codes = [(asset[:code]).to_s]
        else
          asset_codes.push((asset[:code]).to_s)
        end
      end
    end
    asset_codes
  end

  # Find most accurate location (lat/long) from a list of codes
  # if loc_source is provided then act as if we already have a location of
  # that type (area||point||user) and only find things more accurate
  # Input: [codes], 'area' or 'point' or nil
  # Returns: {location: Point, loc_source: 'point'||'area'||'user', asset: Asset
  def self.get_most_accurate_location(codes, loc_source = '', location = nil)
    loc_asset = nil
    accuracy = 999_999_999_999

    if codes.count > 1
      codes.each do |code|
        logger.debug "DEBUG: assessing code2 #{code}"
        assets = Asset.find_by_sql [" select id, code, safecode, asset_type, location, az_area, area from assets where code='#{code}' limit 1"]
        asset = assets ? assets.first : nil
        if asset
          # only consider polygon loc's if we don't already have a point loc
          # use this location if polygon area smaller than previous polygon used
          if asset.type.has_boundary
            if (loc_source != 'point') && (loc_source != 'user') && asset.area && (asset.area < accuracy)
              location = asset.location
              loc_asset = asset
              accuracy = asset.area
              loc_source = 'area'
              logger.debug 'DEBUG: Assigning polygon locn'
            end
          elsif loc_source != 'user'
            # if there are two point locations (e.g. summit and hut)
            # just use the last found (no way to know which is more accurate)
            if loc_source == 'point'
              logger.debug 'Multiple POINT locations found'
            end

            # assign point location
            location = asset.location
            loc_asset = asset
            loc_source = 'point'
            logger.debug 'DEBUG: Assigning point locn'
          end
        end
      end
    end
    # single asset or nothing found from search, just use the first location
    if !location && (codes.count > 0)
      assets = Asset.find_by_sql [" select id, code, safecode, asset_type, location, az_area, area from assets where code='#{codes.first}' limit 1"]
      if assets && (assets.count > 0)
        loc_asset = assets.first
        loc_asset.type.has_boundary ? (loc_source = 'area') : (loc_source = 'point')
        location = loc_asset.location
      end
    end
    { location: location, source: loc_source, asset: loc_asset }
  end

  # Catch common errors in separators used in references in ZLOTA formats:
  # ZLx/xx-###
  # ZLx/####
  def self.correct_separators(code)
    # ZLOTA
    if code =~ /^[zZ][lL][a-zA-Z][-_\/][a-zA-Z]{2}[-_\/]\d{3,4}/
      code[3] = '/'
      code[6] = '-'
    elsif code =~ /^[Zz][Ll][a-zA-Z][-_\/]\d{3,4}/
      code[3] = '/'
    end
    code
  end

  # Calculate maindenhead for any location (point)
  # Input location: Point
  # Returns: maidenhead: string
  def self.get_maidenhead_from_location(location)
    a = Asset.new
    a.location = location
    a.maidenhead
  end

  # Look up all assets that contain a given location point / polygon
  # Optionally provide an asset from which the location was derived
  # Optionally also check for point locations with activation_zones
  # Input: location: Point, asset: Asset or nil, include_point: boolean 
  # Returns: codes: [code]
  #
  # TODO: Logic here is same as that in def add_links, can the two be combined?
  def self.containing_codes_from_location(location, asset = nil, include_point = false, min_overlap=0.9)
    loc_type = 'point'
    codes = []
    if asset && asset.az_area && (asset.az_area > 0)
      loc_type = 'area'
    end

    if !location.nil? && !location.to_s.empty?
      # find all assets containing this location point
      if include_point then
        codes = Asset.find_by_sql ["select code from assets a where a.is_active=true and ST_Intersects(ST_GeomFromText('#{location}',4326), a.az_boundary); "]
      else
        codes = Asset.find_by_sql ["select code from assets a where a.is_active=true and a.az_area>0 and ST_Intersects(ST_GeomFromText('#{location}',4326), a.az_boundary); "]
      end
      # For locations based on a polygon:
      # filter the list by those that overlap at least 90% of the asset
      # defining our polygon
      if loc_type == 'area'
        logger.debug 'Filtering codes by area overlap'
        validcodes = []
        codes.each do |code|
          overlap = ActiveRecord::Base.connection.execute(" select ST_Area(ST_intersection(a.az_boundary, b.az_boundary)) as overlap, ST_Area(a.az_boundary) as area from assets a join assets b on b.code='#{code.code}' where a.id=#{asset.id}; ")
          prop_overlap = overlap.first['overlap'].to_f / overlap.first['area'].to_f
          logger.debug "DEBUG: overlap #{prop_overlap} " + code.code
          validcodes += [code] if prop_overlap > min_overlap
        end
        codes = validcodes
      end
    end
    codes.map(&:code)
  end

  # Look up all assets that are contained by a given asset (by code)
  # Input: code: string
  # Returns: codes: [code]
  def self.containing_codes_from_parent(code)
    code = code.upcase
    codes = AssetLink.find_by_sql ["select containing_code from asset_links al inner join assets a on al.containing_code = a.code where contained_code='#{code}' and is_active=true;"]
    codes.map(&:containing_code)
  end

  # Find the next free unused code for an asset type
  # (in a region, if asset tyoes uses regions)
  # Input: asset_type: AssetType.name, region: region.name
  # Returns: code: string
  def self.get_next_code(asset_type, region = 'ZZ')
    region ||= 'ZZ'
    logger.debug 'Region :' + region
    newcode = nil
    use_region = true
    length = 4
    case asset_type
    when 'hut'
      prefix = 'ZLH/'
      length = 3
    when 'volcano'
      prefix = 'ZLV/'
      length = 3
    when 'park'
      prefix = 'ZLP/'
      length = 4
    when 'island'
      prefix = 'ZLI/'
      length = 3
    when 'lake'
      prefix = 'ZLL/'
      length = 4
      use_region = false
    when 'lighthouse'
      prefix = 'ZLB/'
      length = 3
      use_region = false
    end

    if prefix
      # ZLx/XX-### or ZLx/XX-#### format codes
      if use_region && region && (region != '')
        # get last asset of this type for this region
        last_asset = Asset.where("code like '" + prefix + region + "-%%'").order(:code).last
        # try and determine number length from last asset code
        if last_asset
          logger.debug last_asset
          codestring = last_asset.code[7..-1]
        # or default to 0000
        else
          codestring = '0' * length
        end

        # add one to last asset code
        codenumber = codestring.to_i
        codenumber += 1
        newcode = prefix + region + '-' + codenumber.to_s.rjust(codestring.length, '0')

      # ZLx/#### format codes
      else
        # get last asset of this type
        last_asset = Asset.where(asset_type: asset_type).order(:code).last
        # try and determine number length from last asset code
        codestring = if last_asset
                       last_asset.code[4..-1]
                     # or default to 000
                     else
                       '0' * length
                     end
        # add one to last asset code
        codenumber = codestring.to_i
        codenumber += 1
        newcode = prefix + codenumber.to_s.rjust(codestring.length, '0')
      end
    end
    logger.debug 'Code: ' + newcode||""
    newcode
  end

  #################################################################
  # Imprting assets from externally sourced tables
  # Generally doen in 2 steps:
  # - read from external provider into a custom table which
  #   we can safely trash if things go wrong
  # - read from that table into the master assets table
  ################################################################

  # See lib/asset_import_tools.rb
  # def self.add_parks
  # def self.add_huts
  # def self.add_islands
  # def self.add_lakes
  # def self.add_lake(l)
  # def self.add_sota_peak(p)
  # def self.add_pota_parks
  # def self.add_pota_park(p, existing_asset)
  # def self.add_humps
  # def self.add_hump(p, existing_asset)
  # def self.add_lighthouses
  # def self.add_lighthouse(p, existing_asset)
  # def self.add_wwff_parks
  # def self.add_wwff_park(p, existing_asset)

  ###################################################################
  # GIS DATA HANDLING
  ###################################################################
  # see lib/asset_gis_tools for:
  # per-asset methods:
  #   def calc_location
  #   def add_sota_activation_zone
  #   def add_simple_boundary
  #   def add_area
  #   def add_altitude
  #   def add_buffered_activation_zone
  #   def get_access
  #   def get_access_with_buffer(buffer) REMOVED
  # Asset. methods:
  #   def self.add_areas
  #   def self.fix_invalid_polygons
  #   def self.add_simple_boundaries

  ############################################################
  # UTILS TO CALL FROM CONSOLE
  # See lib/asset_console_tools.rb
  #
  # def self.add_regions
  # def self.add_districts
  # def self.add_links
  # def self.prune_links
  # def self.update_all
  # def self.add_centroids
  # def self.add_sota_activation_zones(force=false)
  # def self.add_hema_activation_zones(force=false)
  # def self.get_hema_access
  # def self.get_sota_access
  # def self.get_lake_access

  def self.get_custom_connection(identifier, dbname, dbuser, password)
    eval("Custom_#{identifier} = Class::new(ActiveRecord::Base)")
    eval("Custom_#{identifier}.establish_connection(:adapter=>'postgis', :database=>'#{dbname}', " \
        ":username=>'#{dbuser}', :password=>'#{password}')")
    eval("Custom_#{identifier}.connection")
  end
end
