# frozen_string_literal: true

# typed: false
class Volcano < ActiveRecord::Base
  require 'csv'

  def eon_data
    GeologicalEon.find_by(name: eon)
  end

  def era_data
    GeologicalEra.find_by(name: era)
  end

  def period_data
    GeologicalPeriod.find_by(name: period)
  end

  def epoch_data
    GeologicalEpoch.find_by(name: epoch.downcase.capitalize)
  end

  def get_date_range
    range = ''
    if age
      range = age_format(age)
    elsif min_age && max_age
      range = age_format(min_age) + ' to ' + age_format(max_age)
    end
    range
  end

  def self.import(filename)
    CSV.foreach(filename, headers: true) do |row|
      puts row.to_json
      place = row.to_hash
      newplace = {}
      place.each do |key, value|
        key = key.gsub(/[^0-9a-z _]/i, '')
        newplace[key] = value
      end
      p = Volcano.find_by(code: newplace['code'])
      p ||= Volcano.new
      p.code = newplace['code']
      p.name = newplace['name']
      p.field_name = newplace['field_name']
      p.field_code = newplace['field_code']
      p.age = newplace['age']
      p.height = newplace['height']
      p.lat = newplace['lat']
      p.long = newplace['long']
      p.az_radius = newplace['az_radius']
      p.url = newplace['url']
      p.location = "POINT(#{p.long} #{p.lat})"
      p.eon = newplace['eon']
      p.era = newplace['era']
      p.period = newplace['period']
      p.epoch = newplace['epoch']
      p.min_age = nil
      p.max_age = nil
      p.age = nil if p.age.nil? or p.age.zero?
      p.min_age = p.age if p.age
      p.max_age = p.age if p.age
      if !p.min_age && !p.max_age
        if p.epoch
          p.min_age = p.epoch_data.end_mya
          p.max_age = p.epoch_data.start_mya
        elsif p.period
          p.min_age = p.period.end_mya
          p.max_age = p.period.start_mya
        elsif p.era
          p.min_age = p.era.end_mya
          p.max_age = p.era.start_mya
        elsif p.eon
          p.min_age = p.eon.end_mya
          p.max_age = p.eon.start_mya
        end
      end
      p.date_range = p.get_date_range

      p.eon = GeologicalEon.from_date(p.max_age) unless p.eon
      p.era = GeologicalEra.from_date(p.max_age) unless p.era
      p.period = GeologicalPeriod.from_date(p.max_age) unless p.period
      p.epoch = GeologicalEpoch.from_date(p.max_age) unless p.epoch
      p.save
      puts p.to_json
    end
  end
end

private

def age_format(age)
  agestr = if age < 0.001 then (age * 1_000_000).to_s + ' years ago'
           elsif age < 1 then (age * 1000).to_s + 'k years ago'
           else age.to_s + 'M years ago'
           end
  agestr
end
