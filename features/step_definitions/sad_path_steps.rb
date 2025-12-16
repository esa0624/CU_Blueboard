Given('the next update to the post will fail') do
  login_as(User.find_by(email: @current_user_email), scope: :user) if defined?(@current_user_email) && @current_user_email
  allow_any_instance_of(Post).to receive(:update).and_return(false)
end

Given('the next save to the bookmark will fail') do
  login_as(User.find_by(email: @current_user_email), scope: :user) if defined?(@current_user_email) && @current_user_email
  allow_any_instance_of(Bookmark).to receive(:save).and_return(false)
end

Given('the next destroy to the bookmark will fail') do
  login_as(User.find_by(email: @current_user_email), scope: :user) if defined?(@current_user_email) && @current_user_email
  allow_any_instance_of(Bookmark).to receive(:destroy).and_return(false)
end

Given('the next save to the report will fail') do
  login_as(User.find_by(email: @current_user_email), scope: :user) if defined?(@current_user_email) && @current_user_email
  allow_any_instance_of(PostReport).to receive(:save).and_return(false)
end

Given('I click {string}') do |link_or_button|
  if link_or_button == 'Bookmark'
    find('.btn-bookmark-inline', text: 'Bookmark').click
  elsif link_or_button == 'Bookmarked'
    find('.btn-bookmark-inline', text: 'Bookmarked').click
  elsif link_or_button == 'Flag Content'
    # Report dropdown requires JS to toggle, so submit form directly
    post = Post.order(created_at: :desc).first
    page.driver.submit :post,
      Rails.application.routes.url_helpers.report_post_path(post),
      { reason: 'inappropriate' }
  else
    click_on link_or_button
  end
end

Given('I have bookmarked the post titled {string}') do |title|
  post = Post.find_by!(title: title)
  user = User.find_by!(email: @current_user_email)
  Bookmark.create!(user: user, post: post)
end

When('I hide my identity on the post titled {string}') do |title|
  post = Post.find_by!(title: title)
  visit Rails.application.routes.url_helpers.post_path(post)
  click_button 'Hide Identity'
end

When('I try to visit the moderation page') do
  visit '/moderation/posts'
end

Then('I should be on the home page') do
  expect(current_path).to eq('/')
end

Given('the user {string} is a moderator') do |email|
  user = User.find_by!(email: email)
  user.update!(role: :moderator)
end

Given('the post {string} is AI flagged') do |title|
  post = Post.find_by!(title: title)
  post.update!(ai_flagged: true)
end

Given('the post {string} is reported') do |title|
  post = Post.find_by!(title: title)
  # Create actual PostReport record so reports_count > 0 for moderation dashboard
  reporter = create(:user)
  create(:post_report, user: reporter, post: post, reason: 'inappropriate')
  post.update!(reported: true, reported_at: Time.current)
end
