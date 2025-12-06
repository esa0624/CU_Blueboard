class AddReportingToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :reported, :boolean, default: false, null: false
    add_column :posts, :reported_reason, :string
    add_column :posts, :reported_at, :datetime
  end
end
