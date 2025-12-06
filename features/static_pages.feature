Feature: Static Pages
  As a user
  I want to view the static pages
  So that I can understand the site's policies

  Scenario: Viewing the Honor Code
    Given I am on the login page
    When I click the header link "Honor Code"
    Then I should see "Honor Code"

  Scenario: Viewing the Terms
    Given I am on the login page
    When I click the header link "Terms"
    Then I should see "Terms of Service"