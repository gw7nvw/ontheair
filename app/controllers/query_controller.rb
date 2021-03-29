class QueryController < ApplicationController

def index
  @searchtext=params[:searchtext]
  if @searchtext then
     puts ":"+@searchtext+":"
     @huts=Hut.find_by_sql [ "select * from huts where (lower(name) like '%%"+@searchtext.downcase+"%%' or CONCAT('zlh/',LPAD(id::text, 4, '0')) like '%%"+@searchtext.downcase+"%%') order by name limit 40"]
  else
     @huts=nil
  end

end

end
