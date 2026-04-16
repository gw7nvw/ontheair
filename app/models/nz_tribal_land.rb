# frozen_string_literal: true

# typed: strict
class NzTribalLand < ActiveRecord::Base
  self.table_name = 'nz_tribal_lands'
  require 'csv'
  def self.import_vk(filename)
    count = 0
    CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = NzTribalLand.new
      np.name = place['group']
      np.wkb_geometry = place['WKT']
      np.id = place['id']
      np.country = 'VK'
      np.save
    end

  end
end
