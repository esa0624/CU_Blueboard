class AnswerLike < ApplicationRecord
  belongs_to :answer
  belongs_to :user

  # Vote types: 1 = upvote, -1 = downvote
  UPVOTE = 1
  DOWNVOTE = -1

  validates :user_id, uniqueness: { scope: :answer_id }
  validates :vote_type, inclusion: { in: [ UPVOTE, DOWNVOTE ] }

  scope :upvotes, -> { where(vote_type: UPVOTE) }
  scope :downvotes, -> { where(vote_type: DOWNVOTE) }

  def upvote?
    vote_type == UPVOTE
  end

  def downvote?
    vote_type == DOWNVOTE
  end
end
