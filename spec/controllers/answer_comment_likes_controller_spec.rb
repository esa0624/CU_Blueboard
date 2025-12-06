require 'rails_helper'

RSpec.describe AnswerCommentLikesController, type: :controller do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }
  let(:answer) { create(:answer, post: post_record) }
  let(:comment) { create(:answer_comment, answer: answer) }

  before { sign_in user }

  describe 'POST #upvote' do
    context 'when no vote exists' do
      it 'creates an upvote' do
        expect {
          post :upvote, params: { post_id: post_record.id, answer_id: answer.id, id: comment.id }
        }.to change(AnswerCommentLike, :count).by(1)
        expect(comment.answer_comment_likes.last.upvote?).to be true
      end
    end

    context 'when upvote exists' do
      before { create(:answer_comment_like, user: user, answer_comment: comment, vote_type: AnswerCommentLike::UPVOTE) }

      it 'removes the upvote (toggle)' do
        expect {
          post :upvote, params: { post_id: post_record.id, answer_id: answer.id, id: comment.id }
        }.to change(AnswerCommentLike, :count).by(-1)
      end
    end

    context 'when downvote exists' do
      before { create(:answer_comment_like, user: user, answer_comment: comment, vote_type: AnswerCommentLike::DOWNVOTE) }

      it 'switches to upvote' do
        expect {
          post :upvote, params: { post_id: post_record.id, answer_id: answer.id, id: comment.id }
        }.not_to change(AnswerCommentLike, :count)
        expect(comment.answer_comment_likes.last.upvote?).to be true
      end
    end
  end

  describe 'POST #downvote' do
    context 'when no vote exists' do
      it 'creates a downvote' do
        expect {
          post :downvote, params: { post_id: post_record.id, answer_id: answer.id, id: comment.id }
        }.to change(AnswerCommentLike, :count).by(1)
        expect(comment.answer_comment_likes.last.downvote?).to be true
      end
    end

    context 'when downvote exists' do
      before { create(:answer_comment_like, user: user, answer_comment: comment, vote_type: AnswerCommentLike::DOWNVOTE) }

      it 'removes the downvote (toggle)' do
        expect {
          post :downvote, params: { post_id: post_record.id, answer_id: answer.id, id: comment.id }
        }.to change(AnswerCommentLike, :count).by(-1)
      end
    end

    context 'when upvote exists' do
      before { create(:answer_comment_like, user: user, answer_comment: comment, vote_type: AnswerCommentLike::UPVOTE) }

      it 'switches to downvote' do
        expect {
          post :downvote, params: { post_id: post_record.id, answer_id: answer.id, id: comment.id }
        }.not_to change(AnswerCommentLike, :count)
        expect(comment.answer_comment_likes.last.downvote?).to be true
      end
    end
  end
end
