require 'rails_helper'

RSpec.describe PostSearchQuery do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let!(:post_1) { create(:post, title: 'First Post', body: 'Body one', created_at: 2.days.ago, school: 'Columbia', course_code: 'COMS W4152') }
  let!(:post_2) { create(:post, title: 'Second Post', body: 'Body two', created_at: 5.days.ago, school: 'Barnard', course_code: 'MATH 1001') }
  let!(:ai_flagged_post) { create(:post, ai_flagged: true, user: user) }
  let!(:other_ai_flagged_post) { create(:post, ai_flagged: true) }

  describe '#call' do
    context 'filtering by AI flagged status' do
      it 'shows all posts to moderators' do
        query = described_class.new({}, current_user: moderator)
        expect(query.call).to include(post_1, post_2, ai_flagged_post, other_ai_flagged_post)
      end

      it 'shows non-flagged and own flagged posts to users' do
        query = described_class.new({}, current_user: user)
        results = query.call
        expect(results).to include(post_1, post_2, ai_flagged_post)
        expect(results).not_to include(other_ai_flagged_post)
      end

      it 'shows only non-flagged posts to guests' do
        query = described_class.new({}, current_user: nil)
        results = query.call
        expect(results).to include(post_1, post_2)
        expect(results).not_to include(ai_flagged_post, other_ai_flagged_post)
      end
    end

    context 'filtering by text' do
      it 'filters by title' do
        query = described_class.new({ q: 'First' })
        expect(query.call).to include(post_1)
        expect(query.call).not_to include(post_2)
      end

      it 'filters by body' do
        query = described_class.new({ q: 'two' })
        expect(query.call).to include(post_2)
        expect(query.call).not_to include(post_1)
      end

      it 'returns all if query is blank' do
        query = described_class.new({ q: '' })
        expect(query.call).to include(post_1, post_2)
      end
    end

    context 'filtering by topic' do
      let(:topic) { create(:topic) }
      before { post_1.update(topic: topic) }

      it 'filters by topic_id' do
        query = described_class.new({ topic_id: topic.id })
        expect(query.call).to include(post_1)
        expect(query.call).not_to include(post_2)
      end
    end

    context 'filtering by tags' do
      let(:tag_1) { create(:tag) }
      let(:tag_2) { create(:tag) }

      before do
        post_1.tags << tag_1
        post_1.tags << tag_2
        post_2.tags << tag_1
      end

      it 'filters by single tag' do
        query = described_class.new({ tag_ids: [ tag_1.id ] })
        expect(query.call).to include(post_1, post_2)
      end

      it 'filters by multiple tags (Match ALL - default)' do
        query = described_class.new({ tag_ids: [ tag_1.id, tag_2.id ] })
        expect(query.call).to include(post_1)
        expect(query.call).not_to include(post_2)
      end

      it 'filters by multiple tags (Match ANY)' do
        query = described_class.new({ tag_ids: [ tag_1.id, tag_2.id ], tag_match: 'any' })
        expect(query.call).to include(post_1, post_2)
      end

      it 'returns all if tag_ids is empty' do
        query = described_class.new({ tag_ids: [] })
        expect(query.call).to include(post_1, post_2)
      end
    end

    context 'filtering by status' do
      before { post_1.update(status: 'solved') }

      it 'filters by status' do
        query = described_class.new({ status: 'solved' })
        expect(query.call).to include(post_1)
        expect(query.call).not_to include(post_2)
      end
    end

    context 'filtering by school' do
      before { post_1.update(school: 'Columbia') }

      it 'filters by school' do
        query = described_class.new({ school: 'Columbia' })
        expect(query.call).to include(post_1)
        expect(query.call).not_to include(post_2)
      end
    end

    context 'filtering by course code' do
      before { post_1.update(course_code: 'COMS W4152') }

      it 'filters by course code (case insensitive)' do
        query = described_class.new({ course_code: 'coms' })
        expect(query.call).to include(post_1)
        expect(query.call).not_to include(post_2)
      end
    end

    context 'filtering by timeframe' do
      it 'filters by 24h' do
        recent_post = create(:post, created_at: 1.hour.ago)
        query = described_class.new({ timeframe: '24h' })
        expect(query.call).to include(recent_post)
        expect(query.call).not_to include(post_1, post_2)
      end

      it 'filters by 7d' do
        query = described_class.new({ timeframe: '7d' })
        expect(query.call).to include(post_1, post_2)
      end

      it 'ignores invalid timeframe' do
        query = described_class.new({ timeframe: 'invalid' })
        expect(query.call).to include(post_1, post_2)
      end
    end

    context 'filtering by author' do
      it 'filters by author_id' do
        query = described_class.new({ author_id: ai_flagged_post.user_id }, current_user: user)
        expect(query.call).to include(ai_flagged_post)
        expect(query.call).not_to include(post_1)
      end
    end

    context 'filtering by post_ids' do
      it 'filters by specific ids' do
        query = described_class.new({ post_ids: [ post_1.id ] })
        expect(query.call).to include(post_1)
        expect(query.call).not_to include(post_2)
      end
    end
  end
end
