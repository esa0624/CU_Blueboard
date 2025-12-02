require 'rails_helper'

RSpec.describe "AnswerCommentLikes", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }
  let(:answer) { create(:answer, post: post_record) }
  let(:comment) { create(:answer_comment, answer: answer) }

  describe "POST /posts/:post_id/answers/:answer_id/comments/:comment_id/upvote" do
    context "when signed in" do
      before { sign_in user }

      context "when no existing vote" do
        it "creates an upvote" do
          expect {
            post upvote_post_answer_comment_path(post_record, answer, comment)
          }.to change { comment.answer_comment_likes.upvotes.count }.by(1)

          expect(response).to redirect_to(post_path(post_record, anchor: "comment-#{comment.id}"))
        end
      end

      context "when already upvoted (toggle off)" do
        before { create(:answer_comment_like, :upvote, user: user, answer_comment: comment) }

        it "removes the upvote" do
          expect {
            post upvote_post_answer_comment_path(post_record, answer, comment)
          }.to change { comment.answer_comment_likes.count }.by(-1)
        end
      end

      context "when already downvoted (switch to upvote)" do
        before { create(:answer_comment_like, :downvote, user: user, answer_comment: comment) }

        it "switches to upvote" do
          post upvote_post_answer_comment_path(post_record, answer, comment)
          expect(comment.find_vote_by(user).upvote?).to be true
        end
      end
    end

    context "when not signed in" do
      it "requires authentication" do
        post upvote_post_answer_comment_path(post_record, answer, comment)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a vote" do
        expect {
          post upvote_post_answer_comment_path(post_record, answer, comment)
        }.not_to change(AnswerCommentLike, :count)
      end
    end
  end

  describe "POST /posts/:post_id/answers/:answer_id/comments/:comment_id/downvote" do
    context "when signed in" do
      before { sign_in user }

      context "when no existing vote" do
        it "creates a downvote" do
          expect {
            post downvote_post_answer_comment_path(post_record, answer, comment)
          }.to change { comment.answer_comment_likes.downvotes.count }.by(1)

          expect(response).to redirect_to(post_path(post_record, anchor: "comment-#{comment.id}"))
        end
      end

      context "when already downvoted (toggle off)" do
        before { create(:answer_comment_like, :downvote, user: user, answer_comment: comment) }

        it "removes the downvote" do
          expect {
            post downvote_post_answer_comment_path(post_record, answer, comment)
          }.to change { comment.answer_comment_likes.count }.by(-1)
        end
      end

      context "when already upvoted (switch to downvote)" do
        before { create(:answer_comment_like, :upvote, user: user, answer_comment: comment) }

        it "switches to downvote" do
          post downvote_post_answer_comment_path(post_record, answer, comment)
          expect(comment.find_vote_by(user).downvote?).to be true
        end
      end
    end

    context "when not signed in" do
      it "requires authentication" do
        post downvote_post_answer_comment_path(post_record, answer, comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
