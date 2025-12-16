class CreatePostReports < ActiveRecord::Migration[8.1]
  def change
    create_table :post_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.string :reason, null: false, default: 'inappropriate'
      t.timestamps
    end

    add_index :post_reports, [:user_id, :post_id], unique: true
    add_column :posts, :reports_count, :integer, default: 0, null: false
    add_index :posts, :reports_count
  end
end
