Feature: Updating posts
  As a post author
  I want to edit my posts
  So I can keep the content accurate

  Background:
    Given I own a post titled "My Original Post" with body "Original content here"

  Scenario: Author updates post body
    When I edit the post titled "My Original Post" to have body "Updated content here"
    Then I should see "Post updated."
    And I should see "Updated content here"

  Scenario: Viewing revision history after edit
    When I edit the post titled "My Original Post" to have body "First edit"
    And I edit the post titled "My Original Post" to have body "Second edit"
    Then I should see "Revision history"
