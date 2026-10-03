# frozen_string_literal: true

# typed: false
class AdminTasksController < ApplicationController
  before_action :signed_in_user

  def index
    admin_task = params[:admin_task] || {}
    @action = admin_task[:task_type]
    @class = admin_task[:affected_table]
    @action = 'All' if @action.blank?
    @class = 'All' if @class.blank?
    @admin_tasks = AdminTask.find_by_sql [ " select * from admin_tasks where pending=true and (task_type=? or ?='All') and (affected_table=? or ?='All') ", @action, @action, @class, @class ]
    @actions = (AdminTask.find_by_sql [ 'select distinct task_type from admin_tasks' ])
    @classes = (AdminTask.find_by_sql [ 'select distinct affected_table from admin_tasks' ])
  end

  def delete
    at = AdminTask.find_by(id: params[:id])
    at.update_column(:pending, false)
    index()
    flash[:success] = "Marked as done"
    render 'index'
  end

  def show
  end

  def edit
  end

  def new
  end

  def create
  end

  def update
  end

  private

  def admin_tasks_params
    params.require(:admin_task).permit(:id, :task_type, :affected_id, :affected_table, :affected_url, :action_url, :description, :pendig)
  end
end
