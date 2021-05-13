class QueriesController < ApplicationController
skip_before_action :verify_authenticity_token

def asset
 query=params[:query]
 asset_type=params[:asset_type]
 if asset_type and asset_type.length>0 and asset_type!='all' then
   assets=Asset.find_by_sql [ "select code,name from assets where is_active=true and name ilike '%%"+query+"%%' and asset_type='"+asset_type+"' order by name" ]

 else
   assets=Asset.find_by_sql [ "select code,name from assets where is_active=true and name ilike '%%"+query+"%%' order by name" ]
 end
 render :json => assets.map{|h| h.codename} 
end
def hut
 query=params[:query]
 huts=Hut.find_by_sql [ "select id,name from huts where is_active=true and name ilike '%%"+query+"%%' order by name" ]
 render :json => huts.map{|h| h.codename} 
end
def park
 query=params[:query]
 parks=Park.find_by_sql [ "select id,name from parks where is_active=true and name ilike '%%"+query+"%%' order by name" ]
 render :json => parks.map{|h| h.codename}
end
def island
 query=params[:query]
 islands=Island.find_by_sql [ "select id,name from islands where is_active=true and name ilike '%%"+query+"%%' order by name" ]
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
