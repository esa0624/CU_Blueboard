require 'rails_helper'

RSpec.describe "Post Reporting", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:post_record) { create(:post, user: other_user) }

  describe "POST /posts/:id/report" do
    context "when signed in" do
      before { sign_in user }

      it "creates a report and flags the post" do
        expect {
          post report_post_path(post_record), params: { reason: 'inappropriate' }
        }.to change(PostReport, :count).by(1)

        expect(post_record.reload.reported).to be(true)
        expect(post_record.reports_count).to eq(1)
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Content reported to moderators.')
      end

      it "uses default reason if none provided" do
        post report_post_path(post_record)

        report = PostReport.last
        expect(report.reason).to eq('inappropriate')
      end

      it "accepts different report reasons" do
        post report_post_path(post_record), params: { reason: 'harassment' }

        report = PostReport.last
        expect(report.reason).to eq('harassment')
      end

      it "prevents duplicate reports" do
        create(:post_report, user: user, post: post_record)

        expect {
          post report_post_path(post_record)
        }.not_to change(PostReport, :count)

        follow_redirect!
        expect(response.body).to include('You have already reported this post.')
      end

      it "prevents reporting own post" do
        own_post = create(:post, user: user)

        expect {
          post report_post_path(own_post)
        }.not_to change(PostReport, :count)

        follow_redirect!
        expect(response.body).to include('You cannot report your own post.')
      end
    end
  end

  describe "DELETE /posts/:id/dismiss_flag" do
    context "when the user reported the post" do
      before do
        sign_in user
        create(:post_report, user: user, post: post_record)
        post_record.update!(reported: true, reported_at: Time.current, reported_reason: '1 report(s)')
      end

      it "removes the user's report" do
        expect(post_record.reload.reports_count).to eq(1)

        expect {
          delete dismiss_flag_post_path(post_record)
        }.to change(PostReport, :count).by(-1)

        expect(post_record.reload.reported).to be(false)
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Your report has been removed.')
      end
    end

    context "when multiple users reported the post" do
      let(:third_user) { create(:user) }

      before do
        sign_in user
        create(:post_report, user: user, post: post_record)
        create(:post_report, user: third_user, post: post_record)
        post_record.update!(reported: true, reported_at: Time.current, reported_reason: '2 report(s)')
      end

      it "removes only the user's report, keeping the post flagged" do
        expect {
          delete dismiss_flag_post_path(post_record)
        }.to change(PostReport, :count).by(-1)

        # Post still flagged because third_user's report remains
        expect(post_record.reload.reports_count).to eq(1)
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Your report has been removed.')
      end
    end

    context "when the user did not report the post" do
      let(:third_user) { create(:user) }

      before do
        sign_in user
        create(:post_report, user: third_user, post: post_record)
        post_record.update!(reported: true, reported_at: Time.current, reported_reason: '1 report(s)')
      end

      it "does not remove any report" do
        expect {
          delete dismiss_flag_post_path(post_record)
        }.not_to change(PostReport, :count)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('You have not reported this post.')
      end
    end

    context "when a moderator dismisses all reports" do
      let(:moderator) { create(:user, role: :moderator) }
      let(:third_user) { create(:user) }

      before do
        sign_in moderator
        create(:post_report, user: user, post: post_record)
        create(:post_report, user: third_user, post: post_record)
        post_record.update!(reported: true, reported_at: Time.current, reported_reason: '2 report(s)')
      end

      it "removes all reports" do
        expect(post_record.post_reports.count).to eq(2)

        expect {
          delete dismiss_flag_post_path(post_record)
        }.to change(PostReport, :count).by(-2)

        expect(post_record.reload.reported).to be(false)
        expect(post_record.reports_count).to eq(0)
        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('All reports dismissed.')
      end
    end
  end

  describe "report tracking" do
    before { sign_in user }

    it "increments reports_count via counter_cache" do
      expect {
        post report_post_path(post_record)
      }.to change { post_record.reload.reports_count }.from(0).to(1)
    end
  end

  describe "Post#reported_by?" do
    before { sign_in user }

    it "returns true when user has reported the post" do
      create(:post_report, user: user, post: post_record)
      expect(post_record.reported_by?(user)).to be(true)
    end

    it "returns false when user has not reported the post" do
      expect(post_record.reported_by?(user)).to be(false)
    end

    it "returns false for nil user" do
      expect(post_record.reported_by?(nil)).to be(false)
    end
  end

  describe "Post#needs_urgent_review?" do
    it "returns true when reports_count >= 3" do
      3.times { create(:post_report, post: post_record) }
      expect(post_record.needs_urgent_review?).to be(true)
    end

    it "returns false when reports_count < 3" do
      2.times { create(:post_report, post: post_record) }
      expect(post_record.needs_urgent_review?).to be(false)
    end

    it "returns false when no reports" do
      expect(post_record.needs_urgent_review?).to be(false)
    end
  end
end
