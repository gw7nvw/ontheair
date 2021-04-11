class QueryparkController < ApplicationController

def index
  @searchtext=params[:searchtext]
  if @searchtext then
     puts ":"+@searchtext+":"
     @parks=Park.find_by_sql [ "select * from parks where is_Active=true and (lower(name) like '%%"+@searchtext.downcase+"%%' or CONCAT('zlp/',LPAD(id::text, 7, '0')) like '%%"+@searchtext.downcase+"%%') order by name limit 40"]
  else
     @parks=nil
  end

end

end
