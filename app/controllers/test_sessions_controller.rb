class TestSessionsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :ensure_non_production

  def create_student
    user = User.find_or_create_by!(email: 'testuser@columbia.edu') do |u|
      u.password = 'password123'
      u.password_confirmation = 'password123'
      u.role = :student
    end
    # Force role upgrade if it was already created but possibly changed
    user.update(role: :student) unless user.student?

    sign_in(:user, user)
    redirect_to root_path, notice: 'Signed in as Test User (Student)'
  end

  def create_moderator
    user = User.find_or_create_by!(email: 'testmoderator@columbia.edu') do |u|
      u.password = 'password123'
      u.password_confirmation = 'password123'
      u.role = :moderator
    end
    # Force role upgrade if it was already created but possibly changed
    user.update(role: :moderator) unless user.moderator?

    sign_in(:user, user)
    redirect_to root_path, notice: 'Signed in as Test Moderator'
  end

  private

  def ensure_non_production
    raise ActionController::RoutingError, 'Not Found' unless Rails.env.development? || Rails.env.test?
  end
end