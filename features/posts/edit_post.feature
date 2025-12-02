Feature: Edit an existing thread
  As the author of a thread
  I want to revise my post later
  So that I can keep guidance up to date while preserving history

  Scenario: Author edits a post and sees the revision history
    Given I own a post titled "Need housing advice" with body "Any sublets available?"
    When I edit the post titled "Need housing advice" to have body "Found a place but leaving tips."
    Then I should see "Post updated."
    And I should see "Revision history" on the page
