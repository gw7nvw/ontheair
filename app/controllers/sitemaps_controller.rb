# typed: false
class SitemapsController < ApplicationController
  #caches_page :index
  def index
    @static_paths = [about_path]
    @stats_paths = [root_path, spots_path, alerts_path, results_path, recent_path]
    @assets = Asset.where('is_active=true and minor is not true')
    @users = User.where(activated: true)

    respond_to do |format|
      format.xml do
      end
    end
  end
end

