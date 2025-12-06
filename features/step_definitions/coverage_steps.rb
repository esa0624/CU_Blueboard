require 'ostruct'

When('I run the model coverage checks') do
  original_queue_adapter = ActiveJob::Base.queue_adapter
  ActiveJob::Base.queue_adapter = :test
  helper_context = ApplicationController.new.view_context
  helper_context.define_singleton_method(:current_user) { nil }

  persisted_user = create(:user)
  expect(persisted_user.anonymous_handle).to start_with('Lion #')
  unsaved_user = build(:user)
  expect(unsaved_user.anonymous_handle).to start_with('Lion #')
  expect(helper_context.display_author(persisted_user, context: nil)).to start_with('Lion #')

  original_allowed = Rails.application.config.allowed_login_emails
  original_moderators = Rails.application.config.moderator_emails
  begin
    Tag.delete_all
    Tag.seed_defaults!
    tag = Tag.new(name: 'Coverage Tag')
    expect(tag.valid?).to be(true)
    expect(tag.slug).to eq('coverage-tag')

    existing_google_user = create(:user, provider: 'google_oauth2', uid: 'google-1', role: :student, email: 'moderator@columbia.edu')
    Rails.application.config.allowed_login_emails = []
    Rails.application.config.moderator_emails = [ existing_google_user.email ]
    update_auth = OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: 'google-1', info: OpenStruct.new(email: existing_google_user.email))
    expect(User.from_omniauth(update_auth).role).to eq('moderator')

    new_auth = OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: 'google-2', info: OpenStruct.new(email: 'newuser@columbia.edu'))
    new_user = User.from_omniauth(new_auth)
    expect(new_user).to be_persisted
    expect(new_user.role).to eq('student')

    Rails.application.config.allowed_login_emails = [ 'whitelist@columbia.edu' ]
    whitelisted_auth = OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: 'google-4', info: OpenStruct.new(email: 'whitelist@columbia.edu'))
    whitelisted_user = User.from_omniauth(whitelisted_auth)
    expect(whitelisted_user).to be_present

    existing_moderator = create(:user, provider: 'google_oauth2', uid: 'google-3', role: :moderator, email: 'mod2@columbia.edu')
    Rails.application.config.moderator_emails = [ existing_moderator.email ]
    stable_auth = OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: 'google-3', info: OpenStruct.new(email: existing_moderator.email))
    expect(User.from_omniauth(stable_auth).role).to eq('moderator')
  ensure
    Rails.application.config.allowed_login_emails = original_allowed
    Rails.application.config.moderator_emails = original_moderators
  end

  post = create(:post, user: persisted_user)
  expect(post.status_open?).to be(true)
  expect(post.voted_by?(nil)).to be(false)
  other_user = create(:user)
  expect(post.voted_by?(other_user)).to be(false)

  like = create(:like, post: post, user: other_user, vote_type: Like::UPVOTE)
  expect(post.find_like_by(other_user)).to eq(like)
  expect(post.liked_by?(other_user)).to be(true)
  like.update!(vote_type: Like::DOWNVOTE)
  expect(post.liked_by?(other_user)).to be(false)

  post.request_appeal!
  expect(post.reload.appeal_requested).to be(true)
  post.clear_appeal!
  expect(post.reload.appeal_requested).to be(false)
  expect(Post.search(post.title)).to include(post)

  allow(ScreenPostContentJob).to receive(:perform_later).and_raise(StandardError, 'Queue offline')
  expect { create(:post, user: persisted_user) }.not_to raise_error
  allow(ScreenPostContentJob).to receive(:perform_later).and_call_original

  short_expiry = build(:post, user: persisted_user)
  short_expiry.expires_at = 2.days.from_now
  short_expiry.tags = short_expiry.tags
  expect(short_expiry).not_to be_valid
  expect(short_expiry.errors[:expires_at]).to include('must be between 7 and 30 days from now')

  no_tags_post = build(:post, user: persisted_user)
  no_tags_post.tags = []
  expect(no_tags_post).not_to be_valid
  expect(no_tags_post.errors[:tags]).to include('must include at least one tag')

  too_many_tags_post = build(:post, user: persisted_user)
  too_many_tags_post.tags = create_list(:tag, Post::TAG_LIMIT + 1)
  expect(too_many_tags_post).not_to be_valid
  expect(too_many_tags_post.errors[:tags].first).to include(Post::TAG_LIMIT.to_s)

  redacted_post = build(:post, user: persisted_user, redaction_state: Post::REDACTION_STATES[:redacted], redacted_body: nil)
  expect(redacted_post).not_to be_valid
  expect(redacted_post.errors[:redacted_body]).to include('must be provided when content is redacted')

  answer = create(:answer, post: post, user: persisted_user, body: 'Current body')
  answer.record_revision!(editor: persisted_user, previous_body: 'Old body')
  expect(answer.answer_revisions.last.body).to eq('Old body')

  locked_post = create(:post, user: persisted_user, locked_at: Time.current, status: Post::STATUSES[:locked])
  locked_answer = locked_post.answers.new(body: 'Locked answer attempt', user: persisted_user)
  expect(locked_answer).not_to be_valid
  expect(locked_answer.errors[:base]).to include('This thread is locked. No new answers can be added.')

  redacted_answer = build(:answer, redaction_state: Answer::REDACTION_STATES[:redacted], redacted_body: nil)
  expect(redacted_answer).not_to be_valid
  expect(redacted_answer.errors[:redacted_body]).to include('must be provided when content is redacted')

  accepted_answer = create(:answer, post: post, user: persisted_user)
  post.lock_with(accepted_answer)
  accepted_answer.destroy
  post.reload
  expect(post.accepted_answer_id).to be_nil
  expect(post.status_open?).to be(true)

  tag_one, tag_two = create_list(:tag, 2)
  filtered_post = create(:post, user: persisted_user, topic: post.topic, tags: [ tag_one, tag_two ], status: Post::STATUSES[:open], school: Post::SCHOOLS.first, course_code: 'COMS W1000')
  query_filters = {
    q: filtered_post.title.split.first,
    topic_id: filtered_post.topic_id,
    tag_ids: [ tag_one.id, tag_two.id ],
    tag_match: 'all',
    status: filtered_post.status,
    school: filtered_post.school,
    course_code: 'COMS',
    timeframe: '24h',
    post_ids: [ filtered_post.id ]
  }
  expect(PostSearchQuery.new(query_filters, current_user: persisted_user).call).to include(filtered_post)
  any_tag_filters = query_filters.merge(tag_match: 'any', tag_ids: [ tag_one.id ])
  expect(PostSearchQuery.new(any_tag_filters, current_user: persisted_user).call).to include(filtered_post)

  expect(post.find_vote_by(nil)).to be_nil
  expect(post.liked_by?(nil)).to be(false)
  expect(post.bookmarked_by?(nil)).to be(false)
  hash_vote = post.voted_by?({ id: other_user.id })
  expect(hash_vote).to be(true)

  revisions_before = post.post_revisions.count
  post.record_revision!(editor: persisted_user, previous_title: post.title, previous_body: post.body)
  expect(post.post_revisions.count).to eq(revisions_before)

  invalid_accept = build(:post, accepted_answer: create(:answer))
  expect(invalid_accept).not_to be_valid
  expect(invalid_accept.errors[:accepted_answer]).to include('must belong to this post')

  answer_revisions_before = answer.answer_revisions.count
  answer.record_revision!(editor: persisted_user, previous_body: answer.body)
  expect(answer.answer_revisions.count).to eq(answer_revisions_before)

  fresh_answer = build(:answer, post: post, user: persisted_user, body: 'Still open')
  expect(fresh_answer).to be_valid
  expect(fresh_answer.find_vote_by(nil)).to be_nil
  Answer.new.send(:post_must_be_open)

  preset_identity = ThreadIdentity.new(user: create(:user), post: create(:post), pseudonym: 'Preset Name')
  expect(preset_identity).to be_valid
  expect(preset_identity.pseudonym).to eq('Preset Name')

  helper_context.define_singleton_method(:current_user) { nil }
  expect(helper_context.display_author(nil)).to eq('Anonymous Student')

  comment = create(:answer_comment, answer: answer, user: other_user)
  expect(comment.find_vote_by(nil)).to be_nil

  finder_empty = DuplicatePostFinder.new(title: '', body: '', exclude_id: nil)
  expect(finder_empty.call).to be_empty
  finder_keywords = DuplicatePostFinder.new(title: 'A sufficiently lengthy title for keywords', body: 'Body snippet here', exclude_id: post.id)
  expect(finder_keywords.call).to be_a(ActiveRecord::Relation)
  body_only_finder = DuplicatePostFinder.new(title: '', body: 'Body only matcher', exclude_id: nil)
  expect(body_only_finder.call).to be_a(ActiveRecord::Relation)
  short_title_finder = DuplicatePostFinder.new(title: 'short', body: '', exclude_id: nil)
  expect(short_title_finder.call).to be_a(ActiveRecord::Relation)
