@coverage_db_truncation
Feature: Cucumber coverage parity
  As a maintainer
  I want our cucumber suite to exercise backend code paths
  So that coverage reflects the behaviour we already verify in specs

  Scenario: Exercising model and service helpers
    When I run the model coverage checks
    And I run the service coverage checks

  Scenario: Exercising controller endpoints
    When I run the controller coverage checks
