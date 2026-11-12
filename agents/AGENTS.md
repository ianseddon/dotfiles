# Ian's agent instructions

These are common instructions for Ian's agents across all scenarios.

## Writing guidelines

These apply to documentation, code comments, commit and PR messages, and replies to the user.
- Write precisely in clear, complete sentences; keep text concise and proportional to task complexity.
- Stay focused: avoid filler, repetition, over-the-top detail, and tangents the user did not ask for. Once a fact is stated, do not restate it for effect ("so the commit landed on a branch nobody was going to merge"). Do not editorialise.
- Always prefer ISO 24495-1:2023 conformant plain language over dense technical jargon: short sentences, one idea per sentence, define terms on first use.
- When reporting your own mistake, give the cause and the fix in one sentence each; no apology, no framing ("the mistake was mine"), no post-mortem.
- Never use em dashes or cataphoric teasers such as "Here's the thing" or "But there's a catch".
- When writing commit messages, NEVER auto-add your agent name as co-author.

## General Guidelines

* Never manually modify CHANGELOG.md files or any files that are marked as auto-generated.
* When making technical decisions, do not give too much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
* When fixing bugs, ALWAYS start by reproducing the bug in an E2E setting as closely aligned with how an end user would experience it.
* When end-to-end testing, be picky about the UI you see and be obsessed with pixel perfection. If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
* Apply the same high standard to engineering excellence: particularly linting, test failures, and test flakiness. Follow the Boy Scout Rule and always leave the code cleaner than you found it.

