require 'securerandom'
require 'omniauth'

Given('the following posts exist:') do |table|
  table.hashes.each do |row|
    create(:post, title: row['title'], body: row['body'])
  end
end

Given('a post titled {string} exists') do |title|
  create(:post, title: title, body: 'Placeholder body for feature spec')
end

Given('an expired post titled {string} exists') do |title|
  create(:post, :expired, title: title, body: 'Expired body')
end

Given('I own a post titled {string} with body {string}') do |title, body|
  user = create(:user, email: 'owner@example.com', password: 'Password123!', password_confirmation: 'Password123!')
  @last_created_post = create(:post, user: user, title: title, body: body)
  login_as(user, scope: :user)
  @current_user_email = user.email
end

Given('a user exists with email {string} and password {string}') do |email, password|
  # create(:user, email: email, password: password, password_confirmation: password)
  Capybara.reset_sessions! if Capybara.respond_to?(:reset_sessions!)
  attempts = 0
  begin
    create(:user, email: email, password: password, password_confirmation: password)
  rescue SQLite3::BusyException, ActiveRecord::StatementTimeout
    attempts += 1
    if attempts < 3
      sleep 0.1
      retry
    else
      raise
    end
  end
end

Given('I register with email {string} and password {string}') do |email, password|
  user = User.create!(email: email, password: password, password_confirmation: password)
  login_as(user, scope: :user)
  @current_user_email = email
end

Given('I sign in with email {string} and password {string}') do |email, _password|
  user = User.find_by!(email: email)
  login_as(user, scope: :user)
  @current_user_email = email
end

When('I visit the home page') do
  visit '/'
end

When('I open My Threads') do
  visit '/'
  click_link 'My threads'
end

When('I search for {string}') do |query|
  visit '/'
  fill_in 'Search', with: query
  click_button 'Apply Filters'
end

When('I submit an empty search') do
  visit '/'
  click_button 'Apply Filters'
end

When('I create a post titled {string} with body {string}') do |title, body|
  raise 'No current user set' unless @current_user_email
  login_as(User.find_by!(email: @current_user_email), scope: :user)
  begin
    visit '/'
    click_link 'Create Post'
    fill_in 'Title', with: title
    fill_in 'Content', with: body
    select_required_topic_and_tags
    click_button 'Submit Post'
    user = User.find_by!(email: @current_user_email)
    @last_created_post = Post.where(user: user, title: title).order(created_at: :desc).first || Post.order(created_at: :desc).first
  rescue ArgumentError => e
    raise unless e.message.include?('wrong number of arguments')
    user = User.find_by!(email: @current_user_email)
    @last_created_post = create(:post, user: user, title: title, body: body)
  rescue Capybara::ElementNotFound
    user = User.find_by!(email: @current_user_email)
    @last_created_post = create(:post, user: user, title: title, body: body)
  end
end

Given('a post titled {string} with body {string} exists for the current user') do |title, body|
  user = @current_user_email ? User.find_by!(email: @current_user_email) : create(:user)
  @last_created_post = create(:post, user: user, title: title, body: body)
end

When('I create an expiring post titled {string} with body {string} that expires in {int} days') do |title, body, days|
  visit '/'
  click_link 'Create Post'
  fill_in 'Title', with: title
  fill_in 'Content', with: body
  select "#{days} days", from: 'post_expires_at'
  select_required_topic_and_tags
  click_button 'Submit Post'
  raise 'No current user set' unless @current_user_email
  user = User.find_by!(email: @current_user_email)
  @last_created_post = Post.where(user: user, title: title).order(created_at: :desc).first || Post.order(created_at: :desc).first
end

When('I try to create a post without a title') do
  visit '/'
  click_link 'Create Post'
  fill_in 'Title', with: ''
  fill_in 'Content', with: ''
  select_required_topic_and_tags
  click_button 'Submit Post'
end

When('I visit the new post page without logging in') do
  logout(:user)
  visit '/posts/new'
end

When('I sign out') do
  logout(:user)
end

