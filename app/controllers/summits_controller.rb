# frozen_string_literal: true

# typed: false
class SummitsController < ApplicationController
  def index
    redirect_to '/assets?type=summit'
  end

  def show
    a = Asset.find_by(code: 'ZL3/' + params[:id.to_s])
    a ||= Asset.find_by(code: 'ZL1/' + params[:id.to_s])
    if a
      redirect_to '/assets/' + a.safecode
    else
      flash[:error] = 'Summit ' + params[:id].to_s + ' not found'
      redirect_to '/assets?type=summit'
    end
  end
end
