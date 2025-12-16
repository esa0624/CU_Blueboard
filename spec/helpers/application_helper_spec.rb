require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post_record) { create(:post, user: user) }

  describe '#display_author' do
    context 'when user is nil' do
      it 'returns Anonymous Student' do
        expect(helper.display_author(nil)).to eq('Anonymous Student')
      end
    end

    context 'when real identity is revealed' do
      before { post_record.update(show_real_identity: true) }

      it 'returns email' do
        expect(helper.display_author(user, context: post_record)).to eq(user.email)
      end
    end

    context 'when user is current user' do
      before { allow(helper).to receive(:current_user).and_return(user) }

      it 'returns You' do
        expect(helper.display_author(user, context: post_record)).to eq('You')
      end
    end

    context 'when user is not current user' do
      before { allow(helper).to receive(:current_user).and_return(other_user) }

      it 'returns pseudonym for thread' do
        identity = ThreadIdentity.find_by(user: user, post: post_record)
        identity.update!(pseudonym: 'Lion #1234')
        expect(helper.display_author(user, context: post_record)).to eq('Lion #1234')
      end

      it 'returns pseudonym for answer context' do
        answer = create(:answer, post: post_record, user: user)
        identity = ThreadIdentity.find_by(user: user, post: post_record)
        identity.update!(pseudonym: 'Lion #1234')
        expect(helper.display_author(user, context: answer)).to eq('Lion #1234')
      end

      it 'returns anonymous handle if no thread context' do
        expect(helper.display_author(user)).to eq(user.anonymous_handle)
      end
    end

    context 'when current_user is nil' do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it 'returns pseudonym if thread exists' do
        identity = ThreadIdentity.find_by(user: user, post: post_record)
        identity.update!(pseudonym: 'Lion #1234')
        expect(helper.display_author(user, context: post_record)).to eq('Lion #1234')
      end
    end
  end

  describe '#display_author_for_moderator' do
    context 'when user is nil' do
      it 'returns Unknown' do
        expect(helper.display_author_for_moderator(nil)).to eq('Unknown')
      end
    end

    context 'when user exists with thread context' do
      it 'returns pseudonym and email' do
        identity = ThreadIdentity.find_by(user: user, post: post_record)
        identity.update!(pseudonym: 'Lion #5678')
        result = helper.display_author_for_moderator(user, context: post_record)
        expect(result).to eq("Lion #5678 (#{user.email})")
      end
    end

    context 'when user exists without thread context' do
      it 'returns anonymous handle and email' do
        result = helper.display_author_for_moderator(user)
        expect(result).to eq("#{user.anonymous_handle} (#{user.email})")
      end
    end

    context 'with answer context' do
      it 'returns pseudonym and email using answer post' do
        answer = create(:answer, post: post_record, user: user)
        identity = ThreadIdentity.find_by(user: user, post: post_record)
        identity.update!(pseudonym: 'Lion #9999')
        result = helper.display_author_for_moderator(user, context: answer)
        expect(result).to eq("Lion #9999 (#{user.email})")
      end
    end
  end
end
