class ParksController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :editgrid]

  def editgrid

  end

  def index_prep
    whereclause="true"
    if params[:filter] then
      @filter=params[:filter]
      whereclause="is_"+@filter+" is true"
    end

    @searchtext=params[:searchtext]
   
    puts "searchMR"
    puts params[:search_mr]
    puts "end" 
    if params[:search_mr]=="true" then 
        @searchMR=true 
    else 
        @searchMR=false 
        whereclause=whereclause+" and is_mr=false"
    end
    if params[:searchtext] then
       whereclause=whereclause+" and (lower(name) like '%%"+@searchtext.downcase+"%%' or CONCAT('zlp/',LPAD(id::text, 7, '0')) like '%%"+@searchtext.downcase+"%%')"

    end

    @parks=Park.find_by_sql [ 'select * from parks where '+whereclause+' order by name limit 100' ]
    counts=Park.find_by_sql [ 'select count(id) as id from parks where '+whereclause ]
    if counts and counts.first then @count=counts.first.id else @count=0 end

    @users=User.where("parks_bagged is not null and parks_bagged>0").order(:parks_bagged).reverse

  end


  def index
    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data parks_to_csv(Park.all), filename: "parks-#{Date.today}.csv" }
    end
  end

  def show
    if(!(@park = Park.find_by_id(params[:id].to_i)))
      redirect_to '/'
    end
  end

  def edit
    if params[:referring] then @referring=params[:referring] end

    if(!(@park = Park.where(id: params[:id]).first))
      redirect_to '/'
    end
      #@park.boundary=@park.all_boundary
      convert_location_params()
  end
  def new
    @park = Park.new
  end

 def create
    if signed_in? and current_user.is_modifier then

    @park = Park.new(park_params)

    convert_location_params()
    @park.createdBy_id=current_user.id

      if @park.save
          @park.reload
          if params[:referring]=='index' then
            index_prep()
            render 'index'
          else
            render 'show'
          end

      else
          render 'new'
      end
    else
      redirect_to '/'
    end
 end

 def update
  if signed_in? and current_user.is_modifier then
    if params[:delete] then
      park = Park.find_by_id(params[:id])
      if park and park.destroy
        flash[:success] = "Park deleted, id:"+params[:id]
        index_prep()
        render 'index'
      else
        edit()
        render 'edit'
      end
    else
      if(!@park = Park.find_by_id(params[:id]))
          flash[:error] = "Park does not exist: "+@park.id.to_s

          #tried to update a nonexistant hut
          render 'edit'
      end

      @park.assign_attributes(park_params)
      convert_location_params()
      @park.createdBy_id=current_user.id

      if @park.save
        flash[:success] = "Park details updated"

        # Handle a successful update.
        if params[:referring]=='index' then
          index_prep()
          render 'index'
        else
          render 'show'
        end
      else
        render 'edit'
      end
    end
  else
    redirect_to '/'
  end
end
#editgrid handlers

  def data
            parks = Park.all.order(:name)

            render :json => {
                 :total_count => parks.length,
                 :pos => 0,
                 :rows => parks.map do |park|
                 {
                   :id => park.id,
                   :data => [park.id, park.name,  park.description, park.is_mr, park.is_active, park.doc_link, park.tramper_link, park.general_link]
                 }
                 end
            }
  end
def db_action
  if signed_in? and current_user.is_modifier then
    @mode = params["!nativeeditor_status"]
    id = params['c0']
    name = params['c1']
    description = params['c2']
    is_mr = params['c3']
    is_active = params['c4']
    doc_link = params['c5']
    tramper_link = params['c6']
    general_link = params['c7']

    @id = params["gr_id"]

    case @mode
    when "inserted"
        park = Park.create :name => name,:description => description, :is_mr => is_mr, :is_active => is_active, :doc_link => doc_link, :tramper_link => tramper_link, :general_link => general_link
       if park then
          @tid = park.id
       else
          @mode="error"
          @tid=nil
       end

    when "deleted"
        if Park.find(@id).destroy then
          @tid = @id
        else
          @mode-"error"
          @tid=nil
       end

    when "updated"
        @park = Park.find(@id)
        @park.name = name
        @park.description = description
        @park.is_mr = is_mr
        @park.is_active = is_active
        @park.tramper_link = tramper_link
        @park.doc_link = doc_link
        @park.general_link = general_link

        if !@park.save then @mode="error" end

        @tid = @id
    end

  end
end

  def parks_to_csv(items)
      require 'csv'
      csvtext=""
      if items and items.first then
        columns=["code"]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then columns << name end end
        csvtext << columns.to_csv
        items.each do |item|
           fields=[item.code]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then fields << value end end
           csvtext << fields.to_csv
        end
     end
     csvtext
  end

  private
  def park_params
    params.require(:park).permit(:id, :name, :description, :boundary, :tramper_link, :doc_link, :general_link, :is_active, :is_mr)
  end

  def convert_location_params
    if @park.boundary then 
      if(@park.boundary.as_text[0..8]=='POLYGON((') then
        @park.boundary="MULTIPOLYGON((("+@park.boundary.as_text[9..-1]+")"
      end
      if(@park.boundary.as_text[0..9]=='POLYGON ((') then
        @park.boundary="MULTIPOLYGON((("+@park.boundary.as_text[10..-1]+")"
      end
    end
  end


end

