# frozen_string_literal: true

# typed: true
class WebLinkClass < ActiveRecord::Base
  def self.seed
    WebLinkClass.create(name: 'hutbagger', display_name: 'Hutbagger', url: 'https://hutbagger.co.nz/')
    WebLinkClass.create(name: 'tramper', display_name: 'NZ Tramper', url: 'https://tramper.nz/')
    WebLinkClass.create(name: 'doc', display_name: 'DOC', url: 'https://doc.govt.nz/')
    WebLinkClass.create(name: 'routeguides', display_name: 'NZ Route Guides', url: 'https://routeguides.co.nz/')
    WebLinkClass.create(name: 'other', display_name: 'Other', url: '')
  end
end
