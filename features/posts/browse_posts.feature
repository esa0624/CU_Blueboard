Feature: Browse campus conversations
  As a Columbia/Barnard student
  I want to see recent questions and conversations after logging in
  So that the feed stays limited to verified peers

  Background:
    Given the following posts exist:
      | title                 | body                                             |
      | Housing after finals  | Does anyone have tips for summer sublets?        |
      | Visa renewal clinic   | What documents should I prepare for ISSO visits? |

  Scenario: Viewing recent posts on the homepage
    Given a user exists with email "reader@example.com" and password "Password123!"
    And I sign in with email "reader@example.com" and password "Password123!"
    When I visit the home page
    Then I should see "Housing after finals" in the posts list
    And I should see "Visa renewal clinic" in the posts list

  Scenario: Searching filters posts without leaking identities
    Given a user exists with email "searcher@example.com" and password "Password123!"
    And I sign in with email "searcher@example.com" and password "Password123!"
    When I search for "visa"
    Then I should see "Visa renewal clinic" in the posts list
    And I should not see "Housing after finals" in the posts list
    And the posts list should not reveal email addresses

  Scenario: Submitting an empty search shows a helpful alert
    Given a user exists with email "blanksearch@example.com" and password "Password123!"
    And I sign in with email "blanksearch@example.com" and password "Password123!"
    When I submit an empty search
    Then I should see the alert "Please enter text to search or choose a filter."

  Scenario: Guest visitors are asked to log in first
    When I visit the home page
    Then I should see "LOG IN WITH UNIVERSITY SSO"

  Scenario: Expired posts are hidden from the feed
    Given a user exists with email "active@example.com" and password "Password123!"
    And an expired post titled "Old roommates" exists
    And I sign in with email "active@example.com" and password "Password123!"
    When I visit the home page
    Then I should not see "Old roommates" in the posts list

  Scenario: Viewing only my threads from the header
    Given I register with email "creator@example.com" and password "Password123!"
    And I create a post titled "My roommate search" with body "Looking for two roommates near campus."
    And I sign out
    And a user exists with email "neighbor@example.com" and password "Password123!"
    And I sign in with email "neighbor@example.com" and password "Password123!"
    And I create a post titled "General housing tips" with body "Check the leasing portal weekly."
    And I sign out
    And I sign in with email "creator@example.com" and password "Password123!"
    When I open My Threads
    Then I should see "My roommate search" in the posts list
    And I should not see "General housing tips" in the posts list
    And I should see "My Threads" on the page

  Scenario: My Threads shows an empty state when no posts exist
    Given a user exists with email "newbie@example.com" and password "Password123!"
    And I sign in with email "newbie@example.com" and password "Password123!"
    When I open My Threads
    Then I should see "You have not created any threads yet." on the page