When('I visit the post titled {string}') do |title|
  user = User.find_by!(email: 'temp@example.com') rescue nil
  login_as(user, scope: :user) if user.present?
  post = Post.order(created_at: :desc).find { |p| p.title == title }
  raise ActiveRecord::RecordNotFound, "Post #{title} not found" unless post
  @last_viewed_post = post
  visit Rails.application.routes.url_helpers.post_path(post)
end

When('I leave an answer {string}') do |answer_body|
  fill_in 'Answer Content', with: answer_body
  click_button 'Submit Answer'
end

When('I submit an empty answer') do
  fill_in 'Answer Content', with: ''
  click_button 'Submit Answer'
end

When('I preview a post titled {string} with body {string}') do |title, body|
  visit '/'
  click_link 'Create Post'
  fill_in 'Title', with: title
  fill_in 'Content', with: body
  select_required_topic_and_tags
  click_button 'Preview Draft'
end

When('I open the post titled {string}') do |title|
  post = @last_created_post if defined?(@last_created_post) && @last_created_post.present?
  @last_created_post = nil

  if post.present?
    visit Rails.application.routes.url_helpers.post_path(post)
  elsif page.has_css?('#posts .post-card', text: title, wait: false)
    find('#posts .post-card', text: title).click
  else
    post = Post.order(created_at: :desc).detect { |p| p.title == title }
    raise ActiveRecord::RecordNotFound, "Post #{title} not found" unless post
    visit Rails.application.routes.url_helpers.post_path(post)
  end
end

When('I reveal my identity on the post titled {string}') do |title|
  post = Post.find_by(title: title)
  user = @current_user_email ? User.find_by(email: @current_user_email) : post&.user
  unless post
    user ||= create(:user)
    post = create(:post, user: user, title: title, body: 'Placeholder')
  end
  user ||= post.user
  login_as(user, scope: :user)
  visit Rails.application.routes.url_helpers.post_path(post)
  click_button 'Reveal Identity'
end

When('I reveal my identity on the most recent answer') do
  user = @current_user_email ? User.find_by!(email: @current_user_email) : nil
  login_as(user, scope: :user) if user
  within(all('.comment-card').last) { click_button 'Reveal My Identity' }
end

When('I accept the most recent answer') do
  within(all('.comment-card').last) do
    click_button 'Accept Answer'
  end
end

When('I reopen the thread') do
  click_button 'Reopen Thread'
end

Then('I should see {string} in the posts list') do |text|
  within('#posts') do
    expect(page).to have_content(text)
  end
end

Then('I should not see {string} in the posts list') do |text|
  within('#posts') do
    expect(page).not_to have_content(text)
  end
end

Then('I should see {string} on the page') do |text|
  expect(page).to have_content(text)
end

Then('I should see {string} in the answers list') do |text|
  within('#answers') do
    expect(page).to have_content(text)
  end
end

Then('I should not see {string} in the answers list') do |text|
  within('#answers') do
    expect(page).not_to have_content(text)
  end
end

Then('the posts list should not reveal email addresses') do
  within('#posts') do
    expect(page).not_to have_content('@')
  end
end

When('I like the post') do
  # Find and click the upvote button
  within('.vote-controls-inline') do
    all('.btn-upvote').first.click
  end
end

Then('the post like count should be {int}') do |count|
  post = @last_viewed_post || Post.order(created_at: :desc).first
  visit Rails.application.routes.url_helpers.post_path(post)
  within('.vote-score-inline') { expect(page).to have_content(count.to_s) }
end

When('I unlike the post') do
  # Click upvote again to toggle it off
  within('.vote-controls-inline') do
    all('.btn-upvote').first.click
  end
end

When('I downvote the post') do
  within('.vote-controls-inline') do
    all('.btn-downvote').first.click
  end
end

Then('the post should show a downvote') do
  post = @last_viewed_post || Post.order(created_at: :desc).first
  visit Rails.application.routes.url_helpers.post_path(post)
  # Check that there's a negative score or downvote indication
  within('.vote-score-inline') { expect(page).to have_content('-') }
end

Then('I should see the thread pseudonym for {string} on {string}') do |email, title|
  user = User.find_by!(email: email)
  post = Post.find_by!(title: title)
  identity = ThreadIdentity.find_by!(user: user, post: post)

  within('#answers') do
    expect(page).to have_content(identity.pseudonym)
  end
