require 'rails_helper'

RSpec.describe RedactionService do
  let(:moderator) { create(:user, :moderator) }
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user, body: 'Original post body') }
  let(:answer) { create(:answer, post: post_record, user: user, body: 'Original answer body') }

  describe '.redact_post' do
    it 'redacts a post' do
      expect(described_class.redact_post(post: post_record, moderator: moderator, reason: 'spam')).to be true
      post_record.reload
      expect(post_record.redaction_state).to eq('redacted')
      expect(post_record.body).to include('[Content removed')
      expect(post_record.redacted_body).to eq('Original post body')
    end

    it 'raises error if user is not moderator' do
      expect {
        described_class.redact_post(post: post_record, moderator: user, reason: 'spam')
      }.to raise_error(ArgumentError, 'Moderator must have moderation privileges')
    end

    it 'raises error for invalid state' do
      expect {
        described_class.redact_post(post: post_record, moderator: moderator, reason: 'spam', state: :invalid)
      }.to raise_error(ArgumentError, 'Invalid redaction state')
    end

    it 'does not overwrite original body if already redacted' do
      described_class.redact_post(post: post_record, moderator: moderator, reason: 'spam')
      original_redacted_body = post_record.redacted_body

      # Change body to something else (simulating a change or just checking it doesn't grab the placeholder)
      post_record.update_columns(body: 'Placeholder')

      described_class.redact_post(post: post_record, moderator: moderator, reason: 'spam')
      post_record.reload
      expect(post_record.redacted_body).to eq(original_redacted_body)
    end

    it 'handles errors gracefully' do
      allow(post_record).to receive(:update!).and_raise(StandardError, 'DB Error')
      expect(Rails.logger).to receive(:error).with(/RedactionService.redact_post failed/)
      expect(described_class.redact_post(post: post_record, moderator: moderator, reason: 'spam')).to be false
    end
  end

  describe '.unredact_post' do
    before { described_class.redact_post(post: post_record, moderator: moderator, reason: 'spam') }

    it 'unredacts a post' do
      expect(described_class.unredact_post(post: post_record, moderator: moderator)).to be true
      post_record.reload
      expect(post_record.redaction_state).to eq('visible')
      expect(post_record.body).to eq('Original post body')
    end

    it 'raises error if post is not redacted' do
      post_record.update(redaction_state: 'visible')
      expect {
        described_class.unredact_post(post: post_record, moderator: moderator)
      }.to raise_error(ArgumentError, 'Post is not redacted')
    end

    it 'raises error if user is not moderator' do
      expect {
        described_class.unredact_post(post: post_record, moderator: user)
      }.to raise_error(ArgumentError, 'Moderator must have moderation privileges')
    end

    it 'handles errors gracefully' do
      allow(post_record).to receive(:update!).and_raise(StandardError, 'DB Error')
      expect(Rails.logger).to receive(:error).with(/RedactionService.unredact_post failed/)
      expect(described_class.unredact_post(post: post_record, moderator: moderator)).to be false
    end
  end

  describe '.redact_answer' do
    it 'redacts an answer' do
      expect(described_class.redact_answer(answer: answer, moderator: moderator, reason: 'spam')).to be true
      answer.reload
      expect(answer.redaction_state).to eq('redacted')
      expect(answer.body).to include('[Content removed')
      expect(answer.redacted_body).to eq('Original answer body')
    end

    it 'raises error if user is not moderator' do
      expect {
        described_class.redact_answer(answer: answer, moderator: user, reason: 'spam')
      }.to raise_error(ArgumentError, 'Moderator must have moderation privileges')
    end

    it 'raises error for invalid state' do
      expect {
        described_class.redact_answer(answer: answer, moderator: moderator, reason: 'spam', state: :invalid)
      }.to raise_error(ArgumentError, 'Invalid redaction state')
    end

    it 'does not overwrite original body if already redacted' do
      described_class.redact_answer(answer: answer, moderator: moderator, reason: 'spam')
      original_redacted_body = answer.redacted_body

      answer.update_columns(body: 'Placeholder')

      described_class.redact_answer(answer: answer, moderator: moderator, reason: 'spam')
      answer.reload
      expect(answer.redacted_body).to eq(original_redacted_body)
    end

    it 'handles errors gracefully' do
      allow(answer).to receive(:update!).and_raise(StandardError, 'DB Error')
      expect(Rails.logger).to receive(:error).with(/RedactionService.redact_answer failed/)
      expect(described_class.redact_answer(answer: answer, moderator: moderator, reason: 'spam')).to be false
    end
  end

  describe '.unredact_answer' do
    before { described_class.redact_answer(answer: answer, moderator: moderator, reason: 'spam') }

    it 'unredacts an answer' do
      expect(described_class.unredact_answer(answer: answer, moderator: moderator)).to be true
      answer.reload
      expect(answer.redaction_state).to eq('visible')
      expect(answer.body).to eq('Original answer body')
    end

    it 'raises error if answer is not redacted' do
      answer.update(redaction_state: 'visible')
      expect {
        described_class.unredact_answer(answer: answer, moderator: moderator)
      }.to raise_error(ArgumentError, 'Answer is not redacted')
    end

    it 'raises error if user is not moderator' do
      expect {
        described_class.unredact_answer(answer: answer, moderator: user)
      }.to raise_error(ArgumentError, 'Moderator must have moderation privileges')
    end

    it 'handles errors gracefully' do
      allow(answer).to receive(:update!).and_raise(StandardError, 'DB Error')
      expect(Rails.logger).to receive(:error).with(/RedactionService.unredact_answer failed/)
      expect(described_class.unredact_answer(answer: answer, moderator: moderator)).to be false
    end
  end

  describe '.placeholder_text' do
    it 'returns partial text' do
      expect(described_class.send(:placeholder_text, :partial)).to eq('[Portions of this content have been redacted by CU moderators]')
    end

    it 'returns nil for unknown state' do
      expect(described_class.send(:placeholder_text, :unknown)).to be_nil
    end
  end
end
