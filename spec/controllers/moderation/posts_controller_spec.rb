require 'rails_helper'

RSpec.describe Moderation::PostsController, type: :controller do
  let(:moderator) { create(:user, :moderator) }
  let(:post_record) { create(:post) }

  before do
    sign_in moderator
  end

  describe '#index' do
    context 'as a regular user' do
      before { sign_in create(:user) }

      it 'redirects to root' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied. Moderator privileges required.')
      end
    end

    it 'handles sources that do not support pagination helpers' do
      # Create actual posts instead of mocking
      redacted_post = create(:post, redaction_state: :redacted, redacted_body: 'Hidden content')
      ai_flagged_post = create(:post, ai_flagged: true)
      reported_post = create(:post)
      create(:post_report, post: reported_post)
      reported_post.update!(reported: true)

      get :index

      expect(response).to have_http_status(:ok)
      expect(assigns(:redacted_posts)).to include(redacted_post)
      expect(assigns(:ai_flagged_posts)).to include(ai_flagged_post)
      expect(assigns(:reported_posts)).to include(reported_post)
    end
  end

  describe '#show' do
    it 'loads audit logs in reverse chronological order' do
      older_log = AuditLog.create!(
        user: post_record.user,
        performed_by: moderator,
        auditable: post_record,
        action: 'post_redacted',
        metadata: { note: 'older' },
        created_at: 2.hours.ago
      )
      newer_log = AuditLog.create!(
        user: post_record.user,
        performed_by: moderator,
        auditable: post_record,
        action: 'post_unredacted',
        metadata: { note: 'newer' },
        created_at: 1.hour.ago
      )

      get :show, params: { id: post_record.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:audit_logs)).to eq([ newer_log, older_log ])
    end
  end

  describe '#redact' do
    it 'uses default reason/state when params are blank' do
      expect(RedactionService).to receive(:redact_post).with(
        post: post_record,
        moderator: moderator,
        reason: 'policy_violation',
        state: :redacted
      ).and_return(true)

      patch :redact, params: { id: post_record.id }

      expect(response).to redirect_to(moderation_posts_path)
      expect(flash[:notice]).to eq('Post has been redacted.')
    end

    it 'passes through provided reason/state and surfaces failures' do
      expect(RedactionService).to receive(:redact_post).with(
        post: post_record,
        moderator: moderator,
        reason: 'spam',
        state: :partial
      ).and_return(false)

      patch :redact, params: { id: post_record.id, reason: 'spam', state: 'partial' }

      expect(response).to redirect_to(moderation_posts_path)
      expect(flash[:alert]).to eq('Failed to redact post.')
    end
  end

  describe '#unredact' do
    it 'redirects with a notice when the service succeeds' do
      expect(RedactionService).to receive(:unredact_post).with(
        post: post_record,
        moderator: moderator
      ).and_return(true)

      patch :unredact, params: { id: post_record.id }

      expect(response).to redirect_to(moderation_posts_path)
      expect(flash[:notice]).to eq('Post has been restored.')
    end

    it 'shows an alert when the service fails' do
      expect(RedactionService).to receive(:unredact_post).with(
        post: post_record,
        moderator: moderator
      ).and_return(false)

      patch :unredact, params: { id: post_record.id }

      expect(response).to redirect_to(moderation_posts_path)
      expect(flash[:alert]).to eq('Failed to restore post.')
    end
  end
end
