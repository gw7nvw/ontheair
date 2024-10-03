# frozen_string_literal: true

# typed: false
class LegalRoad < ActiveRecord::Base
  require 'csv'

  def self.import(filename)
    LegalRoad.destroy_all
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      wkt = place.first[1]
      puts place['id'], wkt.length
      if place && wkt
        ActiveRecord::Base.connection.execute("insert into legal_roads (id, boundary) values ('" + place['id'] + "',ST_Multi(ST_GeomFromText('" + wkt + "',4326)));")
      end
    end; true
  end
end
