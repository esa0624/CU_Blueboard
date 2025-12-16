class PostsController < ApplicationController
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :reveal_identity, :hide_identity, :unlock, :appeal, :bookmark, :unbookmark, :report, :dismiss_flag, :clear_ai_flag ]
  before_action :ensure_active_post, only: [ :show, :reveal_identity ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy, :unlock ]
  skip_before_action :authorize_owner!, only: [ :dismiss_flag, :clear_ai_flag ]
  before_action :load_taxonomies, only: [ :new, :create, :index, :my_threads, :bookmarked, :edit, :update ]

  # GET /posts
  def index
    build_filter_form
    @posts = PostSearchQuery.new(@filter_form, current_user: current_user).call
  end

  # GET /posts/my_threads
  def my_threads
    build_filter_form
    @viewing_my_threads = true
    filters = @filter_form.merge(author_id: current_user.id)
    @posts = PostSearchQuery.new(filters, current_user: current_user).call
    render :index
  end

  # GET /posts/bookmarked
  def bookmarked
    build_filter_form
    @viewing_bookmarked = true
    bookmarked_post_ids = current_user.bookmarks.pluck(:post_id)
    filters = @filter_form.merge(post_ids: bookmarked_post_ids)
    @posts = PostSearchQuery.new(filters, current_user: current_user).call
    render :index
  end

  # POST /posts/:id/bookmark
  def bookmark
    bookmark = current_user.bookmarks.build(post: @post)
    if bookmark.save
      redirect_back fallback_location: @post, notice: 'Post bookmarked.'
    else
      redirect_back fallback_location: @post, alert: 'Unable to bookmark this post.'
    end
  end

  # DELETE /posts/:id/unbookmark
  def unbookmark
    bookmark = current_user.bookmarks.find_by(post: @post)
    if bookmark&.destroy
      redirect_back fallback_location: @post, notice: 'Bookmark removed.'
    else
      redirect_back fallback_location: @post, alert: 'Unable to remove bookmark.'
    end
  end

  # GET /posts/1
  def show
    # Restrict access to AI-flagged posts: only author and moderators can view
    if @post.ai_flagged? && @post.user != current_user && !current_user.can_moderate?
      redirect_to posts_path, alert: 'This post is not available.'
      return
    end

    @answer = Answer.new
    @answers = @post.answers.includes(:user, { answer_comments: :user }, { answer_revisions: :user }).order(created_at: :asc)
  end

  # GET /posts/new
  def new
    @post = Post.new
    assign_duplicate_posts(@post)
  end

  # POST /posts
  def create
    @post = current_user.posts.new(post_params)
    assign_duplicate_posts(@post)

    if @duplicate_posts.present? && params[:confirm_duplicate] != 'true'
      flash.now[:alert] = 'Potential duplicate threads found. Please review them before posting.'
      render :new, status: :unprocessable_content
      return
    end

    if @post.save
      redirect_to posts_path, notice: 'Post was successfully created!'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    assign_duplicate_posts(@post)
  end

  def update
    previous_state = @post.slice(:title, :body)

    if @post.update(post_params)
      @post.record_revision!(editor: current_user, previous_title: previous_state[:title], previous_body: previous_state[:body])
      redirect_to @post, notice: 'Post updated.'
    else
      assign_duplicate_posts(@post)
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /posts/1
  def destroy
    @post.destroy
    redirect_to posts_url, notice: 'Post deleted.'
  end

  def reveal_identity
    if @post.user == current_user
      if @post.update(show_real_identity: true)
        AuditLog.record_identity_reveal(auditable: @post, actor: current_user)
        redirect_to @post, notice: 'Your identity is now visible on this thread.'
      else
        redirect_to @post, alert: 'Unable to reveal identity.'
      end
    else
      redirect_to @post, alert: 'You do not have permission to reveal this identity.'
    end
  end

  def hide_identity
    if @post.user == current_user
      if @post.update(show_real_identity: false)
        AuditLog.create!(
          user: current_user,
          performed_by: current_user,
          auditable: @post,
          action: 'identity_hidden',
          metadata: { post_id: @post.id }
        )
        redirect_to @post, notice: 'Your identity is now hidden on this thread.'
      else
        redirect_to @post, alert: 'Unable to hide identity.'
      end
    else
      redirect_to @post, alert: 'You do not have permission to hide this identity.'
    end
  end

  def unlock
    if @post.locked? && @post.accepted_answer.present?
      @post.unlock!
      redirect_to @post, notice: 'Thread reopened.'
    else
      redirect_to @post, alert: 'No accepted answer to unlock.'
    end
  end

  def appeal
    # Only the author of an AI-flagged post can appeal
    if @post.ai_flagged? && @post.user != current_user
      redirect_to posts_path, alert: 'This post is not available.'
      return
    end

    if @post.user == current_user && @post.ai_flagged?
      @post.request_appeal!
      redirect_to @post, notice: 'Appeal submitted. A moderator will review your request.'
    else
      redirect_to @post, alert: 'Unable to submit appeal.'
    end
  end

  def report
    if @post.reported_by?(current_user)
      redirect_to @post, alert: 'You have already reported this post.'
      return
    end

    if @post.user == current_user
      redirect_to @post, alert: 'You cannot report your own post.'
      return
    end

    reason = params[:reason].presence || 'inappropriate'
    report = @post.post_reports.build(user: current_user, reason: reason)

    if report.save
      @post.update(reported: true, reported_at: Time.current,
                   reported_reason: "#{@post.reports_count} report(s)")
      redirect_to @post, notice: 'Content reported to moderators.'
    else
      redirect_to @post, alert: report.errors.full_messages.to_sentence
    end
  end

  def dismiss_flag
    if current_user.can_moderate?
      @post.post_reports.destroy_all
      @post.update(reported: false, reported_at: nil, reported_reason: nil)
      redirect_to @post, notice: 'All reports dismissed.'
    else
      report = @post.post_reports.find_by(user: current_user)
      if report&.destroy
        if @post.post_reports.reload.empty?
          @post.update(reported: false, reported_at: nil, reported_reason: nil)
        else
          @post.update(reported_reason: "#{@post.reports_count} report(s)")
        end
        redirect_to @post, notice: 'Your report has been removed.'
      else
        redirect_to @post, alert: 'You have not reported this post.'
      end
    end
  end

  def clear_ai_flag
    unless current_user.can_moderate?
      redirect_to @post, alert: 'Permission denied.'
      return
    end

    if @post.update(ai_flagged: false)
      redirect_to @post, notice: 'AI flag cleared.'
    else
      redirect_to @post, alert: 'Unable to clear AI flag.'
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    permitted = params.require(:post).permit(
      :title,
      :body,
      :expires_at,
      :topic_id,
      :school,
      :course_code,
      :ai_flagged,
      tag_ids: []
    )
    permitted[:tag_ids] ||= []
    if permitted[:expires_at].blank?
      permitted[:expires_at] = nil
    else
      days = permitted[:expires_at].to_i
      permitted[:expires_at] = days.positive? ? Time.zone.now + days.days : nil
    end
    permitted
  end

  def filter_params
    return {} unless params[:filters].present?

    permitted = params.require(:filters).permit(:q, :topic_id, :status, :school, :course_code, :timeframe, :tag_match, tag_ids: [])
    permitted[:tag_ids] = Array(permitted[:tag_ids]).reject(&:blank?)
    permitted.to_h.with_indifferent_access
  end

  def ensure_active_post
    return if @post.expires_at.blank? || @post.expires_at.future?

    redirect_to posts_path, alert: 'This post has expired.'
  end

  def build_filter_form
    @filter_form = filter_params.presence || {}.with_indifferent_access
    flash.now[:alert] = 'Please enter text to search or choose a filter.' if blank_search_requested?
  end

  def authorize_owner!
    return if @post.user == current_user

    redirect_to @post, alert: 'You do not have permission to manage this thread.'
  end

  def load_taxonomies
    @topics = Topic.alphabetical
    @tags = Tag.alphabetical
  end

  def assign_duplicate_posts(post)
    finder = DuplicatePostFinder.new(title: post.title, body: post.body, exclude_id: post.id)
    @duplicate_posts = finder.call
  end

  def blank_search_requested?
    return false unless params[:filters].present?

    query_blank = @filter_form[:q].blank?
    # Note: school is intentionally excluded - "All Schools" (blank) is a valid filter
    # that searches both Columbia and Barnard
    other_blank = Array(@filter_form[:tag_ids]).reject(&:blank?).empty? &&
                  @filter_form[:topic_id].blank? &&
                  @filter_form[:status].blank? &&
                  @filter_form[:school].blank? &&
                  @filter_form[:course_code].blank? &&
                  @filter_form[:timeframe].blank?

    query_blank && other_blank
  end
end
