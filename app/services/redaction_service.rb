# Service to handle redaction/unredaction of posts and answers
# Preserves original content and logs all moderation actions
class RedactionService
  # Redact a post
  # @param post [Post] The post to redact
  # @param moderator [User] The moderator performing the action
  # @param reason [String] The reason for redaction
  # @param state [Symbol] :redacted (full) or :partial (partial redaction)
  # @return [Boolean] true if successful
  def self.redact_post(post:, moderator:, reason:, state: :redacted)
    raise ArgumentError, 'Moderator must have moderation privileges' unless moderator.can_moderate?
    raise ArgumentError, 'Invalid redaction state' unless [ :redacted, :partial ].include?(state)

    ActiveRecord::Base.transaction do
      # Store original body if not already redacted
      if post.visible?
        post.redacted_body = post.body
      end

      # Update post state
      post.update!(
        redaction_state: state.to_s,
        redacted_by: moderator,
        redacted_reason: reason,
        body: placeholder_text(state)
      )

      # Log the action
      AuditLog.create!(
        user: post.user,
        performed_by: moderator,
        auditable: post,
        action: 'post_redacted',
        metadata: {
          post_id: post.id,
          moderator_id: moderator.id,
          moderator_email: moderator.email,
          reason: reason,
          state: state.to_s,
          timestamp: Time.current
        }
      )

      true
    end
  rescue ArgumentError => e
    raise e
  rescue StandardError => e
    Rails.logger.error("RedactionService.redact_post failed: #{e.message}")
    false
  end

  # Unredact a post (restore original content)
  # @param post [Post] The post to unredact
  # @param moderator [User] The moderator performing the action
  # @return [Boolean] true if successful
  def self.unredact_post(post:, moderator:)
    raise ArgumentError, 'Moderator must have moderation privileges' unless moderator.can_moderate?
    raise ArgumentError, 'Post is not redacted' if post.visible?

    ActiveRecord::Base.transaction do
      original_body = post.redacted_body || post.body

      post.update!(
        redaction_state: 'visible',
        body: original_body,
        redacted_by: nil,
        redacted_reason: nil,
        redacted_body: nil
      )

      # Log the restoration
      AuditLog.create!(
        user: post.user,
        performed_by: moderator,
        auditable: post,
        action: 'post_unredacted',
        metadata: {
          post_id: post.id,
          moderator_id: moderator.id,
          moderator_email: moderator.email,
          timestamp: Time.current
        }
      )

      true
    end
  rescue ArgumentError => e
    raise e
  rescue StandardError => e
    Rails.logger.error("RedactionService.unredact_post failed: #{e.message}")
    false
  end

  # Redact an answer
  # @param answer [Answer] The answer to redact
  # @param moderator [User] The moderator performing the action
  # @param reason [String] The reason for redaction
  # @param state [Symbol] :redacted (full) or :partial (partial redaction)
  # @return [Boolean] true if successful
  def self.redact_answer(answer:, moderator:, reason:, state: :redacted)
    raise ArgumentError, 'Moderator must have moderation privileges' unless moderator.can_moderate?
    raise ArgumentError, 'Invalid redaction state' unless [ :redacted, :partial ].include?(state)

    ActiveRecord::Base.transaction do
      # Store original body if not already redacted
      if answer.visible?
        answer.redacted_body = answer.body
      end

      # Update answer state
      answer.update!(
        redaction_state: state.to_s,
        redacted_by: moderator,
        redacted_reason: reason,
        body: placeholder_text(state)
      )

      # Log the action
      AuditLog.create!(
        user: answer.user,
        performed_by: moderator,
        auditable: answer,
        action: 'answer_redacted',
        metadata: {
          answer_id: answer.id,
          post_id: answer.post_id,
          moderator_id: moderator.id,
          moderator_email: moderator.email,
          reason: reason,
          state: state.to_s,
          timestamp: Time.current
        }
      )

      true
    end
  rescue ArgumentError => e
    raise e
  rescue StandardError => e
    Rails.logger.error("RedactionService.redact_answer failed: #{e.message}")
    false
  end

  # Unredact an answer (restore original content)
  # @param answer [Answer] The answer to unredact
  # @param moderator [User] The moderator performing the action
  # @return [Boolean] true if successful
  def self.unredact_answer(answer:, moderator:)
    raise ArgumentError, 'Moderator must have moderation privileges' unless moderator.can_moderate?
    raise ArgumentError, 'Answer is not redacted' if answer.visible?

    ActiveRecord::Base.transaction do
      original_body = answer.redacted_body || answer.body

      answer.update!(
        redaction_state: 'visible',
        body: original_body,
        redacted_by: nil,
        redacted_reason: nil,
        redacted_body: nil
      )

      # Log the restoration
      AuditLog.create!(
        user: answer.user,
        performed_by: moderator,
        auditable: answer,
        action: 'answer_unredacted',
        metadata: {
          answer_id: answer.id,
          post_id: answer.post_id,
          moderator_id: moderator.id,
          moderator_email: moderator.email,
          timestamp: Time.current
        }
      )

      true
    end
  rescue ArgumentError => e
    raise e
  rescue StandardError => e
    Rails.logger.error("RedactionService.unredact_answer failed: #{e.message}")
    false
  end

  private

  # Generate placeholder text based on redaction state
  def self.placeholder_text(state)
    case state
    when :redacted
      '[Content removed by CU moderators for policy violations]'
    when :partial
      '[Portions of this content have been redacted by CU moderators]'
    end
  end
end
