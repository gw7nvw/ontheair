# frozen_string_literal: true

# typed: false
class Road < ActiveRecord::Base
  require 'csv'
  establish_connection :topo50_data
  self.table_name='linz_roads'
end
