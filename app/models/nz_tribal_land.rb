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

  # add simple boundaries for all tribal lands
  def self.add_simple_boundaries
    ActiveRecord::Base.connection.execute('update nz_tribal_lands set boundary_simplified=ST_Simplify("wkb_geometry",0.002) where boundary_simplified is null;')
    ActiveRecord::Base.connection.execute('update nz_tribal_lands set boundary_very_simplified=ST_Simplify("wkb_geometry",0.02) where boundary_very_simplified is null;')
    ActiveRecord::Base.connection.execute('update nz_tribal_lands set boundary_quite_simplified=ST_Simplify("wkb_geometry",0.002) where boundary_quite_simplified is null;')
  end

end
