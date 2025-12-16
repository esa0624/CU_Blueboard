# Moderation statistics dashboard controller
module Moderation
  class DashboardController < ApplicationController
    before_action :require_moderator!

    def index
      @daily_posts = Post.where('created_at >= ?', 30.days.ago)
                         .group("date(created_at)")
                         .count

      @topic_distribution = Topic.joins(:posts)
                                 .group('topics.name')
                                 .count

      @stats = {
        total_posts: Post.count,
        total_answers: Answer.count,
        total_users: User.count,
        response_rate: calculate_response_rate,
        resolution_rate: calculate_resolution_rate,
        redacted_posts: Post.where.not(redaction_state: 'visible').count,
        ai_flagged_posts: Post.where(ai_flagged: true).count,
        reported_posts: Post.where(reported: true).count
      }
    end

    private

    def calculate_response_rate
      with_answers = Post.joins(:answers).distinct.count
      total = Post.count
      total > 0 ? (with_answers.to_f / total * 100).round(1) : 0
    end

    def calculate_resolution_rate
      solved = Post.where(status: 'solved').count
      total = Post.count
      total > 0 ? (solved.to_f / total * 100).round(1) : 0
    end
  end
end
