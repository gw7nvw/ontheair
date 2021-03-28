class QueriesController < ApplicationController

def hut
 query=params[:query]
 huts=Hut.find_by_sql [ "select id,name from huts where name ilike '%%"+query+"%%' order by name" ]
 render :json => huts.map{|h| h.name+" - ZLH/"+h.id.to_s} 
end
def park
 query=params[:query]
 parks=Park.find_by_sql [ "select id,name from parks where name ilike '%%"+query+"%%' order by name" ]
 render :json => parks.map{|h| h.name+" - ZLP/"+h.id.to_s} 
end
def island
 query=params[:query]
 islands=Island.find_by_sql [ "select id,name from islands where name ilike '%%"+query+"%%' order by name" ]
 render :json => islands.map{|h| h.name+" - ZLI/"+h.id.to_s} 
end
def summit
 query=params[:query]
 summits=SotaPeak.find_by_sql [ "select name, summit_code from sota_peaks where name ilike '%%"+query+"%%' order by name" ]
 render :json => summits.map{|h| h.name+" - "+h.summit_code} 
end

end
