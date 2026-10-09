class VkLake < ActiveRecord::Base
# frozen_string_literal: true

# typed: true
  require 'csv'

  establish_connection :vk_gis
  self.table_name = 'vk_lakes'
end
