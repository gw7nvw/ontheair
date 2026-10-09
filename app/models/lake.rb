# frozen_string_literal: true

# typed: true
class Lake < ActiveRecord::Base
  require 'csv'

  establish_connection :zl_gis

end
