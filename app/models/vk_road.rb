# frozen_string_literal: true

# typed: false
class VkRoad < ActiveRecord::Base
  require 'csv'
  establish_connection :capad
  self.table_name='au_roads'
end
