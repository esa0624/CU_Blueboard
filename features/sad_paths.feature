Feature: Handling system failures and edge cases
  As a user
  I want the system to handle errors gracefully
  So that I am informed when actions cannot be completed

  Background:
    Given a user exists with email "user@example.com" and password "Password123!"
    And I sign in with email "user@example.com" and password "Password123!"
    And a post titled "Test Post" exists

  Scenario: Reporting a post fails due to system error
    Given the next update to the post will fail
    When I visit the post titled "Test Post"
    And I click "Flag Content"
    Then I should see "Unable to flag content."

  Scenario: Bookmarking a post fails due to system error
    Given the next save to the bookmark will fail
    When I visit the post titled "Test Post"
    And I click "Bookmark"
    Then I should see "Unable to bookmark this post."

  Scenario: Revealing identity fails due to system error
    Given I own a post titled "My Post" with body "Content"
    And the next update to the post will fail
    When I reveal my identity on the post titled "My Post"
    Then I should see "Unable to reveal identity."

  Scenario: Hiding identity fails due to system error
    Given I own a post titled "My Revealed Post" with body "Content"
    And I reveal my identity on the post titled "My Revealed Post"
    And the next update to the post will fail
    When I hide my identity on the post titled "My Revealed Post"
    Then I should see "Unable to hide identity."

  Scenario: Unbookmarking a post fails due to system error
    Given I have bookmarked the post titled "Test Post"
    And the next destroy to the bookmark will fail
    When I visit the post titled "Test Post"
    And I click "Bookmarked"
    Then I should see "Unable to remove bookmark."

  Scenario: Regular user tries to access moderation page
    When I try to visit the moderation page
    Then I should see "Access denied. Moderator privileges required."
    And I should be on the home page

  Scenario: Moderator fails to clear AI flag
    Given a user exists with email "mod@example.com" and password "Password123!"
    And the user "mod@example.com" is a moderator
    And I sign out
    And I sign in with email "mod@example.com" and password "Password123!"
    And the post "Test Post" is AI flagged
    And the next update to the post will fail
    When I visit the post titled "Test Post"
    And I click "Clear AI Flag"
    Then I should see "Unable to clear AI flag."

  Scenario: Moderator fails to dismiss flag
    Given a user exists with email "mod@example.com" and password "Password123!"
    And the user "mod@example.com" is a moderator
    And I sign out
    And I sign in with email "mod@example.com" and password "Password123!"
    And the post "Test Post" is reported
    And the next update to the post will fail
    When I visit the post titled "Test Post"
    And I click "Dismiss Flag"
    Then I should see "Unable to dismiss flag."
