# typed: false
class CommentsController < ApplicationController

before_action :signed_in_user, only: [:delete, :create, :update, :new, :edit]
skip_before_filter :verify_authenticity_token, :only => [:create, :update]

def index
    @fullcomments=Comment.all
    @comments=@fullcomments.paginate(:per_page => 40, :page => params[:page])

end

def show
    tzid=3
    if current_user then tzid=current_user.timezone end
    @tz=Timezone.find(tzid)

    @parameters=params_to_query

    @comment=Comment.find_by_id(params[:id])
    if !@comment then 
      flash[:error]="Sorry - the comment that you tried to view no longer exists"
      redirect_to '/'
    end
end


def new
    @parameters=params_to_query

    @comment=Comment.new
    @tz=Timezone.find_by_id(current_user.timezone||3)
    t=Time.now.in_time_zone(@tz.name)
    d=Time.now.in_time_zone(@tz.name).strftime('%Y-%m-%d 00:00 UTC').to_time
    if params[:asset] then @comment.code=params[:asset].gsub('_','/') end
end

def edit
    @tz=Timezone.find_by_id(current_user.timezone||3)
    if params[:referring] then @referring=params[:referring] end

    if(!(@comment = Comment.where(id: params[:id]).first))
      redirect_to '/'
    end
end

def delete
 if signed_in?  then
    @comment=Comment.find_by_id(params[:id])
    code=@comment.code
    if @comment and (current_user.is_admin or (current_user.id==@comment.updated_by_id)) then
      if @comment.destroy
        flash[:success] = "Comment deleted, id:"+params[:id]
        if code then 
          redirect_to '/assets/'+code.gsub("/","_")
        else
          redirect_to '/comments'
        end
      else
        flash[:error] = "Failed to delete comment"
        edit()
        render 'edit'
      end
    else 
      flash[:error] = "Failed to delete comment"
      redirect_to '/'
    end
  else 
    flash[:error] = "Failed to delete comment"
    redirect_to '/'
  end
end

def update
 @tz=Timezone.find_by_id(current_user.timezone||3)
 if signed_in?  then
    @comment=Comment.find_by_id(params[:id])
    if @comment and (current_user.is_admin or (current_user.id==@comment.updated_by_id)) then
      if params[:commit]=="Delete Comment" then
         code=@comment.code
         if @comment.destroy
           flash[:success] = "Comment deleted, id:"+params[:id]
           redirect_to '/assets/'+code.gsub('/','_')
         else
           flash[:error] = "Failed to delete comment"
           edit()
           render 'edit'
         end
       else

         @comment.assign_attributes(comment_params)
         @comment.updated_by_id=current_user.id
         if @comment.save then

           flash[:success] = "Post updated"

           # Handle a successful update.
             if @comment.code then
               redirect_to '/assets/'+@comment.code.gsub('/','_') 
             else
               render 'show'
             end
         else
           render 'edit'
         end
       end #delete or edit
     else
       redirect_to '/'
     end # do we have permissions
    else
      redirect_to '/'
    end #signed in

end

def create
    @tz=Timezone.find_by_id(current_user.timezone||3)
    if params[:debug] then debug=true else debug=false end
    if signed_in? then
      @comment=Comment.new(comment_params)
      @comment.updated_by_id = current_user.id #current_user.id

      if @comment.save then
        flash[:success] = "Posted!"
        @edit=true

        if @comment.code then
          redirect_to '/assets/'+@comment.code.gsub('/','_')
        else
          render 'show'
        end
      else
        errors="Error creating comment"
        flash[:error] = errors
        @edit=true
        render 'new'
      end
    else
      redirect_to '/'
    end

end

  private
  def comment_params
    params.require(:comment).permit(:comment, :code)
  end

end
