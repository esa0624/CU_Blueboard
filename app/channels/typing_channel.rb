# Channel for real-time typing indicators
# Shows "Lion #XXXX is typing..." in post threads
class TypingChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find_by(id: params[:post_id])
    if post
      stream_for post
    else
      reject
    end
  end

  def typing(data)
    post = Post.find_by(id: data['post_id'])
    return unless post

    pseudonym = ThreadIdentity.for(current_user, post).pseudonym
    TypingChannel.broadcast_to(post, {
      action: 'typing',
      user: pseudonym,
      typing: data['typing']
    })
  end

  def unsubscribed
    stop_all_streams
  end
end
