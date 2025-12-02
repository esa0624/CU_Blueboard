FactoryBot.define do
  factory :answer_like do
    association :answer
    association :user
    vote_type { AnswerLike::UPVOTE }

    trait :upvote do
      vote_type { AnswerLike::UPVOTE }
    end

    trait :downvote do
      vote_type { AnswerLike::DOWNVOTE }
    end
  end
end
