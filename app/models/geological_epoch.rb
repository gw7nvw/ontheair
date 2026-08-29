# frozen_string_literal: true

# typed: false
class GeologicalEpoch < ActiveRecord::Base
  require 'csv'

  def eon
    GeologicalEon.find_by_sql [" select * from geological_eons where start_mya<=#{start_mya} and end_mya>=#{end_mya}; "]
  end

  def era
    GeologicalEra.find_by_sql [" select * from geological_eras where start_mya<=#{start_mya} and end_mya>=#{end_mya}; "]
  end

  def period
    GeologicalPeriod.find_by_sql [" select * from geological_periods where start_mya<=#{start_mya} and end_mya>=#{end_mya}; "]
  end

  def self.import(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      newplace = {}
      place.each do |key, value|
        key = key.gsub(/[^0-9a-z _]/i, '')
        newplace[key] = value
      end
      p = GeologicalEpoch.new(newplace)
      puts p.to_json
      p.save
      puts p.id
    end
  end

  def self.from_date(date_mya)
    unless date_mya.nil?
      s = GeologicalEpoch.find_by("start_mya>=#{date_mya} and end_mya<#{date_mya}")
    end
    s ? s.name : nil
  end
end
