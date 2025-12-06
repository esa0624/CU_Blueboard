Feature: Voting
  As a student
  I want to upvote or downvote answers and comments
  So that I can help curate the best content

  Background:
    Given a user exists with email "voter@example.com" and password "Password123!"
    And I sign in with email "voter@example.com" and password "Password123!"
    And a post titled "Question 1" exists
    And I visit the post titled "Question 1"
    And I leave an answer "Helpful answer"

  Scenario: Upvoting an answer
    When I click the upvote button on the answer "Helpful answer"
    Then I should see the answer "Helpful answer" has 1 upvote

  Scenario: Downvoting an answer
    When I click the downvote button on the answer "Helpful answer"
    Then I should see the answer "Helpful answer" has 1 downvote

  Scenario: Upvoting a comment
    When I comment "Helpful comment" on the most recent answer
    And I click the upvote button on the comment "Helpful comment"
    Then I should see the comment "Helpful comment" has 1 upvote
