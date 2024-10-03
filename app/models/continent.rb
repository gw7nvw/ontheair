# frozen_string_literal: true

# typed: true
class Continent < ActiveRecord::Base
  def self.name_from_code(code)
    c = Continent.find_by(code: code)
    c ? c.name : ''
  end
end
