module PostsHelper
  # Count active filters (excluding search query)
  def count_active_filters(filter_form)
    count = 0
    count += 1 if filter_form[:topic_id].present?
    count += 1 if filter_form[:status].present?
    count += 1 if filter_form[:school].present?
    count += 1 if filter_form[:course_code].present?
    count += 1 if filter_form[:timeframe].present?
    count += Array(filter_form[:tag_ids]).reject(&:blank?).size
    count
  end

  # Check if any filters are active (including search query)
  def has_active_filters?(filter_form)
    filter_form[:q].present? ||
      filter_form[:topic_id].present? ||
      filter_form[:status].present? ||
      filter_form[:school].present? ||
      filter_form[:course_code].present? ||
      filter_form[:timeframe].present? ||
      Array(filter_form[:tag_ids]).any?(&:present?)
  end
end
