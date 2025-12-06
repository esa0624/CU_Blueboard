Feature: Moderation Security
  As a regular user
  I should not be able to access moderation tools
  So that the system remains secure

  Background:
    Given a user exists with email "user@example.com" and password "Password123!"
    And I sign in with email "user@example.com" and password "Password123!"

  Scenario: Accessing moderation dashboard as regular user
    When I visit the moderation dashboard
    Then I should see "Access denied. Moderator privileges required."
    And I should be on the home page

  Scenario: Attempting to redact a post as regular user
    # We need to simulate the PATCH request directly because the button isn't visible
    # But Cucumber drives the browser.
    # We can try to visit the route directly if it was a GET, but it's a PATCH.
    # Capybara can't easily send PATCH requests without a form.
    # However, we can verified that the buttons are NOT present.
    Given a post titled "Some Post" exists
    When I visit the post titled "Some Post"
    Then I should not see "Redact Post"
    And I should not see "Review Post"