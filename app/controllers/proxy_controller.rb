# frozen_string_literal: true

# typed: false
class ProxyController < ApplicationController
  def get
    if params[:url][0..22] = 'https://hutbagger.co.nz'
      url = URI.parse(params['url'])
      result = Net::HTTP.get_response(url)
      send_data result.body, type: result.content_type, disposition: 'inline'
    end
  end
end
