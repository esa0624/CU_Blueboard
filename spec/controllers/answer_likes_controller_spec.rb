require 'rails_helper'

RSpec.describe AnswerLikesController, type: :controller do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }
  let(:answer) { create(:answer, post: post_record) }

  before { sign_in user }

  describe 'POST #upvote' do
    context 'when no vote exists' do
      it 'creates an upvote' do
        expect {
          post :upvote, params: { post_id: post_record.id, id: answer.id }
        }.to change(AnswerLike, :count).by(1)
        expect(answer.answer_likes.last.upvote?).to be true
      end
    end

    context 'when upvote exists' do
      before { create(:answer_like, user: user, answer: answer, vote_type: AnswerLike::UPVOTE) }

      it 'removes the upvote (toggle)' do
        expect {
          post :upvote, params: { post_id: post_record.id, id: answer.id }
        }.to change(AnswerLike, :count).by(-1)
      end
    end

    context 'when downvote exists' do
      before { create(:answer_like, user: user, answer: answer, vote_type: AnswerLike::DOWNVOTE) }

      it 'switches to upvote' do
        expect {
          post :upvote, params: { post_id: post_record.id, id: answer.id }
        }.not_to change(AnswerLike, :count)
        expect(answer.answer_likes.last.upvote?).to be true
      end
    end
  end

  describe 'POST #downvote' do
    context 'when no vote exists' do
      it 'creates a downvote' do
        expect {
          post :downvote, params: { post_id: post_record.id, id: answer.id }
        }.to change(AnswerLike, :count).by(1)
        expect(answer.answer_likes.last.downvote?).to be true
      end
    end

    context 'when downvote exists' do
      before { create(:answer_like, user: user, answer: answer, vote_type: AnswerLike::DOWNVOTE) }

      it 'removes the downvote (toggle)' do
        expect {
          post :downvote, params: { post_id: post_record.id, id: answer.id }
        }.to change(AnswerLike, :count).by(-1)
      end
    end

    context 'when upvote exists' do
      before { create(:answer_like, user: user, answer: answer, vote_type: AnswerLike::UPVOTE) }

      it 'switches to downvote' do
        expect {
          post :downvote, params: { post_id: post_record.id, id: answer.id }
        }.not_to change(AnswerLike, :count)
        expect(answer.answer_likes.last.downvote?).to be true
      end
    end
  end
end
