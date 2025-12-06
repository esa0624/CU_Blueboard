# CU Blue Board – Verified community. Anonymous voice.

## Team Members (Group 8)
- Chih-Hsin Chen (`cc5240`)
- Seung Jae Hong (`sh4546`)
- Mingliang Yu (`my2899`)
- Yujia Zhai (`yz5133`)

## Project Pitch
- Video: https://youtu.be/9S1olW0Fe4o
- Proposal: see `/docs/proposal.txt`

## Why CU Blueboard?

### The Problem
First-year, international, and transfer students often struggle to find reliable answers about campus life (housing, visas, courses) without revealing their identity or receiving judgment.

### Our Solution
CU Blueboard is an **anonymous Q&A platform** exclusively for verified Columbia/Barnard students, combining the safety of verified identities with the freedom of anonymous expression.

### Competitor Analysis: vs Sidechat

| Aspect | Sidechat | CU Blueboard |
|--------|----------|--------------|
| **Format** | Feed-based ephemeral chatter | Structured Q&A knowledge base with "Accepted Answers" |
| **Moderation** | AI + paid employees (generic) | AI pre-screening + Campus Staff who understand context |
| **Accountability** | Fully anonymous (hateful content lingers) | "Identity Escrow" - anonymous to peers, verified by SSO |
| **Academic Integrity** | No enforcement | Strict - redaction system + audit logs for violations |

### Addressing Key Concerns

**Q: How do you prevent hateful content from lingering like on Sidechat?**
- **AI Pre-screening**: Every post is analyzed before publishing. Toxic content is blocked immediately.
- **Identity Escrow**: Users are verified via SSO. Severe violations can be traced by administrators, creating accountability.

**Q: How do you prevent homework/quiz answers from being posted?**
1. **Prevention**: All users agree to Honor Code. Academic dishonesty = ban.
2. **Moderation**: Staff can instantly redact content (hidden but preserved for evidence).
3. **Accountability**: Immutable audit logs trace every action back to verified students.

## Prerequisites
- Ruby `3.2.2` (see `.ruby-version`)
  - Recommended: install via `rbenv` → `brew install rbenv ruby-build`, `rbenv install 3.2.2`, `rbenv local 3.2.2`
- Bundler (`gem install bundler`)
- SQLite 3 (ships with macOS/Linux)
- Google OAuth 2.0 client ID & secret configured for the CU/Barnard domains (see *Configure Google OAuth* below)
- Optional: OpenAI API Key for AI-powered content screening (see *OpenAI Moderation API* section below)

## Local Setup (clone → run app)
1. **Clone the repo** and `cd` into it.
2. Install tooling:
   ```bash
   gem install bundler
   bundle install
   ```

3. Configure Google OAuth using **one of the following methods**:

   **Option A: Environment Variables (Recommended for graders/TAs)**
   ```bash
   # Copy the example environment file and edit it
   cp example.env .env
   # Then edit .env with your Google OAuth credentials
   ```

   **Option B: Rails Credentials (Original method)**
   1. Create a Web client in Google Cloud Console and add both `http://localhost:3000/users/auth/google_oauth2/callback` and `http://127.0.0.1:3000/users/auth/google_oauth2/callback` under *Authorized redirect URIs*. (Leave "Authorized JavaScript origins" empty.)
   2. Remove the old encrypted credentials and add the new secrets:
      ```bash
      rm -f config/credentials.yml.enc
      bin/rails credentials:edit
      ```
      If you prefer a specific editor, prefix with `VISUAL="code --wait"`, `VISUAL="nano"`, `VISUAL="vim"` etc. For example, you can run `VISUAL="vim" bin/rails credentials:edit`.
      Paste the block below so Rails rewrites `config/credentials.yml.enc` and `config/master.key`:
      ```yaml
      google_oauth2:
        client_id: YOUR_CLIENT_ID
        client_secret: YOUR_CLIENT_SECRET
      ```
      Save/exit and share the regenerated `config/master.key` securely with your team. Confirm the entry with `bin/rails credentials:show`.

   **Important for OAuth Testing:**
   - If your Google Cloud project is in "Testing" mode, you must add test user emails under *APIs & Services > OAuth consent screen > Test users*
   - Alternatively, publish your app to "Production" status to allow any @columbia.edu/@barnard.edu email
