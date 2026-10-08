# frozen_string_literal: true

# typed: false
class DocTrack < ActiveRecord::Base
  establish_connection :topo50_data

end
