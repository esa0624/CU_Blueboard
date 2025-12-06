Feature: Appreciate helpful posts
  As a verified student
  I want to upvote useful threads
  So that the best guidance surfaces quickly

  Background:
    Given a post titled "Campus housing tips" exists

  Scenario: Student likes and unlikes a post
    Given I register with email "fan@example.com" and password "Password123!"
    When I visit the post titled "Campus housing tips"
    And I like the post
    Then the post like count should be 1
    When I unlike the post
    Then the post like count should be 0

  Scenario: Student downvotes a post
    Given I register with email "critic@example.com" and password "Password123!"
    When I visit the post titled "Campus housing tips"
    And I downvote the post
    Then the post should show a downvote

  Scenario: Student switches from upvote to downvote
    Given I register with email "voter@example.com" and password "Password123!"
    When I visit the post titled "Campus housing tips"
    And I like the post
    And I downvote the post
    Then the post should show a downvote

  Scenario: Student switches from downvote to upvote
    Given I register with email "switcher@example.com" and password "Password123!"
    When I visit the post titled "Campus housing tips"
    And I downvote the post
    And I like the post
    Then the post like count should be 1