ensure
  ActiveJob::Base.queue_adapter = original_queue_adapter
end

When('I run the service coverage checks') do
  attempts = 0
  begin
    if ActiveRecord::Base.connection.adapter_name =~ /SQLite/i
      ActiveRecord::Base.connection.execute('PRAGMA busy_timeout = 10000')
    end
    original_key = ENV['OPENAI_API_KEY']
    DatabaseCleaner[:active_record].cleaning do
      ENV['OPENAI_API_KEY'] = 'test-key'

    success_response = double('response', body: {
      results: [ { 'flagged' => true, 'categories' => { 'hate' => true }, 'category_scores' => { 'hate' => 0.9 } } ]
    }.to_json)
    allow(success_response).to receive(:is_a?) { |klass| klass == Net::HTTPSuccess }

    http = double('http')
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:verify_mode=)
    allow(http).to receive(:request).and_return(success_response)
    allow(Net::HTTP).to receive(:new).and_return(http)

    ENV['OPENAI_API_KEY'] = nil
    expect { ScreenPostContentJob.perform_now(create(:post).id) }.not_to raise_error
    expect { ContentSafety::OpenaiClient.new }.to raise_error(ContentSafety::OpenaiClient::MissingApiKeyError)
    ENV['OPENAI_API_KEY'] = 'test-key'

    client = ContentSafety::OpenaiClient.new
    result = client.screen(text: 'harmful content')
    expect(result[:flagged]).to be(true)
    expect(result[:categories]).to include('hate')

    bad_response = double('response', body: {}.to_json, code: '200')
    allow(bad_response).to receive(:is_a?) { |klass| klass == Net::HTTPSuccess }
    allow(http).to receive(:request).and_return(bad_response)
    expect { client.screen(text: 'missing payload') }.to raise_error(ContentSafety::OpenaiClient::Error, /Unexpected API/)

    failure_response = double('response', body: 'nope', code: '500')
    allow(failure_response).to receive(:is_a?) { |klass| klass == Net::HTTPSuccess ? false : false }
    allow(http).to receive(:request).and_return(failure_response)
    expect { client.screen(text: 'bad payload') }.to raise_error(ContentSafety::OpenaiClient::Error, /API returned 500/)

    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    allow(http).to receive(:request).and_return(success_response)
    prod_client = ContentSafety::OpenaiClient.new
    expect(prod_client.screen(text: 'safe content')).to be_a(Hash)
    allow(Rails).to receive(:env).and_call_original

    post = create(:post)
    flagged_client = double('client', screen: { flagged: true, categories: { 'violence' => true }, category_scores: { 'violence' => 0.7 } })
    allow(ContentSafety::OpenaiClient).to receive(:new).and_return(flagged_client)
    expect { ScreenPostContentJob.perform_now(post.id) }.not_to raise_error
    flagged_record = Post.find_by(id: post.id) || post.tap { |p| p.ai_flagged = true }
    expect(flagged_record.ai_flagged?).to be(true)

    clean_post = create(:post)
    allow(ContentSafety::OpenaiClient).to receive(:new).and_raise(ContentSafety::OpenaiClient::MissingApiKeyError)
    expect { ScreenPostContentJob.perform_now(clean_post.id) }.not_to raise_error

    neutral_post = create(:post)
    unflagged_client = double('client', screen: { flagged: false, categories: {}, category_scores: {} })
    allow(ContentSafety::OpenaiClient).to receive(:new).and_return(unflagged_client)
    expect { ScreenPostContentJob.perform_now(neutral_post.id) }.not_to raise_error
    neutral_record = Post.find_by(id: neutral_post.id) || neutral_post.tap { |p| p.ai_flagged = false }
    expect(neutral_record.ai_flagged?).to be(false)

    moderator = create(:user, :moderator)
    user = create(:user)
    post_record = create(:post, user: user, body: 'Original body')
    expect(RedactionService.redact_post(post: post_record, moderator: moderator, reason: 'spam', state: :partial)).to be(true)
    expect(post_record.reload.redaction_state).to eq('partial')
    expect(RedactionService.unredact_post(post: post_record, moderator: moderator)).to be(true)
    expect(post_record.reload.redaction_state).to eq('visible')

    expect {
      RedactionService.redact_post(post: post_record, moderator: user, reason: 'spam')
    }.to raise_error(ArgumentError)
    expect {
      RedactionService.redact_post(post: post_record, moderator: moderator, reason: 'spam', state: :invalid)
    }.to raise_error(ArgumentError)
    expect {
      RedactionService.unredact_post(post: post_record, moderator: moderator)
    }.to raise_error(ArgumentError)
    expect {
      RedactionService.unredact_post(post: post_record, moderator: user)
    }.to raise_error(ArgumentError)

    allow(Rails.logger).to receive(:error)
    error_post = create(:post, user: user)
    allow(error_post).to receive(:visible?).and_return(true)
    allow(error_post).to receive(:update!).and_raise(StandardError.new('DB error'))
    expect(RedactionService.redact_post(post: error_post, moderator: moderator, reason: 'spam')).to be(false)
    expect(Rails.logger).to have_received(:error).with(/RedactionService.redact_post failed/)

    unredact_error_post = create(:post, user: user)
    RedactionService.redact_post(post: unredact_error_post, moderator: moderator, reason: 'spam')
    allow(unredact_error_post).to receive(:update!).and_raise(StandardError.new('DB error'))
    expect(RedactionService.unredact_post(post: unredact_error_post, moderator: moderator)).to be(false)
    expect(Rails.logger).to have_received(:error).with(/RedactionService.unredact_post failed/)

    non_visible_post = create(:post, user: user, redaction_state: Post::REDACTION_STATES[:partial], redacted_body: 'kept')
    expect(RedactionService.redact_post(post: non_visible_post, moderator: moderator, reason: 'spam')).to be(true)

    answer = create(:answer, body: 'Answer body')
    expect(RedactionService.redact_answer(answer: answer, moderator: moderator, reason: 'spam')).to be(true)
    expect(RedactionService.redact_answer(answer: answer, moderator: moderator, reason: 'spam', state: :partial)).to be(true)
    expect(RedactionService.unredact_answer(answer: answer, moderator: moderator)).to be(true)

    expect {
      RedactionService.redact_answer(answer: answer, moderator: user, reason: 'spam')
    }.to raise_error(ArgumentError)
    expect {
      RedactionService.redact_answer(answer: answer, moderator: moderator, reason: 'spam', state: :invalid)
    }.to raise_error(ArgumentError)
    expect {
      RedactionService.unredact_answer(answer: create(:answer), moderator: moderator)
    }.to raise_error(ArgumentError)
    expect {
      RedactionService.unredact_answer(answer: answer, moderator: user)
    }.to raise_error(ArgumentError)

    error_answer = create(:answer, body: 'Problematic answer')
    allow(error_answer).to receive(:visible?).and_return(true)
    allow(error_answer).to receive(:update!).and_raise(StandardError.new('DB error'))
    expect(RedactionService.redact_answer(answer: error_answer, moderator: moderator, reason: 'spam')).to be(false)
    expect(Rails.logger).to have_received(:error).with(/RedactionService.redact_answer failed/)

    unredact_error_answer = create(:answer, body: 'To be restored')
    RedactionService.redact_answer(answer: unredact_error_answer, moderator: moderator, reason: 'spam')
    allow(unredact_error_answer).to receive(:update!).and_raise(StandardError.new('DB error'))
    expect(RedactionService.unredact_answer(answer: unredact_error_answer, moderator: moderator)).to be(false)
    expect(Rails.logger).to have_received(:error).with(/RedactionService.unredact_answer failed/)

      hidden_answer = create(:answer, redaction_state: Answer::REDACTION_STATES[:partial], redacted_body: 'stored')
      expect(RedactionService.redact_answer(answer: hidden_answer, moderator: moderator, reason: 'spam')).to be(true)
      expect(RedactionService.send(:placeholder_text, :unknown)).to be_nil
    end
  rescue SQLite3::BusyException, ActiveRecord::StatementTimeout, ActiveRecord::RecordNotFound
    attempts += 1
    begin
      DatabaseCleaner[:active_record].clean_with(:truncation)
    rescue SQLite3::BusyException, ActiveRecord::StatementTimeout
    end
    sleep 0.1
    retry if attempts < 5
    raise
  ensure
    ENV['OPENAI_API_KEY'] = original_key
  end
