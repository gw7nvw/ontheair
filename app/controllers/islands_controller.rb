# frozen_string_literal: true

# typed: false
class IslandsController < ApplicationController
  def index
    redirect_to '/assets?type=island'
  end

  def show
    a = Asset.find_by(code: 'ZLI/' + params[:id.to_s].rjust(5, '0'))
    if a
      redirect_to '/assets/' + a.safecode
    else
      flash[:error] = 'Island ' + params[:id].to_s + ' not found'
      redirect_to '/assets?type=island'
    end
  end
end
