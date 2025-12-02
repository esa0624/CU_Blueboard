class AnswerComment < ApplicationRecord
  belongs_to :answer
  belongs_to :user

  has_many :answer_comment_likes, dependent: :destroy

  delegate :post, to: :answer

  validates :body, presence: true

  after_create :ensure_thread_identity

  # Voting helper methods
  def upvotes_count
    answer_comment_likes.upvotes.count
  end

  def downvotes_count
    answer_comment_likes.downvotes.count
  end

  def net_score
    upvotes_count - downvotes_count
  end

  def find_vote_by(user)
    return nil unless user
    answer_comment_likes.find_by(user_id: user.id)
  end

  private

  def ensure_thread_identity
    ThreadIdentity.find_or_create_by!(user: user, post: post)
  end
end
