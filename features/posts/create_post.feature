Feature: Ask a new question
  As a verified student
  I want to author an anonymous question
  So that the community can help me

  Scenario: Authenticated student creates a post
    Given I register with email "student1@example.com" and password "Password123!"
    When I create a post titled "Looking for roommates" with body "Anyone searching for off-campus roommates for fall?"
    Then I should see "Post was successfully created!"
    And I should see "Looking for roommates" on the page
    And I open the post titled "Looking for roommates"
    Then I should see "Anyone searching for off-campus roommates for fall?"

  Scenario: Student sees errors when required fields are missing
    Given I register with email "student2@example.com" and password "Password123!"
    When I try to create a post without a title
    Then I should see "Title can't be blank"
    And I should see "Body can't be blank"

  Scenario: Guest must log in before accessing the post form
    When I visit the new post page without logging in
    Then I should see "LOG IN WITH UNIVERSITY SSO"

  Scenario: Author marks a post to expire in 7 days
    Given I register with email "temp@example.com" and password "Password123!"
    When I create an expiring post titled "Temporary tips" with body "This should disappear soon." that expires in 7 days
    And I open the post titled "Temporary tips"
    Then I should see "Expires" on the page

  Scenario: Composer surfaces similar threads before posting
    Given a post titled "Visa renewal tips" exists
    And I register with email "duplicate@example.com" and password "Password123!"
    When I create a post titled "Visa renewal tips" with body "Any recent ISSO advice?"
    Then I should see "Possible similar threads"
    And I should see "Visa renewal tips" on the page
