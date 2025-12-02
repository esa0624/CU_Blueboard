class CreateAnswerCommentLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :answer_comment_likes do |t|
      t.references :answer_comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :vote_type, null: false, default: 1

      t.timestamps
    end

    add_index :answer_comment_likes, [ :user_id, :answer_comment_id ], unique: true
  end
end
