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

  Scenario: Toggling upvote on answer removes it
    When I click the upvote button on the answer "Helpful answer"
    And I click the upvote button on the answer "Helpful answer"
    Then I should see the answer "Helpful answer" has 0 upvote

  Scenario: Switching from upvote to downvote on answer
    When I click the upvote button on the answer "Helpful answer"
    And I click the downvote button on the answer "Helpful answer"
    Then I should see the answer "Helpful answer" has 1 downvote

  Scenario: Switching from downvote to upvote on answer
    When I click the downvote button on the answer "Helpful answer"
    And I click the upvote button on the answer "Helpful answer"
    Then I should see the answer "Helpful answer" has 1 upvote

  Scenario: Upvoting a comment
    When I comment "Helpful comment" on the most recent answer
    And I click the upvote button on the comment "Helpful comment"
    Then I should see the comment "Helpful comment" has 1 upvote

  Scenario: Downvoting a comment
    When I comment "Not helpful" on the most recent answer
    And I click the downvote button on the comment "Not helpful"
    Then I should see the comment "Not helpful" has 1 downvote

  Scenario: Toggling upvote on comment removes it
    When I comment "Good point" on the most recent answer
    And I click the upvote button on the comment "Good point"
    And I click the upvote button on the comment "Good point"
    Then I should see the comment "Good point" has 0 upvote

  Scenario: Switching from upvote to downvote on comment
    When I comment "Interesting" on the most recent answer
    And I click the upvote button on the comment "Interesting"
    And I click the downvote button on the comment "Interesting"
    Then I should see the comment "Interesting" has 1 downvote