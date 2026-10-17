# frozen_string_literal: true

# typed: false

class AssetProtectedAreaLink < ActiveRecord::Base
  def self.seed_from_assets
    AssetProtectedAreaLink.destroy_all

    assets = Asset.where(asset_type: 'park').order(:name)
    assets.each do |asset|
      napalis_id=asset.old_code.gsub('ZLP/','')
      napalis_id = napalis_id.to_i if napalis_id
      if napalis_id>0
        asset.update_column(:name_id, napalis_id.to_s)
        asset.update_column(:name_source, 'napalis')
        begin 
          AssetProtectedAreaLink.create(asset_code: asset.code, napalis_id: napalis_id)
        rescue
          dup = AssetProtectedAreaLink.find_by(napalis_id: napalis_id)
          dup_asset = Asset.find_by(code: dup.asset_code)
          puts "ERROR: #{asset.code} - #{asset.name} (#{if asset.is_active then "💡 ACTIVE" else "RETIRED" end}) duplicate id to #{dup_asset.code} - #{dup_asset.name} (#{if dup_asset.is_active then "💡 ACTIVE" else "RETIRED" end}) #{napalis_id}"

        end
      end
    end
    true
  end
end
