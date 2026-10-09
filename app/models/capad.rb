# frozen_string_literal: true
# typed: strict
class Capad < ActiveRecord::Base
  establish_connection :vk_gis
  self.table_name = "capad"
end
