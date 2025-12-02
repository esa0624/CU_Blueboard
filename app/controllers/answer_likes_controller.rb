class AnswerLikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_answer

  # POST /posts/:post_id/answers/:answer_id/upvote
  def upvote
    existing_vote = @answer.find_vote_by(current_user)

    if existing_vote
      if existing_vote.upvote?
        # Toggle: remove upvote
        existing_vote.destroy
      else
        # Switch from downvote to upvote
        existing_vote.update!(vote_type: AnswerLike::UPVOTE)
      end
    else
      # Create new upvote
      @answer.answer_likes.create!(user: current_user, vote_type: AnswerLike::UPVOTE)
    end

    redirect_to post_path(@answer.post, anchor: "answer-#{@answer.id}")
  end

  # POST /posts/:post_id/answers/:answer_id/downvote
  def downvote
    existing_vote = @answer.find_vote_by(current_user)

    if existing_vote
      if existing_vote.downvote?
        # Toggle: remove downvote
        existing_vote.destroy
      else
        # Switch from upvote to downvote
        existing_vote.update!(vote_type: AnswerLike::DOWNVOTE)
      end
    else
      # Create new downvote
      @answer.answer_likes.create!(user: current_user, vote_type: AnswerLike::DOWNVOTE)
    end

    redirect_to post_path(@answer.post, anchor: "answer-#{@answer.id}")
  end

  private

  def set_answer
    @answer = Answer.find(params[:id])
  end
end
