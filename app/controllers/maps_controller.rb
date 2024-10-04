# frozen_string_literal: true

# typed: false
class MapsController < ApplicationController
  def layerswitcher
    @maplayers = Maplayer.all
  end

  def print
    @papersize = Papersize.all
  end

  def legend
    @projections = Projection.all.order(:name)
    @projection = params[:projection] || '2193'
    end
end
