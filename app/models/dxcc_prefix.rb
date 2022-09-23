class DxccPrefix < ActiveRecord::Base

def continent
  Continent.find_by(code: self.continent_code)
end

def self.from_call(callsign)
  p=DxccPrefix.find_by_sql [ "select * from dxcc_prefixes where '#{callsign}' like CONCAT(prefix,'%%') order by length(prefix) desc limit 1;" ]
  if p then p.first else nil end
end

def self.name_from_call(callsign)
  p=self.from_call(callsign)
  if p then
    name=p.name+" ("+p.continent.name+")"
  else 
    name="Unrecognised callsign prefix"
  end
  name
end

def self.continent_from_call(callsign)
  p=self.from_call(callsign)
  if p then
    name=p.continent_code
  else
    name=""
  end
  name
end

end
