require 'rails_helper'

RSpec.describe PostReport, type: :model do
  describe 'associations' do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }

    it 'belongs to a user' do
      report = create(:post_report, user: user, post: post_record)
      expect(report.user).to eq(user)
    end

    it 'belongs to a post' do
      report = create(:post_report, user: user, post: post_record)
      expect(report.post).to eq(post_record)
    end
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }

    it 'is valid with valid attributes' do
      report = build(:post_report, user: user, post: post_record)
      expect(report).to be_valid
    end

    it 'requires a reason' do
      report = build(:post_report, user: user, post: post_record, reason: nil)
      expect(report).not_to be_valid
      expect(report.errors[:reason]).to include("can't be blank")
    end

    it 'requires reason to be one of REASONS' do
      report = build(:post_report, user: user, post: post_record, reason: 'invalid_reason')
      expect(report).not_to be_valid
      expect(report.errors[:reason]).to include('is not included in the list')
    end

    it 'allows all valid reasons' do
      PostReport::REASONS.each do |reason|
        report = build(:post_report, user: user, post: post_record, reason: reason)
        expect(report).to be_valid
      end
    end

    it 'prevents duplicate reports from the same user' do
      create(:post_report, user: user, post: post_record)
      duplicate = build(:post_report, user: user, post: post_record)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already reported this post')
    end

    it 'allows different users to report the same post' do
      other_user = create(:user)
      create(:post_report, user: user, post: post_record)
      report = build(:post_report, user: other_user, post: post_record)
      expect(report).to be_valid
    end

    it 'prevents users from reporting their own posts' do
      own_post = create(:post, user: user)
      report = build(:post_report, user: user, post: own_post)
      expect(report).not_to be_valid
      expect(report.errors[:base]).to include('You cannot report your own post')
    end
  end

  describe 'counter_cache' do
    let(:post_record) { create(:post) }

    it 'increments reports_count when a report is created' do
      expect {
        create(:post_report, post: post_record)
      }.to change { post_record.reload.reports_count }.by(1)
    end

    it 'decrements reports_count when a report is destroyed' do
      report = create(:post_report, post: post_record)
      expect {
        report.destroy
      }.to change { post_record.reload.reports_count }.by(-1)
    end

    it 'counts multiple reports correctly' do
      3.times { create(:post_report, post: post_record) }
      expect(post_record.reload.reports_count).to eq(3)
    end
  end

  describe 'REASONS constant' do
    it 'includes expected reasons' do
      expect(PostReport::REASONS).to include('inappropriate')
      expect(PostReport::REASONS).to include('harassment')
      expect(PostReport::REASONS).to include('spam')
      expect(PostReport::REASONS).to include('misinformation')
      expect(PostReport::REASONS).to include('other')
    end
  end
end
