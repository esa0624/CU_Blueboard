class PostReport < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :reports_count

  REASONS = %w[inappropriate harassment spam misinformation other].freeze

  validates :user_id, uniqueness: { scope: :post_id, message: 'has already reported this post' }
  validates :reason, presence: true, inclusion: { in: REASONS }
  validate :cannot_report_own_post

  private

  def cannot_report_own_post
    errors.add(:base, 'You cannot report your own post') if user_id == post&.user_id
  end
end
