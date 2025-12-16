require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }

  describe '#connect' do
    context 'with authenticated user' do
      it 'successfully connects' do
        connect '/cable', env: { 'warden' => double(user: user) }
        expect(connection.current_user).to eq(user)
      end
    end

    context 'without authenticated user' do
      it 'rejects connection' do
        expect {
          connect '/cable', env: { 'warden' => double(user: nil) }
        }.to have_rejected_connection
      end
    end

    context 'without warden' do
      it 'rejects connection' do
        expect {
          connect '/cable', env: {}
        }.to have_rejected_connection
      end
    end
  end
end
