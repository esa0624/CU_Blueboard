require 'rails_helper'

RSpec.describe 'Static pages', type: :request do
  describe 'GET /honor-code' do
    it 'renders the honor code page' do
      get honor_code_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Honor Code')
      expect(response.body).to include('Academic Integrity')
    end

    it 'displays the last updated date' do
      get honor_code_path
      expect(response.body).to include('December 01, 2025')
    end
  end

  describe 'GET /terms' do
    it 'renders the terms of service page' do
      get terms_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Terms of Service')
      expect(response.body).to include('Acceptance of Terms')
    end

    it 'displays the last updated date' do
      get terms_path
      expect(response.body).to include('December 01, 2025')
    end
  end
end
