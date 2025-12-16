require 'rails_helper'

RSpec.describe TypingChannel, type: :channel do
  let(:user) { create(:user) }
  let(:topic) { create(:topic) }
  let(:post_record) { create(:post, user: user, topic: topic) }

  before do
    stub_connection current_user: user
  end

  describe '#subscribed' do
    context 'with valid post_id' do
      it 'successfully subscribes' do
        subscribe(post_id: post_record.id)
        expect(subscription).to be_confirmed
      end

      it 'streams for the post' do
        subscribe(post_id: post_record.id)
        expect(subscription).to have_stream_for(post_record)
      end
    end

    context 'with invalid post_id' do
      it 'rejects subscription' do
        subscribe(post_id: 999999)
        expect(subscription).to be_rejected
      end
    end
  end

  describe '#typing' do
    before do
      subscribe(post_id: post_record.id)
    end

    it 'broadcasts typing status to the post' do
      expect {
        perform :typing, { 'post_id' => post_record.id, 'typing' => true }
      }.to have_broadcasted_to(post_record).from_channel(TypingChannel)
    end

    it 'includes user pseudonym in broadcast' do
      expect {
        perform :typing, { 'post_id' => post_record.id, 'typing' => true }
      }.to have_broadcasted_to(post_record).with(
        hash_including(action: 'typing', typing: true)
      )
    end

    it 'does nothing for invalid post_id' do
      expect {
        perform :typing, { 'post_id' => 999999, 'typing' => true }
      }.not_to have_broadcasted_to(post_record)
    end
  end

  describe '#unsubscribed' do
    it 'stops all streams' do
      subscribe(post_id: post_record.id)
      subscription.unsubscribe_from_channel
    end
  end
end