4. Prepare the database:
   ```bash
   bin/rails db:prepare
   bin/rails db:seed   # seeds topics/tags for the composer/search filters
   ```
5. Run migrations (after installing the OmniAuth gems via `bundle install`, which our Gemfile already lists):
   ```bash
   bin/rails db:migrate
   ```
6. Start the app:
   ```bash
   bin/rails server
   ```
   Then visit http://localhost:3000 or http://127.0.0.1:3000.

### Default flows covered in Iteration 1
- Browse a feed of posts anonymously, including keyword search without revealing identities
- Register/log in via Devise to get a pseudonymous identity
- Create new questions with title/body validation
- Delete posts you authored with confirmation guardrails
- Reply to a post through answers and remove your own answers
- Toggle likes on posts while preventing duplicate likes per user
- Display pseudonymous handles instead of email addresses on posts and answers

### Default flows covered in Iteration 2
- Sign in with Columbia/Barnard Google accounts via OmniAuth; the callback controller enforces the domain whitelist and surfaces an “Access Denied” flash for non-campus addresses.
- Reuse existing Devise accounts by linking them to Google on the first SSO attempt (using the new `provider`/`uid` columns) or auto-provision a campus user if no record exists.
- Protect the feed by redirecting signed-out visitors to the redesigned login page via the global `authenticate_user!` hook and the authenticated/unauthenticated root split in `routes.rb`.
- Experience the refreshed login page and global header powered by `application.css` / `login.css` plus the new asset packs, replacing `simple.css` and unifying the UI.
- Generate thread-specific pseudonyms via the `ThreadIdentity` join table so every author gets a stable alias per conversation instead of a global handle.
- Reveal identities on demand: posts and answers stay anonymous by default, but authors can opt-in to showing their real email with one click, and every reveal is captured in `AuditLog` for moderator traceability.
- Mark posts as ephemeral by selecting a 7/14/30-day expiry window. Expired threads drop off the feed automatically and cannot be opened once the timer elapses.
- Structure Q&A so every reply is an answer, question authors can accept the best response, and the thread locks (with a reopen button) once solved.
- Author posts with the taxonomy-driven composer: pick an official topic, add 1-5 curated tags, capture school/course context, and open an inline draft preview before publishing.
- Filter the feed with full-text search plus topic, tag, school, course, timeframe, and status facets powered by the new `PostSearchQuery` service.
- Pivot to the “My Threads” feed from the header to see only the posts you authored, complete with empty-state messaging and support for the full filter toolbox.
- Collaborate inside threads with answer-level comments, including ownership-protected create/delete actions and comment logging for pseudonym continuity.
- Catch duplicates before publishing via the composer's "Possible similar threads" panel, powered by the new `DuplicatePostFinder` service the preview and edit forms call.
- Edit posts and answers after publishing while preserving the full revision history so classmates and moderators can trace changes; authors can see their timelines inline on the thread page.

### Default flows covered in Project Demo
- Moderate content with role-based permissions: moderators can redact posts and answers for policy violations, with transparent placeholder messages shown to general users while authors retain access to original content and appeal workflows.
- Access the moderation dashboard (`/moderation/posts`) to review redacted content, view audit trails, and restore posts after review (moderator only).
- Configure moderators via environment variable whitelist with automatic role assignment on OAuth login, eliminating manual role management.
- Screen content automatically with OpenAI Moderation API detecting violence, hate, self-harm, and harassment; authors can submit appeals for moderator review.
- AI-Flagged Post Visibility: Flagged posts are hidden from regular users in both list and detail views. Authors see their own flagged content with blur effect and "View My Content" button. Moderators see blur effect with "View the Post" button and can clear AI flags via "Clear AI Flag" button.
- Bookmark/Unbookmark Posts: Users can click the star icon (☆/★) on any post card or post detail page to bookmark or unbookmark posts for later reference.
- View Bookmarked Posts: Access all bookmarked posts via the "Bookmarks" link in the navigation header (positioned before "My Threads"), with full filter support (search, topic, tags, status, school, course, timeframe).
- Visual Feedback: Gold filled star (★) indicates bookmarked posts, empty star (☆) for unbookmarked. Hover effects show yellow highlight for bookmarking and red highlight for removing bookmarks.
- Data Model: Bookmark model with user-post associations and uniqueness constraint preventing duplicate bookmarks.
- Answer/Comment Voting System: Upvote/downvote answers and reply comments with Stack Overflow-style voting UI. Left-side compact vote buttons for answers, inline micro buttons for comments. Vote toggles work like post votes.
- Reply Comment Indentation: AnswerComments are visually indented with a left border to show comment hierarchy clearly.
- Enhanced Sample Data: 25 realistic posts, 60+ answers, 20+ reply comments with authentic college student language (slang, abbreviations) covering academics, housing, careers, wellness, and campus life topics.

