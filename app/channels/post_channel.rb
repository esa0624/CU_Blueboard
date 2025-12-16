# Channel for real-time updates on individual posts
# Broadcasts new answers and post updates to subscribers
class PostChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find_by(id: params[:post_id])
    if post
      stream_for post
    else
      reject
    end
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed
    stop_all_streams
  end
end
