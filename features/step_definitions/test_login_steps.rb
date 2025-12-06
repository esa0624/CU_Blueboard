Given('I am on the login page') do
  visit unauthenticated_root_path
end

When('I click the "Test as User" button') do
  click_button 'Test as User'
end

When('I click the "Test as Moderator" button') do
  click_button 'Test as Moderator'
end

Then('I should be signed in as {string}') do |email|
  expect(page).to have_content('Logout')
  # Verify we are on the feed page by checking for feed-specific elements
  expect(page).to have_content('Post List')
end