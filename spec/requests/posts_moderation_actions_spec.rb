require 'rails_helper'

RSpec.describe "Missing Coverage Specs", type: :request do
  let(:moderator) { create(:user, :moderator) }
  let(:post_record) { create(:post, ai_flagged: true) }

  before { sign_in moderator }

  describe "PATCH /posts/:id/clear_ai_flag" do
    it "successfully clears the AI flag" do
      patch clear_ai_flag_post_path(post_record)

      expect(response).to redirect_to(post_path(post_record))
      follow_redirect!
      expect(response.body).to include('AI flag cleared.')
      expect(post_record.reload.ai_flagged).to be false
    end
  end
end
