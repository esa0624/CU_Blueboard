require 'rails_helper'

RSpec.describe "General School Filter", type: :request do
  let(:user) { create(:user) }
  let!(:general_post) { create(:post, title: "General Post", school: "General", user: user) }
  let!(:columbia_post) { create(:post, title: "Columbia Post", school: "Columbia", user: user) }

  before do
    sign_in user
  end

  it "filters by General school" do
    get posts_path, params: { filters: { school: "General", q: "" } }

    expect(response.body).to include("General Post")
    expect(response.body).not_to include("Columbia Post")
  end

  it "filters by Columbia school" do
    get posts_path, params: { filters: { school: "Columbia", q: "" } }

    expect(response.body).to include("Columbia Post")
    expect(response.body).not_to include("General Post")
  end
end
