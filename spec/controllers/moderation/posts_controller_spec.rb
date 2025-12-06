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
      redacted_posts = [ create(:post, redaction_state: :redacted, redacted_body: 'Hidden content') ]
      ai_flagged_posts = [ create(:post, ai_flagged: true) ]

      redacted_relation = instance_double(ActiveRecord::Relation)
      ai_flagged_relation = instance_double(ActiveRecord::Relation)

      # Mock for redacted posts
      allow(Post).to receive(:where).with(redaction_state: [ :redacted, :partial ]).and_return(redacted_relation)
      allow(redacted_relation).to receive(:includes).with(:user, :redacted_by).and_return(redacted_relation)
      allow(redacted_relation).to receive(:order).with(updated_at: :desc).and_return(redacted_posts)
      allow(redacted_posts).to receive(:respond_to?).with(:page).and_return(false)

      # Mock for AI-flagged posts
      allow(Post).to receive(:where).with(ai_flagged: true, redaction_state: 'visible').and_return(ai_flagged_relation)
      allow(ai_flagged_relation).to receive(:includes).with(:user, :redacted_by).and_return(ai_flagged_relation)
      allow(ai_flagged_relation).to receive(:order).with(updated_at: :desc).and_return(ai_flagged_posts)
      allow(ai_flagged_posts).to receive(:respond_to?).with(:page).and_return(false)

      # Mock for User-reported posts
      reported_relation = instance_double(ActiveRecord::Relation)
      reported_posts = []
      allow(Post).to receive(:where).with(reported: true, redaction_state: 'visible').and_return(reported_relation)
      allow(reported_relation).to receive(:includes).with(:user).and_return(reported_relation)
      allow(reported_relation).to receive(:order).with(reported_at: :desc).and_return(reported_posts)

      get :index

      expect(response).to have_http_status(:ok)
      expect(assigns(:redacted_posts)).to eq(redacted_posts)
      expect(assigns(:ai_flagged_posts)).to eq(ai_flagged_posts)
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
