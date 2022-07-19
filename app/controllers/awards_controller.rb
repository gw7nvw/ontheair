class AwardsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update, :editgrid]

  def editgrid

  end

  def index_prep
    @awards=Award.all.order(:name)
  end


  def index
    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data awards_to_csv(@awards), filename: "awards-#{Date.today}.csv" }

    end
  end

  def show
    if(!(@award = Award.find_by_id(params[:id].to_i)))
      redirect_to '/'
    end
  end

  def edit
    if params[:referring] then @referring=params[:referring] end

    if(!(@award = Award.where(id: params[:id]).first))
      redirect_to '/'
    end
  end

  def new
    @award = Award.new
  end

 def create
    if signed_in? and current_user.is_admin then

    @award = Award.new(award_params)

    @award.createdBy_id=current_user.id

      if @award.save
          @award.reload
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
  if signed_in? and current_user.is_admin then
    if params[:delete] then
      award = Award.find_by_id(params[:id])
      if award and award.destroy
        auls=AwardUserLink.where(:award_id => award.id)
        auls.each do |aul| aul.destroy; end
        flash[:success] = "Award deleted, id:"+params[:id]
        index_prep()
        render 'index'
      else
        edit()
        render 'edit'
      end
    else
      if(!@award = Award.find_by_id(params[:id]))
          flash[:error] = "Award does not exist: "+@award.id.to_s

          #tried to update a nonexistant hut
          render 'edit'
      end

      @award.assign_attributes(award_params)
      @award.createdBy_id=current_user.id

      if @award.save
        flash[:success] = "Award details updated"

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


  def awards_to_csv(items)
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
  def award_params
    params.require(:award).permit(:id, :name, :description, :email_text, :count_based, :all_district, :all_region, :all_programme, :p2p,  :user_qrp, :contact_qrp, :is_active, :allow_repeat_visits, :activated, :chased, :programme)
  end



end

