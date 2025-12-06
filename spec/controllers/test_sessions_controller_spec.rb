require 'rails_helper'

RSpec.describe TestSessionsController, type: :controller do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe '#create_student' do
    it 'downgrades an existing non-student to student' do
      user = create(:user, email: 'testuser@columbia.edu', role: :moderator)

      post :create_student

      expect(user.reload.role).to eq('student')
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include('Signed in as Test User (Student)')
    end
  end

  describe '#create_moderator' do
    it 'upgrades an existing non-moderator to moderator' do
      user = create(:user, email: 'testmoderator@columbia.edu', role: :student)

      post :create_moderator

      expect(user.reload.role).to eq('moderator')
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include('Signed in as Test Moderator')
    end
  end
end