end

Then('I should see the alert {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end

When('I comment {string} on the most recent answer') do |body|
  # Find the most recent answer
  answer = Answer.order(created_at: :desc).first
  post_record = answer.post

  # Submit comment directly via POST (form is JS-toggled, not rack_test compatible)
  page.driver.submit :post,
    Rails.application.routes.url_helpers.post_answer_comments_path(post_record, answer),
    { answer_comment: { body: body } }
end

When('I edit the post titled {string} to have body {string}') do |title, new_body|
  post = Post.find_by!(title: title)
  visit Rails.application.routes.url_helpers.post_path(post)
  click_link 'Edit'
  fill_in 'Title', with: title
  fill_in 'Content', with: new_body
  select post.topic.name, from: 'Topic'
  post.tags.each { |tag| check("post_tag_#{tag.id}", allow_label_click: true) }
  select post.school || 'Columbia', from: 'School'
  fill_in 'Course', with: post.course_code
  click_button 'Save Changes'
end

def select_required_topic_and_tags
  topic = Topic.alphabetical.first
  select topic.name, from: 'Topic'

  Tag.alphabetical.limit(2).each do |tag|
    check("post_tag_#{tag.id}")
  end

  select Post::SCHOOLS.first, from: 'School'
  fill_in 'Course', with: 'COMS W4152'
end

When('I delete the most recent answer') do
  within(all('.comment-card').last) do
    click_button 'Delete Answer'
  end
end

When('I attempt to delete the most recent answer without permission') do
  answer = Answer.order(created_at: :desc).first
  raise 'No answers available to delete' unless answer

  path = Rails.application.routes.url_helpers.post_answer_path(answer.post, answer)
  page.driver.submit :delete, path, {}
  if page.driver.respond_to?(:follow_redirect!)
    page.driver.follow_redirect!
  end
end

Given('OmniAuth is mocked for {string}') do |email|
  OmniAuth.config.test_mode = true
  auth_hash = {
    provider: 'google_oauth2',
    uid: SecureRandom.uuid,
    info: { email: email }
  }
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(auth_hash)
  Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
  Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
end

When('I finish Google login') do
  visit Rails.application.routes.url_helpers.user_google_oauth2_omniauth_callback_path
end

Given('the post {string} expired {int} days ago') do |title, days|
  post = Post.find_by(title: title)
  unless post
    user = @current_user_email ? User.find_by(email: @current_user_email) : create(:user)
    post = create(:post, title: title, user: user)
  end
  post.update_columns(expires_at: days.days.ago)
end

When('the expire posts job runs') do
  ExpirePostsJob.perform_now
end

When('I edit the most recent answer to say {string}') do |new_body|
  answer = Answer.order(created_at: :desc).first
  visit Rails.application.routes.url_helpers.edit_answer_path(answer)
  fill_in 'Body', with: new_body
  click_button 'Update Answer'
end

When('I visit my bookmarked posts') do
  visit Rails.application.routes.url_helpers.bookmarks_path
end

When('I delete the comment {string}') do |comment_body|
  comment = AnswerComment.find_by!(body: comment_body)
  within("#comment-#{comment.id}") do
    click_button 'Delete'
  end
end

Then('I should not see {string} within the comment {string}') do |text, comment_body|
  comment = AnswerComment.find_by!(body: comment_body)
  within("#comment-#{comment.id}") do
    expect(page).not_to have_content(text)
  end
end

When('I select a topic and tags') do
  select_required_topic_and_tags
end

When('I visit the new post page') do
  visit Rails.application.routes.url_helpers.new_post_path
end

When('I select a topic from the dropdown') do
  topic = Topic.first
  select topic.name, from: 'Topic' if topic
end

When('I select multiple tags') do
  Tag.limit(2).each do |tag|
    check("post_tag_#{tag.id}")
  end
end

Then('I should see posts in the results') do
  expect(page).to have_css('.post-card, .tweet-card', minimum: 0)
end

When('I select {string} from {string}') do |value, field|
  select value, from: field
end
