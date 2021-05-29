class ParksController < ApplicationController

  def index
     redirect_to '/assets?type=park'
  end

  def show
     a=Asset.find_by(old_code: "ZLP/"+params[:id.to_s].rjust(7,'0'))
     if a then
       redirect_to '/assets/'+a.safecode
     else
       flash[:error]="Park "+params[:id].to_s+" not found"
       redirect_to '/assets?type=park'
     end
  end
end
