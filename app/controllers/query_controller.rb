class QueryController < ApplicationController

def index
  @searchtext=params[:searchtext]
  if @searchtext then
     puts ":"+@searchtext+":"
     @huts=Hut.find_by_sql [ "select * from huts where lower(name) like lower('%%"+@searchtext+"%%') order by name limit 40"]
  else
     @huts=nil
  end

end

end
