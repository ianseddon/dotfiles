# Ian's agent instructions

These are common instructions for Ian's agents across all scenarios.

## General Guidelines

* Never use the em dash "—". Use plain dash "-" instead.
* When writing commit messages, NEVER auto-add your agent name as co-author.
* Never manually modify CHANGELOG.md files or any files that are marked as auto-generated.
* When making technical decisions, do not give too much weight to development cost. 
  Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
* When fixing bugs, ALWAYS start by reproducing the bug in an E2E setting as closely aligned with how an end user would experience it.
* When end-to-end testing, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks of, even if it is not directly related to what you are doing, try to get it fixed along the way.
* Apply the same high standard to engineering excellence: particularly linting, test failures, and test flakiness.
  Follow the Boy Scout Rule and always leave the code cleaner than you found it.

