require 'rails_helper'

RSpec.describe "AnswerLikes", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }
  let(:answer) { create(:answer, post: post_record) }

  describe "POST /posts/:post_id/answers/:answer_id/upvote" do
    context "when signed in" do
      before { sign_in user }

      context "when no existing vote" do
        it "creates an upvote" do
          expect {
            post upvote_post_answer_path(post_record, answer)
          }.to change { answer.answer_likes.upvotes.count }.by(1)

          expect(response).to redirect_to(post_path(post_record, anchor: "answer-#{answer.id}"))
        end
      end

      context "when already upvoted (toggle off)" do
        before { create(:answer_like, :upvote, user: user, answer: answer) }

        it "removes the upvote" do
          expect {
            post upvote_post_answer_path(post_record, answer)
          }.to change { answer.answer_likes.count }.by(-1)
        end
      end

      context "when already downvoted (switch to upvote)" do
        before { create(:answer_like, :downvote, user: user, answer: answer) }

        it "switches to upvote" do
          post upvote_post_answer_path(post_record, answer)
          expect(answer.find_vote_by(user).upvote?).to be true
        end
      end
    end

    context "when not signed in" do
      it "requires authentication" do
        post upvote_post_answer_path(post_record, answer)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a vote" do
        expect {
          post upvote_post_answer_path(post_record, answer)
        }.not_to change(AnswerLike, :count)
      end
    end
  end

  describe "POST /posts/:post_id/answers/:answer_id/downvote" do
    context "when signed in" do
      before { sign_in user }

      context "when no existing vote" do
        it "creates a downvote" do
          expect {
            post downvote_post_answer_path(post_record, answer)
          }.to change { answer.answer_likes.downvotes.count }.by(1)

          expect(response).to redirect_to(post_path(post_record, anchor: "answer-#{answer.id}"))
        end
      end

      context "when already downvoted (toggle off)" do
        before { create(:answer_like, :downvote, user: user, answer: answer) }

        it "removes the downvote" do
          expect {
            post downvote_post_answer_path(post_record, answer)
          }.to change { answer.answer_likes.count }.by(-1)
        end
      end

      context "when already upvoted (switch to downvote)" do
        before { create(:answer_like, :upvote, user: user, answer: answer) }

        it "switches to downvote" do
          post downvote_post_answer_path(post_record, answer)
          expect(answer.find_vote_by(user).downvote?).to be true
        end
      end
    end

    context "when not signed in" do
      it "requires authentication" do
        post downvote_post_answer_path(post_record, answer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
