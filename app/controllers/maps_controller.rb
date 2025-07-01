# frozen_string_literal: true

# typed: false
class MapsController < ApplicationController
  def layerswitcher
    @maplayers = Maplayer.all

    if current_user then
      current_user.pointlayers=params[:pointlayers].gsub('[','').gsub(']','').split(',').map{|aa| '"'+aa+'"'}.join(',') if params[:pointlayers]
      current_user.polygonlayers=params[:polygonlayers].gsub('[','').gsub(']','').split(',').map{|aa| '"'+aa+'"'}.join(',') if params[:polygonlayers]
      current_user.save
    end
    #TODO store current settings against current user
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
