class Answer < ApplicationRecord
  belongs_to :post
  belongs_to :user

  has_many :audit_logs, as: :auditable, dependent: :destroy
  has_many :answer_comments, dependent: :destroy
  has_many :answer_revisions, dependent: :destroy
  has_many :answer_likes, dependent: :destroy
  belongs_to :redacted_by, class_name: 'User', optional: true

  validates :body, presence: true
  validate :post_must_be_open, on: :create
  validate :redacted_body_presence

  after_create :ensure_thread_identity
  before_destroy :clear_post_acceptance

  REDACTION_STATES = {
    visible: 'visible',
    partial: 'partial',
    redacted: 'redacted'
  }.freeze
  enum :redaction_state, REDACTION_STATES, default: :visible

  def record_revision!(editor:, previous_body:)
    return if previous_body == body

    answer_revisions.create!(user: editor, body: previous_body)
  end

  # Voting helper methods
  def upvotes_count
    answer_likes.upvotes.count
  end

  def downvotes_count
    answer_likes.downvotes.count
  end

  def net_score
    upvotes_count - downvotes_count
  end

  def find_vote_by(user)
    return nil unless user
    answer_likes.find_by(user_id: user.id)
  end

  private

  def ensure_thread_identity
    ThreadIdentity.find_or_create_by!(user: user, post: post)
  end

  def clear_post_acceptance
    return unless post.accepted_answer_id == id

    post.update_columns(accepted_answer_id: nil, locked_at: nil, status: Post::STATUSES[:open])
  end

  def post_must_be_open
    return unless post&.locked?

    errors.add(:base, 'This thread is locked. No new answers can be added.')
  end

  def redacted_body_presence
    return if redaction_state == REDACTION_STATES[:visible]

    if redacted_body.blank?
      errors.add(:redacted_body, 'must be provided when content is redacted')
    end
  end
end
