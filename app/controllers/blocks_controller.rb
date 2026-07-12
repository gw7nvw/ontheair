class BlocksController < ApplicationController

  before_action :signed_in_user

def index
  where_clause = 'true'
  where_clause += ' and confirmed_human = true' if params[:human]
  where_clause += ' and confirmed_bot = true' if params[:robot]
  where_clause += ' and suspected_bot = true' if params[:suspect]
  where_clause += ' and suspected_bot = true' if params[:suspect]
  order_clause = 'access_count desc' 
  order_clause = 'suspicious_access_count desc' if params[:suspicious]
  @blocks = UserAgent.where(where_clause).order(order_clause)
  count  = ActiveRecord::Base.connection.execute(" select count(id) as count from user_agents; ")
  humans  = ActiveRecord::Base.connection.execute(" select count(id) as count from user_agents where confirmed_human = true; ")
  robots  = ActiveRecord::Base.connection.execute(" select count(id) as count from user_agents where confirmed_bot = true; ")
  @humans = humans.first["count"] if humans and humans.count>0
  @robots = robots.first["count"] if robots and robots.count>0
  @count = count.first["count"] if count and count.count>0
end

def delete
  if current_user and current_user.is_admin
    a=UserAgent.find_by(id: params[:id])
    if a then 
      logger.debug "BLOCKS: Deleting row #{params[:id]}"
      a.destroy
    else
      flash[:error] = "Agent #{params[:id]} not found"
    end
  end
  index
  render 'index'
end

def robot
  if current_user and current_user.is_admin
    a=UserAgent.find_by(id: params[:id])
    if a then 
      logger.debug "BLOCKS: Blocking row #{params[:id]}"
      a.update_column(:confirmed_human, false)
      a.update_column(:confirmed_bot, true)
    else
      flash[:error] = "Agent #{params[:id]} not found"
    end
  end
  index
  render 'index'

end

def human
  if current_user and current_user.is_admin
    a=UserAgent.find_by(id: params[:id])
    if a then 
      logger.debug "BLOCKS: Allowing row #{params[:id]}"
      a.update_column(:confirmed_human, true)
      a.update_column(:confirmed_bot, false)
    else
      flash[:error] = "Agent #{params[:id]} not found"
    end
  end
  index
  render 'index'

end

def reset
  if current_user and current_user.is_admin
    ActiveRecord::Base.connection.execute("delete from user_agents;")
    flash[:success] = "Block list reset"
  end
  index
  render 'index'
end

end
