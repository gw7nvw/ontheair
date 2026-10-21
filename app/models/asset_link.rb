# frozen_string_literal: true

# typed: false

class AssetLink < ActiveRecord::Base
  def self.find_by_parent(code)
    als1 = AssetLink.where(contained_code: code)
    als2 = AssetLink.where(containing_code: code)
    als2.each(&:reverse)
    als1 + als2
  end

  def reverse
    temp = containing_code
    self.containing_code = contained_code
    self.contained_code = temp
  end

  def parent
    Asset.find_by(code: contained_code)
  end

  def child
    Asset.find_by(code: containing_code)
  end

  def self.prune
    AssetLink.all.each do |al|
      c = al.child
      p = al.parent
      if !c || !p || (c.is_active == false) || (p.is_active == false)
        puts "PRUNE: " + al.id.to_s
        al.destroy
      end
    end
  end

  def self.find_equivalent(code)
    als = AssetLink.find_by_sql [ "select al1.* from asset_links al1 inner join asset_links al2 on al2.containing_code = al1.contained_code and al2.contained_code = al1.containing_code where al1.contained_code = ?", code]
    als.pluck(:containing_code)
  end

end
