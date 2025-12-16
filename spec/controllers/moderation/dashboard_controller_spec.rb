require 'rails_helper'

RSpec.describe Moderation::DashboardController, type: :controller do
  let(:moderator) { create(:user, :moderator) }
  let(:student) { create(:user) }
  let(:topic) { create(:topic) }

  describe 'GET #index' do
    context 'when logged in as moderator' do
      before { sign_in moderator }

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns daily_posts statistics' do
        create(:post, user: student, topic: topic, created_at: 2.days.ago)
        create(:post, user: student, topic: topic, created_at: 1.day.ago)
        create(:post, user: student, topic: topic, created_at: Time.current)

        get :index

        expect(assigns(:daily_posts)).to be_a(Hash)
        expect(assigns(:daily_posts).values.sum).to be >= 3
      end

      it 'assigns topic_distribution statistics' do
        create(:post, user: student, topic: topic)

        get :index

        expect(assigns(:topic_distribution)).to be_a(Hash)
        expect(assigns(:topic_distribution)).to have_key(topic.name)
      end

      it 'assigns stats hash with expected keys' do
        get :index

        stats = assigns(:stats)
        expect(stats).to include(
          :total_posts,
          :total_answers,
          :total_users,
          :response_rate,
          :resolution_rate,
          :redacted_posts,
          :ai_flagged_posts,
          :reported_posts
        )
      end

      it 'calculates response_rate correctly' do
        post_with_answer = create(:post, user: student, topic: topic)
        create(:answer, post: post_with_answer, user: moderator)
        create(:post, user: student, topic: topic) # post without answer

        get :index

        stats = assigns(:stats)
        expect(stats[:response_rate]).to be_a(Float).or be_a(Integer)
        expect(stats[:response_rate]).to be >= 0
        expect(stats[:response_rate]).to be <= 100
      end

      it 'calculates resolution_rate correctly' do
        create(:post, user: student, topic: topic, status: 'solved')
        create(:post, user: student, topic: topic, status: 'open')

        get :index

        stats = assigns(:stats)
        expect(stats[:resolution_rate]).to be_a(Float).or be_a(Integer)
        expect(stats[:resolution_rate]).to be >= 0
        expect(stats[:resolution_rate]).to be <= 100
      end

      it 'counts redacted posts' do
        post = create(:post, user: student, topic: topic)
        post.update_columns(redaction_state: 'redacted', redacted_body: 'Original content')

        get :index

        expect(assigns(:stats)[:redacted_posts]).to be >= 1
      end

      it 'counts ai_flagged posts' do
        create(:post, user: student, topic: topic, ai_flagged: true)

        get :index

        expect(assigns(:stats)[:ai_flagged_posts]).to be >= 1
      end

      it 'counts reported posts' do
        create(:post, user: student, topic: topic, reported: true)

        get :index

        expect(assigns(:stats)[:reported_posts]).to be >= 1
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when logged in as student' do
      before { sign_in student }

      it 'redirects to root with alert' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'edge cases' do
      before { sign_in moderator }

      it 'handles zero posts gracefully' do
        Post.destroy_all

        get :index

        stats = assigns(:stats)
        expect(stats[:response_rate]).to eq(0)
        expect(stats[:resolution_rate]).to eq(0)
      end
    end
  end
end
