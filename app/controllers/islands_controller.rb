class IslandsController < ApplicationController
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
        whereclause=whereclause+" and status like '%%Official%%'"
    else 
        @searchMR=false 
    end
    if params[:searchtext] then
       whereclause=whereclause+" and (lower(name) like '%%"+@searchtext.downcase+"%%' or CONCAT('zli/',id) like '%%"+@searchtext.downcase+"%%')"

    end

    @islands=Island.find_by_sql [ 'select * from islands where '+whereclause+' order by name limit 100' ]
    counts=Island.find_by_sql [ 'select count(id) as id from islands where '+whereclause ]
    if counts and counts.first then @count=counts.first.id else @count=0 end
    @users=User.where("islands_bagged is not null and islands_bagged>0").order(:islands_bagged).reverse


  end


  def index
    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data huts_to_csv(@islands), filename: "parks-#{Date.today}.csv" }
    end
  end

  def show
    if(!(@island = Island.find_by_id(params[:id].to_i)))
      redirect_to '/'
    end
  end

  def edit
    if params[:referring] then @referring=params[:referring] end

    if(!(@island = Island.where(id: params[:id]).first))
      redirect_to '/'
    end
      #@park.boundary=@park.all_boundary
      convert_location_params()
  end
  def new
    @island = Island.new
  end

 def create
    if signed_in? and current_user.is_modifier then

    @island = Island.new(island_params)

    convert_location_params()
    @island.createdBy_id=current_user.id

      if @island.save
          @island.reload
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
      island = Island.find_by_id(params[:id])
      if island and island.destroy
        flash[:success] = "Island deleted, id:"+params[:id]
        index_prep()
        render 'index'
      else
        edit()
        render 'edit'
      end
    else
      if(!@island = Island.find_by_id(params[:id]))
          flash[:error] = "Island does not exist: "+@island.id.to_s

          #tried to update a nonexistant hut
          render 'edit'
      end

      @island.assign_attributes(island_params)
      convert_location_params()
      @island.createdBy_id=current_user.id

      if @island.save
        flash[:success] = "Island details updated"

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
            islands = Island.all.order(:name)

            render :json => {
                 :total_count => parks.length,
                 :pos => 0,
                 :rows => parks.map do |park|
                 {
                   :id => island.id,
                   :data => [island.id, island.name,  island.info_description, island.general_link]
                 }
                 end
            }
  end
def db_action
  if signed_in? and current_user.is_modifier then
    @mode = params["!nativeeditor_status"]
    id = params['c0']
    name = params['c1']
    info_description = params['c2']
    is_mr = params['c3']
    is_active = params['c4']
    doc_link = params['c5']
    tramper_link = params['c6']
    general_link = params['c7']

    @id = params["gr_id"]

    case @mode
    when "inserted"
        park = Park.create :name => name,:info_description => info_description, :is_mr => is_mr, :is_active => is_active, :doc_link => doc_link, :tramper_link => tramper_link, :general_link => general_link
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

  def islands_to_csv(items)
    if signed_in? and current_user.is_admin then
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

  private
  def island_params
    params.require(:island).permit(:id, :name, :info_description, :info_note, :feat_note, :WKT, :crd_east, :crd_north, :general_link, :status)
  end

  def convert_location_params
    if(@island.boundary.as_text[0..8]=='POLYGON((') then
      @island.boundary="MULTIPOLYGON((("+@island.boundary.as_text[9..-1]+")"
    end
    if(@island.boundary.as_text[0..9]=='POLYGON ((') then
      @island.boundary="MULTIPOLYGON((("+@island.boundary.as_text[10..-1]+")"
    end

  end


end

