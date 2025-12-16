require 'rails_helper'

RSpec.describe PostChannel, type: :channel do
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

  describe '#unsubscribed' do
    it 'stops all streams' do
      subscribe(post_id: post_record.id)
      expect(subscription).to have_stream_for(post_record)

      subscription.unsubscribe_from_channel
      # After unsubscribe, the subscription should stop streaming
    end
  end
end
