# frozen_string_literal: true
# typed: strict
class Capad < ActiveRecord::Base
  establish_connection :capad
  self.table_name = "capad"
end
