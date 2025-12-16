@omniauth
Feature: Sign in with Google SSO
  As a Columbia/Barnard student
  I want to authenticate with my campus Google account
  So that I can access the community without a password

  Scenario: Approved campus email completes Google login
    Given a user exists with email "lion@columbia.edu" and password "Password123!"
    And OmniAuth is mocked for "lion@columbia.edu"
    When I finish Google login
    Then I should see "Create Post"
    And I should see "My threads"

  Scenario: Non-campus email is rejected during Google login
    Given OmniAuth is mocked for "outsider@gmail.com"
    When I finish Google login
    Then I should see "Access Denied. You must use a @columbia.edu or @barnard.edu email address to log in."
    And I should see "LOG IN WITH UNIVERSITY SSO"
