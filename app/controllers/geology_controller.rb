class GeologyController < ApplicationController
  include ApplicationHelper

  def index_prep
    whereclause = 'true'

    @searchtext = safe_param(params[:searchtext] || '')
    if params[:searchtext] && (params[:searchtext] != '')
      whereclause = "lower(code) like '%%" + @searchtext.downcase + "%%' or lower(name) like '%%" + @searchtext.downcase + "%%'"
    end

    @fullgeologies = VolcanicField.find_by_sql ['select * from volcanic_fields where ' + whereclause + ' order by code']
    @geologies = @fullgeologies.paginate(per_page: 40, page: params[:page])
  end

  def index
    index_prep
    respond_to do |format|
      format.html
      format.js
    end
  end


  def show
    id = params[:id]
    @geology = VolcanicField.find_by(code: id) if id
    unless @geology 
      flash[:error]="Cannot find geological region "+id.to_s
      redirect_to '/'
    end
  end
end