### Default flows covered in Final Submission
- **Addressing Iteration 2 Feedback - School Filter Logic**: Refined `PostSearchQuery` service so posts marked as "General" appear in both Columbia and Barnard feeds, while school-specific filters correctly show only posts from that school plus General posts, verified by comprehensive RSpec tests in `spec/requests/general_school_filter_spec.rb`.
- **Addressing Iteration 2 Feedback - Multi-Tag Search Clarity**: Added interactive toggle UI on the search form allowing users to switch between "Match ANY" (OR logic - shows posts with at least one selected tag) and "Match ALL" (AND logic - shows posts with all selected tags), with visual feedback showing the active mode and defaulting to "Match ANY" for broader discovery.
- **Addressing Iteration 2 Feedback - Solved vs Locked Status Distinction**: Implemented visual distinction with different status pills (Solved in green for author-accepted answers with reopen option, Locked in red for moderator-closed threads) plus interactive tooltip icon (ℹ️) explaining who can reopen each type, eliminating confusion about thread closure authority.
- **Deduplication System**: Implemented `DuplicatePostFinder` service that detects similar questions during post creation by analyzing title and body text, displaying a "Possible similar threads" panel with links to existing discussions, prompting users to add to existing threads instead of creating duplicates, reducing redundant content across the platform.
- **Resource Sidebar**: Added static resources panel with essential campus links (Counseling \& Psychological Services, Public Safety, Student Health, Disability Services, etc.) visible throughout the application, providing quick access to critical student support services without leaving the Q\&A platform.
- **Reporting System**: Integrated user-initiated content flagging via "Flag Content" button on posts, allowing students to report policy violations, with flagged posts appearing in the moderation dashboard (`/moderation/posts`) for staff review, creating a community-driven moderation layer alongside automated AI screening.
- **Test Login for TAs/Graders**: Added two test login buttons on the login page ("Test as User" and "Test as Moderator") that instantly authenticate as pre-configured accounts (`test_student@columbia.edu` or `test_moderator@columbia.edu`) without requiring Google OAuth setup, allowing TAs to quickly test all features and verify permission boundaries between regular users and moderators, implemented via `TestSessionsController` with full RSpec and Cucumber coverage.
- **100% Test Coverage**: Achieved 100% line coverage (927/927) and 99.29% branch coverage (281/283) across both RSpec (414 examples) and Cucumber (50 scenarios, 346 steps) test suites, with comprehensive moderation scenarios covering redaction, security boundaries, and automated OpenAI content screening.


## Test Suites
```bash
# RSpec unit/request coverage
bundle exec rspec

# Cucumber executable user stories
bundle exec cucumber
```

