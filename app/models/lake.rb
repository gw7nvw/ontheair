# frozen_string_literal: true

# typed: true
class Lake < ActiveRecord::Base
  require 'csv'

  establish_connection :topo50_data

end
