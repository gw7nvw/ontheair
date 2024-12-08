class VolcanicField < ActiveRecord::Base
  require 'csv'

  def site_count
    sites=Volcano.find_by_sql [ "select count(id) as id from volcanos where field_code = '#{code}';" ]
    if sites and sites.count>0 then sites.first.id else nil end
  end

  def self.import(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      ActiveRecord::Base.connection.execute("insert into volcanic_fields (code, name, boundary, min_age, max_age, url) values ('" + place['GROUP_CODE'] + "','" + place['VOLC_NAME'].gsub("'", "''") + "',ST_GeomFromText('" + place['WKT'] + "',4326), "+place['ABSMIN_MA']+", "+place['ABSMAX_MA']+", 'geology/" + place['GROUP_CODE'] + "');")
    end; true
  end

  def self.add_simple_boundaries
    ActiveRecord::Base.connection.execute('update volcanic_fields set boundary_simplified=ST_Simplify("boundary",0.002) where boundary_simplified is null;')
    ActiveRecord::Base.connection.execute('update volcanic_fields set boundary_very_simplified=ST_Simplify("boundary",0.02) where boundary_very_simplified is null;')
    ActiveRecord::Base.connection.execute('update volcanic_fields set boundary_quite_simplified=ST_Simplify("boundary",0.0002) where boundary_quite_simplified is null;')
  end

  # simplified boundary with downscaling big assets (and detail/accuracy for small assets)
  def boundary_simple
    pp = VolcanicField.find_by_sql ['select id, ST_NPoints(boundary) as numpoints from volcanic_fields where id=' + id.to_s]
    if pp
      lenfactor = Math.sqrt((pp.first['numpoints'] || 0) / 10_000)
      rnd = 0.000002 * 10**lenfactor
      boundarys = VolcanicField.find_by_sql ['select id, ST_AsText(ST_Simplify("boundary", ' + rnd.to_s + ')) as "boundary" from volcanic_fields where id=' + id.to_s]
      boundary = boundarys.first.boundary
      boundary
    end
  end

end
