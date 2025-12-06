Feature: Automatically clean up expired posts
  As a moderator maintaining the feed
  I want expired threads removed automatically
  So that students only see active questions

  Scenario: ExpirePostsJob deletes posts past their deadline
    Given I register with email "expiretest@example.com" and password "Password123!"
    And I create a post titled "Temporary checklist" with body "This guidance will be outdated soon."
    And the post "Temporary checklist" expired 1 days ago
    When the expire posts job runs
    And I visit the home page
    Then I should not see "Temporary checklist" in the posts list
