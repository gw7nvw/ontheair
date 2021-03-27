class QueryislandController < ApplicationController
def index
  @searchtext=params[:searchtext]
  if @searchtext then
     puts ":"+@searchtext+":"
     @islands=Island.find_by_sql [ "select * from islands where lower(name) like lower('%%"+@searchtext+"%%') order by name limit 40"]
  else
     @islands=nil
  end

end


end
