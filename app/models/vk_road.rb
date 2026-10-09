# frozen_string_literal: true

# typed: false
class VkRoad < ActiveRecord::Base
  require 'csv'
  establish_connection :vk_gis
  self.table_name='au_roads'
end
