require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#google_oauth2' do
    before do
      request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: '123456',
        info: { email: 'test@example.com' }
      )
    end

    context 'when user is successfully authenticated' do
      let(:user) { create(:user) }

      before do
        allow(User).to receive(:from_omniauth).and_return(user)
      end

      it 'signs in and redirects' do
        get :google_oauth2
        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq(user)
      end
    end

    context 'when authentication fails (e.g. invalid domain)' do
      before do
        allow(User).to receive(:from_omniauth).and_return(nil)
      end

      it 'redirects to root with alert' do
        get :google_oauth2
        expect(response).to redirect_to(unauthenticated_root_path)
        expect(flash[:alert]).to include('Access Denied')
      end
    end
  end

  describe '#failure' do
    it 'redirects to root with alert' do
      get :failure
      expect(response).to redirect_to(unauthenticated_root_path)
      expect(flash[:alert]).to eq('Google sign-in failed. Please try again.')
    end
  end
end
