class AddAiFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :ai_categories, :text
    add_column :posts, :ai_scores, :text
  end
end
