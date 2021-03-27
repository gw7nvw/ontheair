class QueryparkController < ApplicationController

def index
  @searchtext=params[:searchtext]
  if @searchtext then
     puts ":"+@searchtext+":"
     @parks=Park.find_by_sql [ "select * from parks where lower(name) like lower('%%"+@searchtext+"%%') order by name limit 40"]
  else
     @parks=nil
  end

end

end