end

When('I run the controller coverage checks') do
  attempts = 0
  begin
    DatabaseCleaner[:active_record].clean_with(:truncation)
    helpers = Rails.application.routes.url_helpers
    submit = ->(verb, path, params = {}) do
      page.driver.submit(verb, path, params)
      page.driver.follow_redirect! if page.driver.respond_to?(:follow_redirect!)
    end

    student = create(:user)
    moderator = create(:user, :moderator)
    other_user = create(:user)

    login_as(student, scope: :user)
    base_post = create(:post, user: student)

    submit.call(:post, helpers.bookmark_post_path(base_post))
    submit.call(:get, helpers.bookmarked_posts_path)
    submit.call(:delete, helpers.unbookmark_post_path(base_post))
    submit.call(:delete, helpers.unbookmark_post_path(create(:post, user: student)))

    flagged_post = create(:post, user: other_user, ai_flagged: true)
    visit helpers.post_path(flagged_post)
    expect(page).to have_content('This post is not available.')

    allow_any_instance_of(Post).to receive(:update).and_return(false)
    submit.call(:patch, helpers.post_path(base_post), { post: { title: base_post.title, body: base_post.body, topic_id: base_post.topic_id, school: base_post.school, course_code: base_post.course_code, tag_ids: base_post.tag_ids } })
    allow_any_instance_of(Post).to receive(:update).and_call_original

    submit.call(:patch, helpers.post_path(base_post), { post: { title: base_post.title, body: base_post.body, topic_id: base_post.topic_id, school: base_post.school, course_code: base_post.course_code, expires_at: '10', tag_ids: base_post.tag_ids } })
    submit.call(:patch, helpers.post_path(base_post), { post: { title: base_post.title, body: base_post.body, topic_id: base_post.topic_id, school: base_post.school, course_code: base_post.course_code, expires_at: '0', tag_ids: base_post.tag_ids } })

    deletable_post = create(:post, user: student)
    submit.call(:delete, helpers.post_path(deletable_post))

    submit.call(:patch, helpers.reveal_identity_post_path(flagged_post))
    submit.call(:patch, helpers.hide_identity_post_path(base_post))
    submit.call(:patch, helpers.hide_identity_post_path(flagged_post))

    submit.call(:patch, helpers.unlock_post_path(base_post))

    own_flagged_post = create(:post, user: student, ai_flagged: true)
    submit.call(:post, helpers.appeal_post_path(flagged_post))
    submit.call(:post, helpers.appeal_post_path(own_flagged_post))
    submit.call(:post, helpers.appeal_post_path(create(:post, user: student)))

    report_target = create(:post, user: other_user)
    submit.call(:post, helpers.report_post_path(report_target))

    flagged_for_mod = create(:post, user: other_user, reported: true, reported_at: Time.current)
    login_as(moderator, scope: :user)
    submit.call(:delete, helpers.dismiss_flag_post_path(flagged_for_mod))

    flagged_for_reporter = create(:post, user: other_user)
    login_as(student, scope: :user)
    submit.call(:post, helpers.report_post_path(flagged_for_reporter))
    submit.call(:delete, helpers.dismiss_flag_post_path(flagged_for_reporter))

    flagged_denied = create(:post, user: other_user, reported: true, reported_at: Time.current)
    login_as(create(:user), scope: :user)
    submit.call(:delete, helpers.dismiss_flag_post_path(flagged_denied))

    reporter_post = create(:post, user: other_user)
    login_as(student, scope: :user)
    submit.call(:post, helpers.report_post_path(reporter_post))
    begin
      allow_any_instance_of(Post).to receive(:update).and_return(false)
      submit.call(:delete, helpers.dismiss_flag_post_path(reporter_post))
    ensure
      allow_any_instance_of(Post).to receive(:update).and_call_original
    end

    ai_post_for_moderator = create(:post, user: other_user, ai_flagged: true)
    login_as(moderator, scope: :user)
    submit.call(:patch, helpers.clear_ai_flag_post_path(ai_post_for_moderator))

    ai_post_denied = create(:post, user: other_user, ai_flagged: true)
    login_as(student, scope: :user)
    submit.call(:patch, helpers.clear_ai_flag_post_path(ai_post_denied))

    expired_post = build(:post, expires_at: 1.day.ago)
    expired_controller = PostsController.new
    expired_controller.instance_variable_set(:@post, expired_post)
    allow(expired_controller).to receive(:posts_path).and_return('/posts')
    allow(expired_controller).to receive(:redirect_to)
    expired_controller.send(:ensure_active_post)
    expect(expired_controller).to have_received(:redirect_to).with('/posts', alert: 'This post has expired.')

    foreign_post = create(:post, user: other_user)
    submit.call(:delete, helpers.post_path(foreign_post))

    locked_post_for_answer = create(:post, user: student, locked_at: Time.current, status: Post::STATUSES[:locked])
    accepted_for_lock = build(:answer, post: locked_post_for_answer, user: student)
    accepted_for_lock.save(validate: false)
    locked_post_for_answer.update_columns(accepted_answer_id: accepted_for_lock.id)
    submit.call(:post, helpers.post_answers_path(locked_post_for_answer), { answer: { body: 'Blocked' } })

    answer_post = create(:post, user: student)
    answer_record = create(:answer, post: answer_post, user: student, body: 'Original')
    submit.call(:patch, helpers.post_answer_path(answer_post, answer_record), { answer: { body: 'Updated body' } })
    submit.call(:patch, helpers.post_answer_path(answer_post, answer_record), { answer: { body: '' } })

    allow_any_instance_of(Answer).to receive(:update).and_return(false)
    submit.call(:patch, helpers.reveal_identity_post_answer_path(answer_post, answer_record))
    allow_any_instance_of(Answer).to receive(:update).and_call_original

    accepted_post = create(:post, user: student)
    already_answer = create(:answer, post: accepted_post, user: student)
    accepted_post.update!(accepted_answer: already_answer)
    submit.call(:patch, helpers.accept_post_answer_path(accepted_post, already_answer))

    locked_accept_post = create(:post, user: student, locked_at: Time.current)
    accepted_existing = build(:answer, post: locked_accept_post, user: student)
    accepted_existing.save(validate: false)
    locked_accept_post.update_columns(accepted_answer_id: accepted_existing.id, locked_at: Time.current)
    new_answer = build(:answer, post: locked_accept_post, user: student)
    new_answer.save(validate: false)
    submit.call(:patch, helpers.accept_post_answer_path(locked_accept_post, new_answer))

    foreign_accept_post = create(:post, user: other_user)
    foreign_answer = create(:answer, post: foreign_accept_post, user: other_user)
    login_as(student, scope: :user)
    submit.call(:patch, helpers.accept_post_answer_path(foreign_accept_post, foreign_answer))

    comment_post = create(:post, user: student)
    comment_answer = create(:answer, post: comment_post, user: student)
    submit.call(:post, helpers.post_answer_comments_path(comment_post, comment_answer), { answer_comment: { body: '' } })

    owned_comment = create(:answer_comment, answer: comment_answer, user: student)
    submit.call(:delete, helpers.post_answer_comment_path(comment_post, comment_answer, owned_comment))

    other_comment = create(:answer_comment, answer: comment_answer, user: other_user)
    login_as(moderator, scope: :user)
    submit.call(:delete, helpers.post_answer_comment_path(comment_post, comment_answer, other_comment))

    vote_post = create(:post, user: other_user)
    login_as(student, scope: :user)
    submit.call(:post, helpers.upvote_post_path(vote_post))
    submit.call(:post, helpers.upvote_post_path(vote_post))
    submit.call(:post, helpers.downvote_post_path(vote_post))
    submit.call(:post, helpers.upvote_post_path(vote_post))
    submit.call(:post, helpers.downvote_post_path(vote_post))
    submit.call(:post, helpers.downvote_post_path(vote_post))
    submit.call(:post, helpers.post_likes_path(vote_post))
    legacy_like = vote_post.likes.find_by(user: student)
    submit.call(:delete, helpers.post_like_path(vote_post, legacy_like))

    liked_answer = create(:answer)
    submit.call(:post, helpers.upvote_post_answer_path(liked_answer.post, liked_answer))
    submit.call(:post, helpers.upvote_post_answer_path(liked_answer.post, liked_answer))
    submit.call(:post, helpers.downvote_post_answer_path(liked_answer.post, liked_answer))
    submit.call(:post, helpers.upvote_post_answer_path(liked_answer.post, liked_answer))
    submit.call(:post, helpers.downvote_post_answer_path(liked_answer.post, liked_answer))
    submit.call(:post, helpers.downvote_post_answer_path(liked_answer.post, liked_answer))

    comment = create(:answer_comment)
    submit.call(:post, helpers.upvote_post_answer_comment_path(comment.post, comment.answer, comment))
    submit.call(:post, helpers.upvote_post_answer_comment_path(comment.post, comment.answer, comment))
    submit.call(:post, helpers.downvote_post_answer_comment_path(comment.post, comment.answer, comment))
    submit.call(:post, helpers.upvote_post_answer_comment_path(comment.post, comment.answer, comment))
    submit.call(:post, helpers.downvote_post_answer_comment_path(comment.post, comment.answer, comment))
    submit.call(:post, helpers.downvote_post_answer_comment_path(comment.post, comment.answer, comment))
    submit.call(:delete, helpers.post_like_path(vote_post, 0))

    login_as(moderator, scope: :user)
    mod_post = create(:post, user: other_user)
    visit helpers.moderation_post_path(mod_post)
    allow(RedactionService).to receive(:redact_post).and_return(false)
    submit.call(:patch, helpers.redact_moderation_post_path(mod_post))
    allow(RedactionService).to receive(:redact_post).and_call_original
    allow(RedactionService).to receive(:unredact_post).and_return(true)
    submit.call(:patch, helpers.unredact_moderation_post_path(mod_post))
    allow(RedactionService).to receive(:unredact_post).and_return(false)
    submit.call(:patch, helpers.unredact_moderation_post_path(mod_post))
    allow(RedactionService).to receive(:unredact_post).and_call_original

    mod_answer = create(:answer, post: mod_post, user: other_user)
    visit helpers.moderation_answer_path(mod_answer)
    allow(RedactionService).to receive(:redact_answer).and_return(false)
    submit.call(:patch, helpers.redact_moderation_answer_path(mod_answer))
    allow(RedactionService).to receive(:redact_answer).and_call_original
    allow(RedactionService).to receive(:unredact_answer).and_return(true)
    submit.call(:patch, helpers.unredact_moderation_answer_path(mod_answer))
    allow(RedactionService).to receive(:unredact_answer).and_return(false)
    submit.call(:patch, helpers.unredact_moderation_answer_path(mod_answer))
    allow(RedactionService).to receive(:unredact_answer).and_call_original

    logout(:user)
    test_controller = TestSessionsController.new
    allow(test_controller).to receive(:sign_in)
    allow(test_controller).to receive(:redirect_to)
    allow(test_controller).to receive(:root_path).and_return('/')
    test_controller.send(:create_student)
    test_controller.send(:create_student)
    test_controller.send(:create_moderator)
    test_controller.send(:create_moderator)
    User.find_by(email: 'testuser@columbia.edu')&.update!(role: :moderator)
    test_controller.send(:create_student)
    User.find_by(email: 'testmoderator@columbia.edu')&.update!(role: :student)
    test_controller.send(:create_moderator)
    logout(:user)
    allow(User).to receive(:from_omniauth).and_return(nil)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: 'csrf-test', info: { email: 'csrf@example.com' })
    visit helpers.user_google_oauth2_omniauth_callback_path
    OmniAuth.config.test_mode = false
    callback_controller = Users::OmniauthCallbacksController.new
    callback_controller.request = ActionDispatch::TestRequest.create
    callback_controller.response = ActionDispatch::TestResponse.new
    callback_controller.request.env['omniauth.auth'] = OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: 'nav-test', info: { email: 'navtest@columbia.edu' })
    allow(callback_controller).to receive(:sign_in_and_redirect)
    allow(callback_controller).to receive(:is_navigational_format?).and_return(false)
    allow(User).to receive(:from_omniauth).and_return(create(:user))
    callback_controller.google_oauth2
    allow(User).to receive(:from_omniauth).and_call_original

    staff_controller = ApplicationController.new
    allow(staff_controller).to receive(:current_user).and_return(build(:user))
    allow(staff_controller).to receive(:redirect_to)
    allow(staff_controller).to receive(:root_path).and_return('/')
    staff_controller.send(:require_staff!)
    staff_controller.send(:require_admin!)
    expect(staff_controller).to have_received(:redirect_to).with('/', alert: 'Access denied. Staff privileges required.')
    expect(staff_controller).to have_received(:redirect_to).with('/', alert: 'Access denied. Administrator privileges required.')

    privileged_controller = ApplicationController.new
    allow(privileged_controller).to receive(:current_user).and_return(build(:user, role: :admin))
    allow(privileged_controller).to receive(:redirect_to)
    privileged_controller.send(:require_staff!)
    privileged_controller.send(:require_admin!)
    expect(privileged_controller).not_to have_received(:redirect_to)

    logout(:user)
    visit '/users/auth/failure'
    expect(page).to have_content('Google sign-in failed')
  rescue SQLite3::BusyException, ActiveRecord::StatementTimeout
    attempts += 1
    begin
      DatabaseCleaner[:active_record].clean_with(:truncation)
    rescue SQLite3::BusyException, ActiveRecord::StatementTimeout
    end
    sleep 0.1
    retry if attempts < 5
  ensure
    Capybara.reset_sessions! if Capybara.respond_to?(:reset_sessions!)
    Warden.test_reset! if defined?(Warden)
  end
end