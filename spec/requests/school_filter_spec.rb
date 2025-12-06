require 'rails_helper'

RSpec.describe "School Filter Search", type: :request do
  let(:user) { create(:user) }
  let!(:columbia_post) { create(:post, title: "Columbia Post", school: "Columbia", user: user) }

  before do
    sign_in user
  end

  it "allows searching by school only" do
    get posts_path, params: { filters: { school: "Columbia", q: "" } }

    # If blocked, it sets a flash alert
    expect(flash[:alert]).to be_nil
    expect(response.body).to include("Columbia Post")
  end

  it "allows searching by course only" do
    get posts_path, params: { filters: { course_code: "COMS", q: "" } }

    expect(flash[:alert]).to be_nil
  end
end
