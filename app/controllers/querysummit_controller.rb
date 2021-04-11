class QuerysummitController < ApplicationController

def index
  @searchtext=params[:searchtext]
  if @searchtext then
     puts ":"+@searchtext+":"
     @summits=SotaPeak.find_by_sql [ "select * from sota_peaks where (lower(name) like '%%"+@searchtext.downcase+"%%' or lower(summit_code) like '%%"+@searchtext.downcase+"%%')" ]
  else
     @summits=nil
  end

end

end
