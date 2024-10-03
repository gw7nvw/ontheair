# typed: false
class MapsController < ApplicationController

def layerswitcher
  @maplayers=Maplayer.all
end

def print
  @papersize=Papersize.all
end

def legend
  @projections=Projection.all.order(:name)
  if params[:projection] then @projection=params[:projection] else @projection="2193" end

end


end
