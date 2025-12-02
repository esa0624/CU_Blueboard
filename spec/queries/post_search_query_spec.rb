require 'rails_helper'

RSpec.describe PostSearchQuery do
  let!(:topic_one) { Topic.find_or_create_by!(name: 'Academics') }
  let!(:topic_two) { Topic.find_or_create_by!(name: 'Housing') }
  let!(:tag_one) { Tag.find_or_create_by!(slug: 'academics') { |t| t.name = 'Academics' } }
  let!(:tag_two) { Tag.find_or_create_by!(slug: 'housing') { |t| t.name = 'Housing' } }

  let!(:post_one) do
    create(:post, title: 'Academics help', topic: topic_one).tap { |post| post.update!(tag_ids: [ tag_one.id ]) }
  end
  let!(:post_two) do
    create(:post, title: 'Housing question', topic: topic_two).tap { |post| post.update!(tag_ids: [ tag_two.id ]) }
  end

  it 'returns all active posts without filters' do
    results = described_class.new.call
    expect(results).to include(post_one, post_two)
  end

  it 'filters by topic' do
    results = described_class.new({ topic_id: topic_one.id }).call
    expect(results).to include(post_one)
    expect(results).not_to include(post_two)
  end

  it 'filters by tags' do
    results = described_class.new({ tag_ids: [ tag_two.id ] }).call
    expect(results).to include(post_two)
    expect(results).not_to include(post_one)
  end

  it 'filters by timeframe' do
    post_two.update!(created_at: 40.days.ago)
    results = described_class.new({ timeframe: '30d' }).call
    expect(results).to include(post_one)
    expect(results).not_to include(post_two)
  end

  it 'filters by status' do
    post_one.update!(status: Post::STATUSES[:solved])
    results = described_class.new({ status: Post::STATUSES[:solved] }).call

    expect(results).to contain_exactly(post_one)
  end

  it 'filters by school' do
    post_two.update!(school: 'Barnard')
    results = described_class.new({ school: 'Barnard' }).call

    expect(results).to contain_exactly(post_two)
  end

  it 'filters by course code (case insensitive)' do
    post_two.update!(course_code: 'COMS W4995')
    results = described_class.new({ course_code: 'coms w4995' }).call

    expect(results).to contain_exactly(post_two)
  end

  describe 'AI-flagged filtering' do
    let!(:normal_post) { create(:post, ai_flagged: false) }
    let!(:flagged_post) { create(:post, ai_flagged: true) }

    it 'returns all posts for moderators including AI-flagged' do
      moderator = create(:user, :moderator)

      results = described_class.new({}, current_user: moderator).call

      expect(results).to include(normal_post, flagged_post)
    end
  end
end
