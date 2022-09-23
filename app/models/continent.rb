class Continent < ActiveRecord::Base

def self.name_from_code(code)
  c=Continent.find_by(code: code)
  if c then c.name else "" end
end
end
