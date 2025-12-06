require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #honor_code' do
    it 'returns http success' do
      get :honor_code
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #terms' do
    it 'returns http success' do
      get :terms
      expect(response).to have_http_status(:success)
    end
  end
end
