# frozen_string_literal: true

# typed: false
class AdminTasksController < ApplicationController
  before_action :signed_in_user

  def index
    @admin_tasks = AdminTask.where(pending: true)
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
