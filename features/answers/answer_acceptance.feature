Feature: Answer acceptance and reopening
  As a question author
  I want to accept the best answer and manage the thread state
  So that the community knows which solution worked

  Background:
    Given a user exists with email "asker@example.com" and password "Password123!"
    And a user exists with email "answerer@example.com" and password "Password123!"
    And I sign in with email "asker@example.com" and password "Password123!"
    And I create a post titled "Need help" with body "How do I solve this?"
    And I sign out
    And I sign in with email "answerer@example.com" and password "Password123!"
    And I visit the post titled "Need help"
    And I leave an answer "Try this solution"

  Scenario: Author accepts an answer and locks the thread
    Given I sign out
    And I sign in with email "asker@example.com" and password "Password123!"
    When I visit the post titled "Need help"
    And I accept the most recent answer
    Then I should see "Thread locked after accepting an answer."
    And I should see "Accepted answer"

  Scenario: Author reopens a locked thread
    Given I sign out
    And I sign in with email "asker@example.com" and password "Password123!"
    When I visit the post titled "Need help"
    And I accept the most recent answer
    And I reopen the thread
    Then I should see "Share Your Answer"
