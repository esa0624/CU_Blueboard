class DuplicatePostFinder
  DEFAULT_LIMIT = 5

  def initialize(title:, body:, exclude_id: nil, limit: DEFAULT_LIMIT)
    @title = title.to_s.strip
    @body = body.to_s.strip
    @exclude_id = exclude_id
    @limit = limit
  end

  def call
    return Post.none if search_terms.empty?

    scope = Post.active.order(created_at: :desc)
    scope = scope.where.not(id: exclude_id) if exclude_id.present?
    scope.where(search_clause, *search_terms).limit(@limit)
  end

  private

  attr_reader :title, :body, :exclude_id

  def search_terms
    terms = []
    # Exact title match (high priority)
    terms << "%#{title.downcase}%" if title.present?

    # Body snippet match
    terms << "%#{body.downcase[0, 120]}%" if body.present?

    # Keyword matching from title (if title is long enough)
    if title.present? && title.length > 10
      keywords = title.downcase.split(/\s+/).select { |w| w.length > 3 }
      keywords.each do |keyword|
        terms << "%#{keyword}%"
      end
    end

    terms
  end

  def search_clause
    clauses = []
    clauses << 'LOWER(title) LIKE ?' if title.present?
    clauses << 'LOWER(body) LIKE ?' if body.present?

    if title.present? && title.length > 10
      keywords = title.downcase.split(/\s+/).select { |w| w.length > 3 }
      keywords.each do |_|
        clauses << 'LOWER(title) LIKE ?'
      end
    end

    clauses.join(' OR ')
  end
end
