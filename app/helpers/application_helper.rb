module ApplicationHelper
  def display_author(user, context: nil)
    return 'Anonymous Student' unless user

    return real_identity_for(user) if reveal_real_identity?(context)

    return 'You' if current_user.present? && current_user == user

    thread = thread_from(context)
    return ThreadIdentity.for(user, thread).pseudonym if thread

    user.anonymous_handle
  end

  # Display author with pseudonym AND email for moderator views
  def display_author_for_moderator(user, context: nil)
    return 'Unknown' unless user

    thread = thread_from(context)
    pseudonym = thread ? ThreadIdentity.for(user, thread).pseudonym : user.anonymous_handle

    "#{pseudonym} (#{user.email})"
  end

  private

  def reveal_real_identity?(context)
    context.respond_to?(:show_real_identity) && context.show_real_identity?
  end

  def thread_from(context)
    return context if context.is_a?(Post)
    return context.post if context.respond_to?(:post)

    nil
  end

  def real_identity_for(user)
    user.email
  end
end
