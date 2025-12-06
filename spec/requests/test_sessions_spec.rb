require 'rails_helper'

RSpec.describe 'Test Login', type: :request do
  describe 'POST /test_login/student' do
    it 'signs in a test student and redirects to root' do
      post test_login_student_path

      expect(response).to redirect_to(root_path)
      follow_redirect!

      expect(response.body).to include('Signed in as Test User (Student)')
      expect(controller.current_user).to be_present
      expect(controller.current_user.email).to eq('testuser@columbia.edu')
      expect(controller.current_user.role).to eq('student')
    end
  end

  describe 'POST /test_login/moderator' do
    it 'signs in a test moderator and redirects to root' do
      post test_login_moderator_path

      expect(response).to redirect_to(root_path)
      follow_redirect!

      expect(response.body).to include('Signed in as Test Moderator')
      expect(controller.current_user).to be_present
      expect(controller.current_user.email).to eq('testmoderator@columbia.edu')
      expect(controller.current_user.role).to eq('moderator')
    end
  end
end