**RSpec coverage**
- Line Coverage: 100% (927 / 927) across 414 examples, 0 failures
- Branch Coverage: 100% (283 / 283)
- `spec/models/post_spec.rb`: validations, taxonomy limits, search helper, expiration logic, and thread-identity callback.
- `spec/models/answer_spec.rb`: body validations, per-thread identities, reveal logging, and acceptance cleanup.
- `spec/models/answer_comment_spec.rb`: comment validation + thread delegation to preserve pseudonyms.
- `spec/models/post_revision_spec.rb` / `spec/models/answer_revision_spec.rb`: ensure revision history entries stay valid.
- `spec/models/like_spec.rb`: uniqueness constraint plus helper methods for liked?/find_like_by.
- `spec/models/answer_like_spec.rb`: answer voting model validations, scopes, and helper methods.
- `spec/models/answer_comment_like_spec.rb`: comment voting model validations, scopes, and helper methods.
- `spec/requests/answer_likes_spec.rb`: answer upvote/downvote endpoints with toggle behavior.
- `spec/requests/answer_comment_likes_spec.rb`: comment upvote/downvote endpoints with toggle behavior.
- `spec/models/user_spec.rb`: anonymous handle helper and OmniAuth linkage for happy/duplicate/new flows.
- `spec/requests/posts_spec.rb`: global feed filters, create/destroy, reveal identity, expiring threads, `my_threads` route, and AI-flagged post access control.
- `spec/requests/answers_spec.rb`: CRUD, validation, authorization, identity reveals, edit/revision flows, and accept/reopen flows.
- `spec/requests/answer_comments_spec.rb`: comment create/delete permissions and flash messaging.
- `spec/requests/likes_spec.rb`: like/unlike endpoints with authentication guards.
- `spec/requests/omniauth_callbacks_spec.rb`: Google SSO domain enforcement and account linking.
- `spec/helpers/application_helper_spec.rb`: `display_author` pseudonym helper.
- `spec/queries/post_search_query_spec.rb`: text/topic/status/tag/school/course/timeframe/author filters + AI-flagged filtering for moderators.
- `spec/services/duplicate_post_finder_spec.rb`: verifies the composer's duplicate-detector logic.
- `spec/models/bookmark_spec.rb`: bookmark associations, validations, uniqueness constraints, and helper methods.
- `spec/requests/bookmarks_spec.rb`: bookmark/unbookmark endpoints, bookmarked posts listing, and authentication guards.
- `spec/requests/posts_moderation_actions_spec.rb`: tests for moderator actions like clearing AI flags.
- `spec/services/redaction_service_spec.rb`: tests for redaction logic and permission checks.

- **Cucumber scenarios**
- Latest run: `bundle exec cucumber` now executes 50 scenarios / 346 steps (runs in ~2.4s) and, when followed by `bundle exec rspec`, produces 100% line/branch coverage (927/927 lines, 283/283 branches). Run `open coverage/index.html` after both suites to inspect the report.
- Reports publish to https://reports.cucumber.io by default (`CUCUMBER_PUBLISH_ENABLED=true`). Set `CUCUMBER_PUBLISH_QUIET=true` or pass `--publish-quiet` locally to silence the banner.
- `features/posts/browse_posts.feature`: authenticated browsing, advanced filters, My Threads navigation, blank-search alerts, and guest redirect to the SSO screen.
- `features/posts/create_post.feature`: signup + creation flow, validation failures, expiring threads, and draft preview UX.
- `features/answers/add_answer.feature`: answering success + validation errors plus delete permissions for owners vs. non-owners.
- `features/posts/like_post.feature`: like/unlike toggle with count updates.
- `features/posts/reveal_identity.feature`: verifies post/answer reveal buttons surface real identities and audit logs.
- `features/posts/thread_pseudonym.feature`: proves each thread shows a unique pseudonym and never leaks the answerer’s email.
- `features/posts/accept_answer.feature`: author accepts an answer, thread locks, and reopening restores the composer.
- `features/auth/google_sign_in.feature`: OmniAuth success path for campus emails and rejection for non-campus addresses.
- `features/posts/expire_posts_job.feature`: executes `ExpirePostsJob` to remove threads once their expiry window elapses.
- `features/posts/edit_post.feature`: author edits a thread, saves changes, and sees the revision history.
- `features/sad_paths.feature`: covers system failures, permission denied scenarios, and moderator action failures.

### Test Coverage

