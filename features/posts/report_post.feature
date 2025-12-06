Feature: Reporting posts
  As a student
  I want to report inappropriate content
  So that moderators can review it

  Background:
    Given a user exists with email "reporter@example.com" and password "Password123!"
    And I sign in with email "reporter@example.com" and password "Password123!"
    And a post titled "Questionable Post" exists

  Scenario: Student flags a post for review
    When I visit the post titled "Questionable Post"
    And I click "Flag Content"
    Then I should see "Content flagged for moderator review."

  Scenario: Moderator dismisses a reported post
    Given a user exists with email "mod@columbia.edu" and password "Password123!"
    And the user "mod@columbia.edu" is a moderator
    And the post "Questionable Post" is reported
    And I sign out
    And I sign in with email "mod@columbia.edu" and password "Password123!"
    When I visit the post titled "Questionable Post"
    And I click "Dismiss Flag"
    Then I should see "Flag dismissed."
