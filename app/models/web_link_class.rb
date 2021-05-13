class WebLinkClass < ActiveRecord::Base
def self.seed
    a=WebLinkClass.create(name: 'hutbagger', display_name: 'Hutbagger', url: 'https://hutbagger.co.nz/')
    a=WebLinkClass.create(name: 'tramper', display_name: 'NZ Tramper', url: 'https://tramper.nz/')
    a=WebLinkClass.create(name: 'doc', display_name: 'DOC', url: 'https://doc.govt.nz/')
    a=WebLinkClass.create(name: 'routeguides', display_name: 'NZ Route Guides', url: 'https://routeguides.co.nz/')
    a=WebLinkClass.create(name: 'other', display_name: 'Other', url: '')
end
end
