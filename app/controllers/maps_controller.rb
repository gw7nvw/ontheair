# frozen_string_literal: true

# typed: false
class MapsController < ApplicationController
  def layerswitcher
    @maplayers = Maplayer.all
  end

  # No current support for printing - though code is all there
  # def print
  #   @papersize = Papersize.all
  # end

  def legend
    @projections = Projection.all.order(:name)
    @projection = params[:projection] || '2193'
  end
end
