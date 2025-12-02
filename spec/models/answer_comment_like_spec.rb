require 'rails_helper'

RSpec.describe AnswerCommentLike, type: :model do
  it 'is valid with unique user and answer_comment combination' do
    like = build(:answer_comment_like)
    expect(like).to be_valid
  end

  it 'is invalid if the same user votes on the same comment twice' do
    user = create(:user)
    comment = create(:answer_comment)
    create(:answer_comment_like, user: user, answer_comment: comment)

    duplicate_like = build(:answer_comment_like, user: user, answer_comment: comment)
    expect(duplicate_like).not_to be_valid
    expect(duplicate_like.errors[:user_id]).to include('has already been taken')
  end

  describe '#upvote?' do
    it 'returns true for upvote' do
      like = build(:answer_comment_like, :upvote)
      expect(like.upvote?).to be true
    end

    it 'returns false for downvote' do
      like = build(:answer_comment_like, :downvote)
      expect(like.upvote?).to be false
    end
  end

  describe '#downvote?' do
    it 'returns true for downvote' do
      like = build(:answer_comment_like, :downvote)
      expect(like.downvote?).to be true
    end

    it 'returns false for upvote' do
      like = build(:answer_comment_like, :upvote)
      expect(like.downvote?).to be false
    end
  end

  describe 'scopes' do
    let(:comment) { create(:answer_comment) }
    let!(:upvote1) { create(:answer_comment_like, :upvote, answer_comment: comment) }
    let!(:upvote2) { create(:answer_comment_like, :upvote, answer_comment: comment) }
    let!(:downvote1) { create(:answer_comment_like, :downvote, answer_comment: comment) }

    describe '.upvotes' do
      it 'returns only upvotes' do
        expect(comment.answer_comment_likes.upvotes.count).to eq(2)
        expect(comment.answer_comment_likes.upvotes).to include(upvote1, upvote2)
        expect(comment.answer_comment_likes.upvotes).not_to include(downvote1)
      end
    end

    describe '.downvotes' do
      it 'returns only downvotes' do
        expect(comment.answer_comment_likes.downvotes.count).to eq(1)
        expect(comment.answer_comment_likes.downvotes).to include(downvote1)
        expect(comment.answer_comment_likes.downvotes).not_to include(upvote1, upvote2)
      end
    end
  end

  describe 'AnswerComment voting methods' do
    let(:user) { create(:user) }
    let(:comment) { create(:answer_comment) }

    describe '#find_vote_by' do
      it 'returns the vote when user has voted' do
        like = create(:answer_comment_like, user: user, answer_comment: comment)
        expect(comment.find_vote_by(user)).to eq(like)
      end

      it 'returns nil when user has not voted' do
        expect(comment.find_vote_by(user)).to be_nil
      end

      it 'returns nil when user is nil' do
        expect(comment.find_vote_by(nil)).to be_nil
      end
    end

    describe '#upvotes_count and #downvotes_count' do
      it 'counts votes correctly' do
        create(:answer_comment_like, :upvote, answer_comment: comment)
        create(:answer_comment_like, :upvote, answer_comment: comment)
        create(:answer_comment_like, :downvote, answer_comment: comment)

        expect(comment.upvotes_count).to eq(2)
        expect(comment.downvotes_count).to eq(1)
      end
    end

    describe '#net_score' do
      it 'calculates net score correctly' do
        create(:answer_comment_like, :upvote, answer_comment: comment)
        create(:answer_comment_like, :upvote, answer_comment: comment)
        create(:answer_comment_like, :downvote, answer_comment: comment)

        expect(comment.net_score).to eq(1)
      end
    end
  end
end
