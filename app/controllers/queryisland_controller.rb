class QueryislandController < ApplicationController
def index
  @searchtext=params[:searchtext]
  if @searchtext then
     puts ":"+@searchtext+":"
     @islands=Island.find_by_sql [ "select * from islands where is_active=true and (lower(name) like '%%"+@searchtext.downcase+"%%' or CONCAT('zli/',LPAD(id::text, 5, '0')) like '%%"+@searchtext.downcase+"%%') order by name limit 40"]
  else
     @islands=nil
  end

end


end
