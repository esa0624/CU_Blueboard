require 'rails_helper'

RSpec.describe "Blocking Duplicate Posts", type: :request do
  let(:user) { create(:user) }
  let!(:existing_post) { create(:post, title: "How to register for classes?", body: "I need help with registration.") }
  let(:topic) { create(:topic) }
  let(:tag) { create(:tag) }

  before do
    sign_in user
  end

  it "blocks duplicate post creation and allows override" do
    post_params = {
      post: {
        title: "How to register for classes?",
        body: "I need help with registration.",
        topic_id: topic.id,
        school: "Columbia",
        tag_ids: [ tag.id ]
      }
    }

    # First attempt: Should be blocked
    post posts_path, params: post_params

    expect(response).to have_http_status(:unprocessable_content)
    expect(flash[:alert]).to include("Potential duplicate threads found")
    expect(Post.count).to eq(1)

    # Second attempt with confirmation: Should succeed
    post posts_path, params: post_params.merge(confirm_duplicate: 'true')

    expect(response).to redirect_to(posts_path)
    follow_redirect!
    expect(flash[:notice]).to eq("Post was successfully created!")
    expect(Post.count).to eq(2)
  end
end
