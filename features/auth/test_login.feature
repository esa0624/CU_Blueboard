Feature: Test Login
  As a developer or tester
  I want to be able to login as a test user or moderator quickly
  So that I can verify functionality without setting up OAuth

  Scenario: Logging in as a test student
    Given I am on the login page
    When I click the "Test as User" button
    Then I should be signed in as "testuser@columbia.edu"
    And I should see "Signed in as Test User (Student)"

  Scenario: Logging in as a test moderator
    Given I am on the login page
    When I click the "Test as Moderator" button
    Then I should be signed in as "testmoderator@columbia.edu"
    And I should see "Signed in as Test Moderator"
