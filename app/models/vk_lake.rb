class VkLake < ActiveRecord::Base
# frozen_string_literal: true

# typed: true
  require 'csv'

  establish_connection :lakes
  self.table_name = 'vk_lakes'
end
