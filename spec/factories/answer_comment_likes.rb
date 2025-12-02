FactoryBot.define do
  factory :answer_comment_like do
    association :answer_comment
    association :user
    vote_type { AnswerCommentLike::UPVOTE }

    trait :upvote do
      vote_type { AnswerCommentLike::UPVOTE }
    end

    trait :downvote do
      vote_type { AnswerCommentLike::DOWNVOTE }
    end
  end
end
