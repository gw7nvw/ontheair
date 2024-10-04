# frozen_string_literal: true

# typed: false
class AwardsController < ApplicationController
  before_action :signed_in_user, only: %i[edit update new create]

  def index_prep
    @awards = Award.all.order(:name)
  end

  def index
    index_prep
  end

  def show
    unless (@award = Award.find_by_id(params[:id].to_i))
      flash[:error] = 'Award not found'
      redirect_to '/awards'
    end
  end

  def edit
    if signed_in? && current_user.is_admin
      unless (@award = Award.where(id: params[:id]).first)
        flash[:error] = 'Award not found'
        redirect_to '/awards'
      end
    else
      flash[:error] = 'You do not have permissions to edit an award'
      redirect_to '/awards'
    end
  end

  def new
    if signed_in? && current_user.is_admin
      @award = Award.new
    else
      flash[:error] = 'You do not have permissions to create a new award'
      redirect_to '/awards'
    end
  end

  def create
    if signed_in? && current_user.is_admin
      @award = Award.new(award_params)
      @award.createdBy_id = current_user.id

      if @award.save
        @award.reload
        flash[:success] = 'Success!'
        if params[:referring] == 'index'
          index_prep
          redirect_to '/awards'
        else
          redirect_to '/awards/' + @award.id.to_s
        end
      else
        render 'new'
      end
    else
      flash[:error] = 'You do not have permissions to create a new award'
      redirect_to '/awards'
    end
  end

  def update
    if signed_in? && current_user.is_admin
      if params[:delete]
        award = Award.find_by_id(params[:id])
        if award && award.destroy
          auls = AwardUserLink.where(award_id: award.id)
          auls.each(&:destroy)
          flash[:success] = 'Award deleted, id:' + params[:id]
          redirect_to '/awards'
        else
          edit
          render 'edit'
        end
      else
        unless (@award = Award.find_by_id(params[:id]))
          flash[:error] = 'Award does not exist: ' + @award.id.to_s

          # tried to update a nonexistant award
          redirect_to '/awards'
        end

        @award.assign_attributes(award_params)
        @award.createdBy_id = current_user.id

        if @award.save
          flash[:success] = 'Award details updated'

          # Handle a successful update.
          if params[:referring] == 'index'
            redirect_to '/awards'
          else
            redirect_to '/awards/' + @award.id.to_s
          end
        else
          render 'edit'
        end
      end
    else
      flash[:error] = 'You do not have permissions to edit an award'
      redirect_to '/awards'
    end
  end

  private

  def award_params
    params.require(:award).permit(:id, :name, :description, :email_text, :count_based, :all_district, :all_region, :all_programme, :p2p, :user_qrp, :contact_qrp, :is_active, :allow_repeat_visits, :activated, :chased, :programme)
  end
end
