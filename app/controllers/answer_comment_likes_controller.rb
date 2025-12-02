class AnswerCommentLikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment

  # POST /posts/:post_id/answers/:answer_id/comments/:comment_id/upvote
  def upvote
    existing_vote = @comment.find_vote_by(current_user)

    if existing_vote
      if existing_vote.upvote?
        # Toggle: remove upvote
        existing_vote.destroy
      else
        # Switch from downvote to upvote
        existing_vote.update!(vote_type: AnswerCommentLike::UPVOTE)
      end
    else
      # Create new upvote
      @comment.answer_comment_likes.create!(user: current_user, vote_type: AnswerCommentLike::UPVOTE)
    end

    redirect_to post_path(@comment.post, anchor: "comment-#{@comment.id}"), status: :see_other
  end

  # POST /posts/:post_id/answers/:answer_id/comments/:comment_id/downvote
  def downvote
    existing_vote = @comment.find_vote_by(current_user)

    if existing_vote
      if existing_vote.downvote?
        # Toggle: remove downvote
        existing_vote.destroy
      else
        # Switch from upvote to downvote
        existing_vote.update!(vote_type: AnswerCommentLike::DOWNVOTE)
      end
    else
      # Create new downvote
      @comment.answer_comment_likes.create!(user: current_user, vote_type: AnswerCommentLike::DOWNVOTE)
    end

    redirect_to post_path(@comment.post, anchor: "comment-#{@comment.id}"), status: :see_other
  end

  private

  def set_comment
    @comment = AnswerComment.find(params[:id])
  end
end
