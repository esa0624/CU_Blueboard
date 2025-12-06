require 'rails_helper'

RSpec.describe "Post Reporting", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:post_record) { create(:post, user: other_user) }

  describe "POST /posts/:id/report" do
    context "when signed in" do
      before { sign_in user }

      it "flags the post and tracks it in session" do
        post report_post_path(post_record)

        expect(post_record.reload.reported).to be(true)
        expect(post_record.reported_reason).to eq('User flagged')
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Content flagged for moderator review.')
      end
    end
  end

  describe "DELETE /posts/:id/dismiss_flag" do
    context "when the user reported the post" do
      before do
        sign_in user
        # User reports the post first to set the session
        post report_post_path(post_record)
      end

      it "unflags the post" do
        expect(post_record.reload.reported).to be(true)

        delete dismiss_flag_post_path(post_record)

        expect(post_record.reload.reported).to be(false)
        expect(post_record.reported_reason).to be_nil
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Flag removed.')
      end
    end

    context "when the user did not report the post" do
      before do
        sign_in user
        # Manually flag the post as if someone else did it
        post_record.update!(reported: true, reported_reason: 'User flagged')
      end

      it "does not unflag the post" do
        delete dismiss_flag_post_path(post_record)

        expect(post_record.reload.reported).to be(true)
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('You cannot unflag this post.')
      end
    end

    context "when a moderator dismisses the flag" do
      let(:moderator) { create(:user, role: :moderator) }

      before do
        sign_in moderator
        post_record.update!(reported: true, reported_reason: 'User flagged')
      end

      it "dismisses the flag" do
        delete dismiss_flag_post_path(post_record)

        expect(post_record.reload.reported).to be(false)
        expect(post_record.reported_reason).to be_nil
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Flag dismissed.')
      end
    end
  end
end
