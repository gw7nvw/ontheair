# typed: false
class HutsController < ApplicationController

  def index
     redirect_to '/assets?type=hut'
  end

  def show
     a=Asset.find_by(code: "ZLH/"+params[:id.to_s].rjust(4,'0'))
     if a then 
       redirect_to '/assets/'+a.safecode  
     else 
       flash[:error]="Hut "+params[:id].to_s+" not found" 
       redirect_to '/assets?type=hut' 
     end
  end

end

