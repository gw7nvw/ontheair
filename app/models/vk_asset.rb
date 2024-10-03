# frozen_string_literal: true

# typed: false
class VkAsset < ActiveRecord::Base
  # fake ZL asset fields
  def url
    '/vkassets/' + get_safecode
  end

  def minor
    false
  end

  def maidenhead
    ''
  end

  def is_active
    true
  end

  def type
    nil
  end

  def self.import
    destroy_all
    url = 'http://parksnpeaks.org/api/SITES'
    data = JSON.parse(open(url).read)
    if data
      data.each do |site|
        next unless site && site['ID'] && (site['ID'][0..1] == 'VK') && (site['ID'].length > 4)
        p = VkAsset.new
        p.award = site['Award']
        p.wwff_code = site['Location']
        p.shire_code = site['ShireID']
        p.code = site['ID']
        p.wwff_code = p.code if p.code[0..3] == 'VKFF'
        p.name = site['Name']
        p.site_type = site['Type']
        p.latitude = site['Latitude']
        p.longitude = site['Longitude']
        p.location = 'POINT(' + p.longitude.to_s + ' ' + p.latitude.to_s + ')'
        puts 'Adding: ' + p.code + ' [' + p.name + ']'
        if p.wwff_code
          detailurl = 'http://parksnpeaks.org/api/PARK/WWFF/' + p.wwff_code
          ddraw = open(detailurl).read
          detaildata = ddraw && (ddraw.length > 2) ? JSON.parse(ddraw) : nil
          if detaildata
            p.pota_code = detaildata[0]['POTAID']
            p.state = detaildata[0]['State']
            p.region = detaildata[0]['Region']
            p.district = detaildata[0]['District']
          end
        end
        p.save
      end
    end
  end

  def self.add_pota_parks
    assets = VkAsset.find_by_sql [" select * from vk_assets where award='WWFF' and pota_code is not null "]
    assets.each do |asset|
      va = asset.dup
      va.code = va.pota_code
      va.award = 'POTA'
      va.save
    end
  end

  def get_safecode
    code.tr('/', '_')
  end

  def external_url
    url = if award == 'HEMA'
            'https://parksnpeaks.org/showAward.php?award=HEMA'
          elsif award == 'SiOTA'
            'https://www.silosontheair.com/silos/#' + code.to_s
          elsif award == 'POTA'
            'https://pota.app/#/park/' + code.to_s
          elsif award == 'SOTA'
            'https://summits.sota.org.uk/summit/' + code.to_s
          elsif award == 'WWFF'
            'https://parksnpeaks.org/getPark.php?actPark=' + code.to_s + '&submit=Process'
          else
            '/assets'
          end
    url
  end

  def codename
    '[' + code + '] ' + name
  end

  def wwff_asset
    asset = nil
    if award != 'WWFF'
      asset = VkAsset.find_by(code: wwff_code) if wwff_code && !wwff_code.empty?
    end
    asset
  end

  def pota_asset
    asset = nil
    if award != 'POTA'
      if pota_code && !pota_code.empty?
        asset = VkAsset.find_by(code: pota_code)
        if asset
          asset.award = 'POTA'
          asset.code = pota_code
        end
      end
    end
    asset
  end

  def contained_by_assets
    assets = []
    assets.push(pota_asset) if pota_asset
    assets.push(wwff_asset) if wwff_asset
    assets
  end

  def contains_assets
    assets = []

    if award == 'WWFF'
      assets = VkAsset.where(wwff_code: code)
    elsif award == 'POTA'
      assets = VkAsset.where(pota_code: code)
    end
    assets
  end

  def self.containing_codes_from_parent(code)
    codes = []
    code = code.upcase
    a = VkAsset.find_by(code: code.split(' ')[0])

    codes = a.contained_by_assets.map(&:code) if a
    codes
  end
end
