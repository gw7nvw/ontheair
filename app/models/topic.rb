class Topic < ActiveRecord::Base

    establish_connection "qrp"
def url
  url=[self.id, self.name.parameterize].join('-')
end

end


