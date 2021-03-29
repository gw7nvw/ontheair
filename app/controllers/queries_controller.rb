class QueriesController < ApplicationController
skip_before_action :verify_authenticity_token

def hut
 query=params[:query]
 huts=Hut.find_by_sql [ "select id,name from huts where name ilike '%%"+query+"%%' order by name" ]
 render :json => huts.map{|h| h.codename} 
end
def park
 query=params[:query]
 parks=Park.find_by_sql [ "select id,name from parks where name ilike '%%"+query+"%%' order by name" ]
 render :json => parks.map{|h| h.codename}
end
def island
 query=params[:query]
 islands=Island.find_by_sql [ "select id,name from islands where name ilike '%%"+query+"%%' order by name" ]
 render :json => islands.map{|h| h.codename}
end
def summit
 query=params[:query]
 summits=SotaPeak.find_by_sql [ "select name, summit_code from sota_peaks where name ilike '%%"+query+"%%' order by name" ]
 render :json => summits.map{|h| h.codename}
end
def test
 puts request.raw_post
end
end
