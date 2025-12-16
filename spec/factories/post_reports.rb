FactoryBot.define do
  factory :post_report do
    association :user
    association :post
    reason { 'inappropriate' }

    trait :harassment do
      reason { 'harassment' }
    end

    trait :spam do
      reason { 'spam' }
    end

    trait :misinformation do
      reason { 'misinformation' }
    end

    trait :other do
      reason { 'other' }
    end
  end
end
