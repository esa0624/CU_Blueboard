Feature: Moderation
  As a moderator
  I want to review and manage content
  So that the community remains safe

  Background:
    Given a user exists with email "mod@columbia.edu" and password "Password123!"
    And the user "mod@columbia.edu" is a moderator
    And I sign in with email "mod@columbia.edu" and password "Password123!"
    And a post titled "Inappropriate Post" exists
    And I visit the post titled "Inappropriate Post"
    And I leave an answer "Bad answer"
    And the post "Inappropriate Post" is reported

  Scenario: Viewing the moderation dashboard
    When I visit the moderation dashboard
    Then I should see "Moderation Dashboard"
    And I should see "Inappropriate Post"

  Scenario: Redacting a post
    When I visit the moderation dashboard
    And I click "Review" for the post "Inappropriate Post"
    And I click "Redact Post"
    Then I should see "Post has been redacted."

  Scenario: Redacting an answer
    When I visit the post titled "Inappropriate Post"
    And I click "Redact Answer" for the answer "Bad answer"
    Then I should see "Answer has been redacted."