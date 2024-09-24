class Volcano < ActiveRecord::Base
require 'csv'

def eon_data
  GeologicalEon.find_by(name: self.eon)
end

def era_data
  GeologicalEra.find_by(name: self.era)
end

def period_data
  GeologicalPeriod.find_by(name: self.period)
end

def epoch_data
  GeologicalEpoch.find_by(name: self.epoch.downcase.capitalize)
end
def get_date_range
  range=""
  if self.age then
    range=age_format(self.age)
  elsif self.min_age and self.max_age then
    range=age_format(self.min_age)+" to "+age_format(self.max_age)
  end
  range  
end


def self.import(filename)
  h=[]
  CSV.foreach(filename, :headers => true) do |row|
    place=row.to_hash
      newplace={}; place.each do |key,value| key = key.gsub(/[^0-9a-z _]/i, ''); newplace[key]=value  end
      p=Volcano.find_by(code: newplace["code"])
      if !p then
        p=Volcano.new
      end
      p.code=newplace["code"]
      p.name=newplace["name"]
      p.field_name=newplace["field_name"]
      p.age=newplace["age"]
      p.height=newplace["height"]
      p.lat=newplace["lat"]
      p.long=newplace["long"]
      p.az_radius=newplace["az_radius"]
      p.url=newplace["url"]
      p.location="POINT(#{p.long} #{p.lat})"
      p.eon=newplace["eon"]
      p.era=newplace["era"]
      p.period=newplace["period"]
      p.epoch=newplace["epoch"]
      p.min_age=nil
      p.max_age=nil
      if p.age==0 then p.age=nil end
      if p.age then p.min_age=p.age end
      if p.age then p.max_age=p.age end
      if !p.min_age and !p.max_age then
        if p.epoch then
          p.min_age=p.epoch_data.end_mya
          p.max_age=p.epoch_data.start_mya
        elsif p.period then
          p.min_age=p.period.end_mya
          p.max_age=p.period.start_mya
        elsif p.era then
          p.min_age=p.era.end_mya
          p.max_age=p.era.start_mya
        elsif p.eon then
          p.min_age=p.eon.end_mya
          p.max_age=p.eon.start_mya
        end
      end
      p.date_range=p.get_date_range

      if !p.eon then p.eon=GeologicalEon.from_date(p.max_age) end
      if !p.era then p.era=GeologicalEra.from_date(p.max_age) end
      if !p.period then p.period=GeologicalPeriod.from_date(p.max_age) end
      if !p.epoch then p.epoch=GeologicalEpoch.from_date(p.max_age) end
      p.save
      puts p.to_json
    end
  end
end

private

def age_format(age)
 agestr=""
 if age<0.001 then agestr=(age*1000000).to_s+" years ago"
 elsif age<1 then agestr=(age*1000).to_s+"k years ago"
 else agestr=age.to_s+"M years ago"
 end
 agestr
end

