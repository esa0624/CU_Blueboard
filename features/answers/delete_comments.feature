Feature: Deleting comments
  As a comment author
  I want to delete my comments
  So that I can remove content I no longer want visible

  Background:
    Given a user exists with email "commenter@example.com" and password "Password123!"
    And I sign in with email "commenter@example.com" and password "Password123!"
    And a post titled "Discussion Post" exists
    And I visit the post titled "Discussion Post"
    And I leave an answer "My answer here"
    And I comment "My comment here" on the most recent answer

  Scenario: Author deletes their own comment
    When I delete the comment "My comment here"
    Then I should see "Comment deleted."
    And I should not see "My comment here"

  Scenario: Non-author cannot delete someone else's comment
    Given a user exists with email "other@example.com" and password "Password123!"
    And I sign out
    And I sign in with email "other@example.com" and password "Password123!"
    When I visit the post titled "Discussion Post"
    Then I should not see "Delete" within the comment "My comment here"
