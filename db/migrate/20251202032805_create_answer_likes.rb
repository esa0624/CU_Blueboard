class CreateAnswerLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :answer_likes do |t|
      t.references :answer, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :vote_type, null: false, default: 1

      t.timestamps
    end

    add_index :answer_likes, [ :user_id, :answer_id ], unique: true
  end
end
