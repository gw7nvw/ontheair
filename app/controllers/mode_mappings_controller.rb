# frozen_string_literal: true

# typed: false

class ModeMappingsController < ApplicationController
  before_action :admin_user

  def index
    @mode = ModeMapping.new
    @modes = ModeMapping.all.order(:raw_mode)
  end

  def edit
    @mode = ModeMapping.find(params[:id])
    @modes = ModeMapping.all.order(:raw_mode)
    render 'index'
  end

  def create
    mode = ModeMapping.create(mode_params)
    @modes = ModeMapping.all.order(:raw_mode)
    @mode = ModeMapping.new
    render 'index'
  end

  def delete
    mode = ModeMapping.find(params[:id])
    mode.destroy
    @modes = ModeMapping.all.order(:raw_mode)
    @mode = ModeMapping.new
    render 'index'
  end

  def update
    mode = ModeMapping.find(params[:id])
    mode.assign_attributes(mode_params)
    mode.save
    @modes = ModeMapping.all.order(:raw_mode)
    @mode = ModeMapping.new
    render 'index'
  end

  private

  def mode_params
    params.require(:mode_mapping).permit(:id, :raw_mode, :parent_group)
  end
end