This project uses [SimpleCov](https://github.com/simplecov-ruby/simplecov) to measure test coverage. The coverage approach and configuration were adapted from **COMS W4152 hw-tdd** (Codio 8.9 CHIPS: The Acceptance Test/Unit Test Cycle).

After running both test suites, view the coverage report:

```bash
open coverage/index.html
```

**Target:** 100% statement and branch coverage
**Local test results:** Running `bundle exec cucumber` (50 scenarios / 346 steps @ ~2.4s) followed by `bundle exec rspec` yields 100% line coverage (927/927) and 100% branch coverage (283/283); run both before inspecting `coverage/index.html`.

Running the test suites will generate a detailed coverage report in `coverage/index.html`.

## Deployment
- Heroku: https://cu-blueboard-2025-e68ebfea4530.herokuapp.com
- Source code: https://github.com/esa0624/CU_Blueboard

### Environment Variables Overview

The `example.env` file contains all configurable environment variables. Copy it to `.env` for local development:

```bash
cp example.env .env
```

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_OAUTH2_CLIENT_ID` | **Yes** | Google OAuth client ID from [Google Cloud Console](https://console.cloud.google.com/apis/credentials) |
| `GOOGLE_OAUTH2_CLIENT_SECRET` | **Yes** | Google OAuth client secret |
| `OPENAI_API_KEY` | No | OpenAI API key for AI content moderation (FREE tier available) |
| `MODERATOR_EMAILS` | No | Comma-separated emails that get moderator role on login (Course Staff + Team 8 included in example.env) |
| `ALLOWED_LOGIN_EMAILS` | No | Comma-separated emails that bypass @columbia.edu/@barnard.edu domain restriction |

> **Note:** The `example.env` includes pre-configured TA and Team 8 emails for grading/testing. Replace with your own emails as needed.

### Heroku Deployment Guide

#### Initial Setup (First-time deployment)

```bash
# 1. Create Heroku app (if not already created)
heroku create your-app-name

# 2. Add PostgreSQL database
heroku addons:create heroku-postgresql:essential-0

# 3. Set Rails master key (required for credentials)
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

# 4. Set environment variables
# Google OAuth - get credentials from Google Cloud Console
heroku config:set GOOGLE_OAUTH2_CLIENT_ID=your_client_id
heroku config:set GOOGLE_OAUTH2_CLIENT_SECRET=your_client_secret

# Moderator emails - use example.env values for grading, or customize with your own
heroku config:set MODERATOR_EMAILS="your_email@columbia.edu,another@columbia.edu"

# OpenAI API key - FREE tier, required to test AI content moderation features
heroku config:set OPENAI_API_KEY=your_openai_api_key

# 5. Configure Google OAuth callback URL
#    Add this URL to Google Cloud Console > APIs & Services > Credentials > OAuth 2.0 Client
#    Under "Authorized redirect URIs":
#    https://your-app-name.herokuapp.com/users/auth/google_oauth2/callback

# 6. Deploy to Heroku
git add .
git commit -m "Prepare for Heroku deployment"
git push heroku main

# 7. Run database migrations
heroku run rails db:migrate

# 8. Seed the database (REQUIRED - creates topics and tags)
heroku run rails db:seed

# 9. Open the app
heroku open
```

#### Subsequent Deployments

```bash
git add .
git commit -m "Your commit message"
git push heroku main
heroku run rails db:migrate  # Only if migrations were added
```

#### Verify Deployment

```bash
heroku run rails deployment:check
heroku logs --tail  # View live logs
```

**Important:** If posts cannot be created (no tags available), run `heroku run rails db:seed` to populate the required taxonomy data.

## Additional Materials
- Iteration artifacts (such as proposal.txt) are stored in `/docs` as the project evolves.
- A daily `ExpirePostsJob` can be scheduled (e.g., via Heroku Scheduler or cron) to purge posts whose `expires_at` timestamp has passed.
- Seeded tag allowlist (via `TaxonomySeeder`): `academics`, `courses/coms`, `advising`, `housing`, `visas-immigration`, `financial-aid`, `mental-health`, `student-life`, `career`, `marketplace`, `accessibility-ods`, `public-safety`, `tech-support`, `international`, `resources`.

### Moderator Setup
The application supports role-based moderation with automatic role assignment via environment variables.

#### Course Staff (TAs & Instructor)
The following emails are pre-configured in `example.env` for moderator access:

| Name | Email | Role |
|------|-------|------|
| Aimee Oh | ao2686@columbia.edu | TA |
| Hailie Mitchell | hm3075@columbia.edu | TA |
| Layanne El | lae2146@columbia.edu | TA |
| Xuanming Billy Zhang | xz2995@columbia.edu | TA |
| Jenny Ma | jm5676@columbia.edu | TA |
| Junfeng Yang | jy2324@columbia.edu | Instructor |

#### Configuring Moderators
Add moderator emails to the `MODERATOR_EMAILS` environment variable (comma-separated):

**Local Development:**
```bash
# .env file (copy from example.env which includes Course Staff + Team 8 members)
cp example.env .env
```

> **Note:** The `example.env` file already includes all Course Staff (TAs + Instructor) and Team 8 members as moderators for grading and testing purposes.

**Production (Heroku):**
```bash
# Course Staff + Team 8 members (pre-configured in example.env)
heroku config:set MODERATOR_EMAILS="ao2686@columbia.edu,hm3075@columbia.edu,lae2146@columbia.edu,xz2995@columbia.edu,jm5676@columbia.edu,jy2324@columbia.edu,cc5240@columbia.edu,sh4546@columbia.edu,my2899@columbia.edu,yz5133@columbia.edu"
```

#### How It Works
- When a user signs in with Google OAuth, their email is checked against the whitelist
- If the email is in `MODERATOR_EMAILS`, they are automatically assigned the `moderator` role
- Moderators can access `/moderation/posts` to review and manage content
- Non-moderators see "Access denied" when attempting to access moderation features

#### Manual Role Assignment (Alternative)
For local development/testing, you can manually assign roles via Rails console:
```ruby
user = User.find_by(email: 'someone@columbia.edu')
user.update(role: :moderator)
```

### Allowing Non-Columbia Emails (for TA/Grader Testing)
By default, only `@columbia.edu` and `@barnard.edu` emails can log in. To allow specific non-campus emails (e.g., for TAs testing with personal Gmail accounts), use the `ALLOWED_LOGIN_EMAILS` environment variable:

**Local Development (.env file):**
```bash
# Comma-separated list of emails that bypass domain restriction
ALLOWED_LOGIN_EMAILS=ta_personal@gmail.com,grader@example.com
```

**Production (Heroku):**
```bash
heroku config:set ALLOWED_LOGIN_EMAILS="ta_personal@gmail.com,grader@example.com"
```

**How It Works:**
- Emails in `ALLOWED_LOGIN_EMAILS` skip the domain check entirely
- They can still be added to `MODERATOR_EMAILS` for moderator access
- Leave empty to only allow columbia.edu/barnard.edu emails

### OpenAI Moderation API (Automated Content Screening)
The moderation system integrates with OpenAI's Moderation API for automated content screening.

- **Model**: `omni-moderation-latest` (FREE tier available)
- **API Key Setup**: Add `OPENAI_API_KEY` to your environment:
  ```bash
  # .env file (for local development)
  OPENAI_API_KEY=your_openai_api_key_here

  # Or in Heroku
  heroku config:set OPENAI_API_KEY="your_openai_api_key_here"
  ```
- **Getting an API Key**: Visit [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys) to create a free account and generate your API key.

**Key Features:**
- Automatic AI screening on post creation detects violence, hate, self-harm, and harassment with detailed category scores displayed to moderators
- Moderator dashboard shows flagged posts with appeal system allowing authors to request human review of AI decisions

**Under Consideration:**
- Email notifications to moderators for flagged content and appeal requests

## Troubleshooting

### Posts cannot be created (no tags available)
```bash
# Run seed to create topics and tags
rails db:seed        # local
heroku run rails db:seed --app your-app-name  # Heroku
```

### Google OAuth not working
1. Verify environment variables are set:
   ```bash
   echo $GOOGLE_OAUTH2_CLIENT_ID
   echo $GOOGLE_OAUTH2_CLIENT_SECRET
   ```
2. Check redirect URIs in Google Cloud Console match your domain exactly
3. If in "Testing" mode, ensure your email is added as a Test User
4. Ensure email domain is `@columbia.edu` or `@barnard.edu`, or add your email to `ALLOWED_LOGIN_EMAILS` for non-campus testing

### Accept answer button not working
- Clear browser cache or try in incognito mode
- Check browser console for JavaScript errors
- Ensure the post is not already locked

### School filter returns empty results
- Posts require a school selection (Columbia or Barnard)
- Filtering by school only shows posts with that specific school selected

## Addressing Iteration 1 Feedback
- Added the missing user-story coverage that graders flagged (blank search alert, invalid post/answer validations, and guest redirects) so every scenario now runs via Cucumber (`features/posts/browse_posts.feature`, `features/posts/create_post.feature`, `features/answers/add_answer.feature`).
- Kept the post creation flow behind authentication and clarified the behavior in both README and acceptance tests so unauthenticated users always see the SSO screen first (`config/routes.rb`, `features/posts/create_post.feature`).
- Verified that delete buttons still show a Turbo confirmation prompt before removing posts/answers, matching the “confirmation guardrails” promise in the README (`app/views/posts/show.html.erb`).
- Trimmed optional directories (e.g., removed unused `app/mailers/`) so coverage reporting aligns with the actual code we ship and reflects the >95% combined line coverage.

## Addressing Iteration 2 Feedback

### Setup & Documentation
- **OAuth with TA emails**: Updated README with clear instructions for adding TA emails as Google OAuth test users, plus `ALLOWED_LOGIN_EMAILS` env var to bypass domain restrictions for testing.
- **Missing tags on Heroku**: Emphasized `rails db:seed` requirement in deployment guide - this creates the required topics and tags.
- **Credentials setup**: Added `example.env` with all environment variables and clear fallback system (ENV first, Rails credentials second).

### Critical Bug Fixes & UX Refinements
- **School Filter Logic**: Addressed the issue where posts with unspecified schools would disappear during filtering. Logic now ensures "General" posts are handled correctly, and specific school filters (Columbia vs. Barnard) work as expected.
- **Multi-tag Search Logic**: Implemented a user-controlled toggle to switch between "Match ANY" (OR) and "Match ALL" (AND) logic when filtering by multiple tags, allowing for both broad discovery and precise searching.
- **Status Clarity**: Added visual distinction between "Solved" (author accepted an answer) and "Locked" (moderator closed the thread), plus an interactive tooltip icon explaining the difference.

### Deployment Fixes
- Fixed Heroku deployment by ensuring `db:seed` runs after `db:migrate` to populate tags.
- Accept answer functionality now works correctly on deployed site.
- Updated deployment guide with complete step-by-step instructions including PostgreSQL addon and callback URL configuration.

## Repository Map (key folders)
```text
CU_Blueboard/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb             # Global auth hook + moderator helpers
│   │   ├── posts_controller.rb                   # Post CRUD + My Threads + revisions + bookmarks
│   │   ├── answers_controller.rb                 # Answer CRUD + revisions + accept
│   │   ├── answer_comments_controller.rb         # Answer comment create/destroy
│   │   ├── likes_controller.rb                   # Like toggle endpoints
│   │   ├── answer_likes_controller.rb            # Answer voting (upvote/downvote)
│   │   ├── answer_comment_likes_controller.rb    # Answer comment voting
│   │   ├── pages_controller.rb                   # Static pages (Honor Code, Terms)
│   │   ├── moderation/posts_controller.rb        # Moderation dashboard & redaction
│   │   ├── moderation/answers_controller.rb      # Answer redaction actions
│   │   └── users/omniauth_callbacks_controller.rb # Google SSO callback handler
│   ├── jobs/
│   │   ├── expire_posts_job.rb                   # Background cleanup for expired threads
│   │   └── screen_post_content_job.rb            # OpenAI content screening job
│   ├── queries/
│   │   └── post_search_query.rb                  # Multi-filter feed search service
│   ├── services/
│   │   ├── content_safety/
│   │   │   └── openai_client.rb                  # OpenAI Moderation API client
│   │   ├── taxonomy_seeder.rb                    # Seeds topics & tags (TaxonomySeeder)
│   │   ├── duplicate_post_finder.rb              # Composer duplicate detection
│   │   └── redaction_service.rb                  # Post/Answer redaction service
│   ├── models/
│   │   ├── post.rb                               # Post validations + taxonomy + status helpers + bookmark support
│   │   ├── post_revision.rb                      # Stores post edit history
│   │   ├── answer.rb                             # Answer validations + reveal support
│   │   ├── answer_revision.rb                    # Stores answer edit history
│   │   ├── answer_comment.rb                     # Inline comments on answers
│   │   ├── bookmark.rb                           # Bookmark model for user-post associations
│   │   ├── like.rb / thread_identity.rb / audit_log.rb
│   │   ├── answer_like.rb                        # Answer voting model
│   │   ├── answer_comment_like.rb                # Answer comment voting model
│   │   ├── tag.rb / topic.rb / post_tag.rb       # Taxonomy models
│   │   └── user.rb                               # Devise user with anonymous handle + OmniAuth + bookmarks
│   ├── views/posts/                              # Index/show/new/edit templates & shared partials
│   │   └── _revision_history.html.erb            # Shared revision list
│   ├── views/answers/edit.html.erb               # Answer edit form
│   ├── views/moderation/posts/                   # Moderation views
│   │   ├── index.html.erb                        # Moderation dashboard
│   │   └── show.html.erb                         # Post audit detail view
│   ├── views/layouts/application.html.erb        # Main layout (nav, flashes)
│   ├── helpers/application_helper.rb             # `display_author` pseudonym helper
│   └── javascript/
│       ├── controllers/post_show_controller.js   # Toggles answer form
│       └── controllers/tag_picker_controller.js  # Enforces tag selection limits
├── config/
│   ├── routes.rb                       # Devise keyword routes + nested resources
│   ├── environments/{development,test}.rb # Notes integration + Cucumber annotations
│   ├── initializers/
│   │   ├── devise.rb                    # Devise configuration
│   │   ├── moderation.rb                # Moderator whitelist ENV configuration
│   │   └── simple_form.rb               # SimpleForm theme overrides
├── db/
│   ├── migrate/                        # Devise + posts/answers/likes/topics/tags tables
│   └── schema.rb                       # Current SQLite schema
├── docs/
│   └── proposal.txt                    # Iteration proposal document
├── features/
│   ├── answers/add_answer.feature           # Answering and delete permissions
│   ├── auth/google_sign_in.feature          # Google OAuth flows (success + rejection)
│   ├── posts/accept_answer.feature          # Accept + lock + reopen threads
│   ├── posts/browse_posts.feature           # Browse/search feed + My Threads
│   ├── posts/create_post.feature            # Signup + post creation flow
│   ├── posts/expire_posts_job.feature       # ExpirePostsJob cleanup scenario
│   ├── posts/like_post.feature              # Like/unlike toggle flow
│   ├── posts/reveal_identity.feature        # Identity reveal flows
│   ├── posts/thread_pseudonym.feature       # Thread-specific pseudonym checks
│   ├── coverage/full_coverage.feature       # Coverage-driving services/controllers scenario
│   ├── posts/edit_post.feature              # Post editing + revision history
│   ├── sad_paths.feature                    # System failures & edge cases
│   ├── step_definitions/
│   │   ├── post_steps.rb                    # Shared step implementations
│   │   └── sad_path_steps.rb                # Sad path step implementations
│   └── support/
│       ├── env.rb                           # Cucumber+DatabaseCleaner/OmniAuth setup
│       └── rspec_mocks.rb                   # RSpec mocks integration
├── lib/tasks/cucumber.rake             # Rake tasks for Cucumber profiles
├── spec/
│   ├── factories/{users,posts,answers,likes,answer_likes,answer_comment_likes,answer_comments,...}.rb  # FactoryBot fixtures
│   ├── models/{post,answer,like,answer_like,answer_comment_like,user,answer_comment,...}_spec.rb        # Model specs
│   ├── requests/{posts,answers,likes,answer_likes,answer_comment_likes,answer_comments,...}_spec.rb      # Request specs
│   ├── requests/posts_failures_spec.rb                                                          # Post failure scenarios
│   ├── requests/posts_moderation_actions_spec.rb                                                # Moderator action specs
│   ├── requests/moderation/{posts,answers}_spec.rb                                              # Moderation request specs
│   ├── controllers/moderation/posts_controller_spec.rb                                          # Moderation controller specs
│   ├── controllers/users/omniauth_callbacks_controller_spec.rb                                  # OmniAuth controller specs
│   ├── controllers/pages_controller_spec.rb                                                     # Pages controller specs
│   ├── jobs/
│   │   ├── expire_posts_job_spec.rb                                                              # Expiration job specs
│   │   └── screen_post_content_job_spec.rb                                                       # OpenAI screening job specs
│   ├── services/
│   │   ├── content_safety/openai_client_spec.rb                                                  # OpenAI API client specs
│   │   ├── duplicate_post_finder_spec.rb                                                         # Composer duplicate detection
│   │   └── redaction_service_spec.rb                                                             # Redaction service specs
│   ├── helpers/application_helper_spec.rb                                                        # Helper method specs
│   ├── queries/post_search_query_spec.rb                                                         # Search service specs
│   └── rails_helper.rb                                                                           # RSpec + Devise/Test helpers config
├── simplecov_setup.rb                 # SimpleCov configuration
├── coverage/index.html                # Coverage report (generated by running tests, not in git)
├── test/application_system_test_case.rb # Stub system test base class (no tests)
├── test/system/.keep                   # Placeholder to satisfy Rails system-test task
├── test/test_helper.rb                 # Remaining Minitest harness (empty)
├── README.md                           # Iteration instructions & deliverables
├── example.env                         # Environment variables template (copy to .env)
└── Gemfile                             # Dependencies (Rails 8.1, Devise, OmniAuth, etc.)
```
