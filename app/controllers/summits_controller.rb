class SummitsController < ApplicationController

  def index_prep
    whereclause="true"
    if params[:filter] then
      @filter=params[:filter]
      whereclause="is_"+@filter+" is true"
    end

    @searchtext=params[:searchtext]
    if params[:searchtext] then
       whereclause=whereclause+" and (lower(name) like '%%"+@searchtext.downcase+"%%' or lower(summit_code) like '%%"+@searchtext.downcase+"%%')"
    end

    @summits=SotaPeak.find_by_sql [ 'select * from sota_peaks where '+whereclause+' order by name limit 100' ]
    @all_summits=SotaPeak.find_by_sql [ 'select * from sota_peaks where '+whereclause+' order by name' ]
    counts=SotaPeak.find_by_sql [ 'select count(id) as id from sota_peaks where '+whereclause ]
    if counts and counts.first then @count=counts.first.id else @count=0 end

    url = "https://api-db.sota.org.uk/admin/activator_roll?associationID=119"
    @summits_zl1 = JSON.parse(open(url).read)
    url = "https://api-db.sota.org.uk/admin/activator_roll?associationID=123"
    @summits_zl3 = JSON.parse(open(url).read)

  end

 def index
    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data huts_to_csv(@all_summits), filename: "summits-#{Date.today}.csv" }
    end
  end

  def show
    if(!(@summit = SotaPeak.find_by(short_code: params[:id])))
      redirect_to '/'
    end
  end

  def huts_to_csv(items)
    if signed_in? then
      require 'csv'
      csvtext=""
      if items and items.first then
        columns=[]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then columns << name end end
        csvtext << columns.to_csv
        items.each do |item|
           fields=[]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then fields << value end end
           csvtext << fields.to_csv
        end
     end
     csvtext
   end
  end

end
