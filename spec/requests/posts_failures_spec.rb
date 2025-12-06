require 'rails_helper'

RSpec.describe "Posts Controller Failures", type: :request do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let(:post_record) { create(:post, user: user) }

  before { sign_in user }

  describe "POST /posts/:id/report" do
    it "alerts when reporting fails" do
      allow_any_instance_of(Post).to receive(:update).and_return(false)

      post report_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Unable to flag content.')
    end
  end

  describe "DELETE /posts/:id/dismiss_flag" do
    context "as moderator" do
      before { sign_in moderator }

      it "alerts when dismissal fails" do
        allow_any_instance_of(Post).to receive(:update).and_return(false)

        delete dismiss_flag_post_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Unable to dismiss flag.')
      end
    end

    context "as user" do
      it "alerts when removal fails" do
        # Simulate user having reported the post
        post report_post_path(post_record)

        allow_any_instance_of(Post).to receive(:update).and_return(false)

        delete dismiss_flag_post_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('Unable to remove flag.')
      end

      it "alerts when user hasn't reported the post" do
        delete dismiss_flag_post_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include('You cannot unflag this post.')
      end
    end
  end

  describe "PATCH /posts/:id/clear_ai_flag" do
    before { sign_in moderator }

    it "alerts when clearing fails" do
      allow_any_instance_of(Post).to receive(:update).and_return(false)

      patch clear_ai_flag_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Unable to clear AI flag.')
    end

    it "denies non-moderators" do
      sign_in user
      patch clear_ai_flag_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Permission denied.')
    end
  end

  describe "POST /posts/:id/bookmark" do
    it "alerts when bookmarking fails" do
      allow_any_instance_of(Bookmark).to receive(:save).and_return(false)

      post bookmark_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Unable to bookmark this post.')
    end
  end

  describe "DELETE /posts/:id/unbookmark" do
    it "alerts when unbookmarking fails" do
      create(:bookmark, user: user, post: post_record)
      allow_any_instance_of(Bookmark).to receive(:destroy).and_return(false)

      delete unbookmark_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Unable to remove bookmark.')
    end
  end

  describe "PATCH /posts/:id/reveal_identity" do
    it "alerts when reveal fails" do
      allow_any_instance_of(Post).to receive(:update).and_return(false)

      patch reveal_identity_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Unable to reveal identity.')
    end
  end

  describe "PATCH /posts/:id/hide_identity" do
    before { post_record.update(show_real_identity: true) }

    it "alerts when hide fails" do
      allow_any_instance_of(Post).to receive(:update).and_return(false)

      patch hide_identity_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Unable to hide identity.')
    end
  end

  describe "POST /posts/:id/appeal" do
    let(:ai_post) { create(:post, ai_flagged: true, user: user) }

    it "alerts when appeal submission fails (e.g. not owner)" do
      other_user = create(:user)
      sign_in other_user

      post appeal_post_path(ai_post)

      expect(response).to redirect_to(posts_path)
      follow_redirect!
      expect(response.body).to include('This post is not available.')
    end

    it "alerts when appeal fails for other reasons (e.g. not flagged)" do
      post appeal_post_path(post_record) # post_record is not ai_flagged

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('Unable to submit appeal.')
    end
  end

  describe "Search Alert Logic" do
    it "does not alert when filtering by topic" do
      get posts_path, params: { filters: { topic_id: 1 } }
      expect(flash[:alert]).to be_nil
    end

    it "does not alert when filtering by status" do
      get posts_path, params: { filters: { status: 'open' } }
      expect(flash[:alert]).to be_nil
    end

    it "does not alert when filtering by school" do
      get posts_path, params: { filters: { school: 'Columbia' } }
      expect(flash[:alert]).to be_nil
    end

    it "does not alert when filtering by course code" do
      get posts_path, params: { filters: { course_code: 'COMS' } }
      expect(flash[:alert]).to be_nil
    end

    it "does not alert when filtering by timeframe" do
      get posts_path, params: { filters: { timeframe: '24h' } }
      expect(flash[:alert]).to be_nil
    end
  end

  describe "Post Params Edge Cases" do
    let(:topic) { create(:topic) }
    let(:tag) { create(:tag) }

    it "ignores non-positive expiration days" do
      post posts_path, params: {
        post: attributes_for(:post, expires_at: '0').merge(
          topic_id: topic.id,
          tag_ids: [ tag.id ]
        )
      }
      expect(Post.last.expires_at).to be_nil
    end

    it "ignores negative expiration days" do
      post posts_path, params: {
        post: attributes_for(:post, expires_at: '-5').merge(
          topic_id: topic.id,
          tag_ids: [ tag.id ]
        )
      }
      expect(Post.last.expires_at).to be_nil
    end
  end
end
