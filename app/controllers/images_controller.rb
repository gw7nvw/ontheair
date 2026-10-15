# frozen_string_literal: true

# typed: false

class ImagesController < ApplicationController
  before_action :signed_in_user
end
