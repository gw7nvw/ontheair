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
        puts 'PRUNE: ' + al.id.to_s
        al.destroy
      end
    end
  end

  def self.add_pota_links
    pps = PotaPark.all
    pps.each do |pp|
      p = Park.find_by_id(pp.park_id)
      a = p ? Asset.find_by(code: p.dist_code) : nil
      ap = Asset.find_by(code: pp.reference)
      next unless a && ap
      al = AssetLink.new
      al.contained_code = a.code
      al.containing_code = pp.reference
      dup = AssetLink.where(contained_code: a.code, containing_code: pp.reference)
      if !dup || dup.count.zero?
        al.save
        puts "Link #{p.name} with #{a.name}"
      else
        puts "Already Linked #{p.name} with #{a.name}"
      end
      al = AssetLink.new
      al.containing_code = a.code
      al.contained_code = pp.reference
      dup = AssetLink.where(containing_code: a.code, contained_code: pp.reference)
      al.save if !dup || dup.count.zero?
    end
  end

  def self.add_wwff_links
    pps = WwffPark.all
    pps.each do |pp|
      p = Park.find_by_id(pp.napalis_id)
      a = p ? Asset.find_by(code: p.dist_code) : nil
      ap = Asset.find_by(code: pp.code)
      next unless a && ap
      al = AssetLink.new
      al.contained_code = a.code
      al.containing_code = pp.code
      dup = AssetLink.where(contained_code: a.code, containing_code: pp.code)
      if !dup || dup.count.zero?
        al.save
        puts "Link #{p.name} with #{a.name}"
      else
        puts "Already Linked #{p.name} with #{a.name}"
      end
      al = AssetLink.new
      al.containing_code = a.code
      al.contained_code = pp.code
      dup = AssetLink.where(containing_code: a.code, contained_code: pp.code)
      al.save if !dup || dup.count.zero?
    end
  end
end
