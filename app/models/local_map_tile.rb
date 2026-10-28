# frozen_string_literal: true
# typed: strict

class LocalMapTile < ActiveRecord::Base
  establish_connection :zl_gis
end
