# frozen_string_literal: true

# typed: false

class CommentsController < ApplicationController
  before_action :signed_in_user, only: %i[destroy create update new edit]
  skip_before_action :verify_authenticity_token, only: %i[create update]

  def index
    @fullcomments = Comment.all
    @comments = @fullcomments.paginate(per_page: 40, page: params[:page])
  end

  def show
    @comment = Comment.find_by_id(params[:id])
    unless @comment
      flash[:error] = "Sorry - the comment that you tried to view no longer exists"
      redirect_to "/"
    end
  end

  def new
    @comment = Comment.new
    @comment.code = params[:asset].tr("_", "/") if params[:asset]
  end

  def edit
    @referring = params[:referring] if params[:referring]

    redirect_to "/" unless (@comment = Comment.where(id: params[:id]).first)
  end

  def destroy
    if signed_in?
      @comment = Comment.find_by_id(params[:id])
      code = @comment.code if @comment
      if @comment && (current_user.is_admin || (current_user.id == @comment.updated_by_id))
        if @comment.destroy
          flash[:success] = "Comment deleted, id:" + params[:id]
          if code
            redirect_to "/assets/" + code.tr("/", "_"), status: :see_other
            nil
          else
            redirect_to "/comments", status: :see_other
            nil
          end
        else
          flash[:error] = "Failed to delete comment"
          edit
          render "edit"
        end
      else
        flash[:error] = "You do not have permissions to delete this comment"
        redirect_to "/", status: :see_other
        nil
      end
    else
      flash[:error] = "Failed to delete comment"
      redirect_to "/", status: :see_other
      nil
    end
  end

  def update
    if signed_in?
      @comment = Comment.find_by_id(params[:id])
      if @comment && (current_user.is_admin || (current_user.id == @comment.updated_by_id))
          @comment.assign_attributes(comment_params)
          @comment.updated_by_id = current_user.id
          if @comment.save

            flash[:success] = "Post updated"

            # Handle a successful update.
            if @comment.code
              redirect_to "/assets/" + @comment.code.tr("/", "_"), status: :see_other
              nil
            else
              render "show"
              nil
            end
          else
            render "edit"
            nil
          end
      else
        flash[:error] = "You do not have permissions to update this comment"
        redirect_to "/assets/" + @comment.code.tr("/", "_")
        nil
      end # do we have permissions
    else
      redirect_to "/", status: :see_other
      nil
    end # signed in
  end

  def create
    if signed_in?
      @comment = Comment.new(comment_params)
      @comment.updated_by_id = current_user.id # current_user.id

      if @comment.save
        flash[:success] = "Posted!"
        @edit = true

        if @comment.code
          redirect_to "/assets/" + @comment.code.tr("/", "_"), status: :see_other
          nil
        else
          render "show"
        end
      else
        errors = "Error creating comment"
        flash[:error] = errors
        @edit = true
        render "new"
      end
    else
      redirect_to "/", status: :see_other
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:comment, :code)
  end
end
