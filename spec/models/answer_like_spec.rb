require 'rails_helper'

RSpec.describe AnswerLike, type: :model do
  it 'is valid with unique user and answer combination' do
    like = build(:answer_like)
    expect(like).to be_valid
  end

  it 'is invalid if the same user votes on the same answer twice' do
    user = create(:user)
    answer = create(:answer)
    create(:answer_like, user: user, answer: answer)

    duplicate_like = build(:answer_like, user: user, answer: answer)
    expect(duplicate_like).not_to be_valid
    expect(duplicate_like.errors[:user_id]).to include('has already been taken')
  end

  describe '#upvote?' do
    it 'returns true for upvote' do
      like = build(:answer_like, :upvote)
      expect(like.upvote?).to be true
    end

    it 'returns false for downvote' do
      like = build(:answer_like, :downvote)
      expect(like.upvote?).to be false
    end
  end

  describe '#downvote?' do
    it 'returns true for downvote' do
      like = build(:answer_like, :downvote)
      expect(like.downvote?).to be true
    end

    it 'returns false for upvote' do
      like = build(:answer_like, :upvote)
      expect(like.downvote?).to be false
    end
  end

  describe 'scopes' do
    let(:answer) { create(:answer) }
    let!(:upvote1) { create(:answer_like, :upvote, answer: answer) }
    let!(:upvote2) { create(:answer_like, :upvote, answer: answer) }
    let!(:downvote1) { create(:answer_like, :downvote, answer: answer) }

    describe '.upvotes' do
      it 'returns only upvotes' do
        expect(answer.answer_likes.upvotes.count).to eq(2)
        expect(answer.answer_likes.upvotes).to include(upvote1, upvote2)
        expect(answer.answer_likes.upvotes).not_to include(downvote1)
      end
    end

    describe '.downvotes' do
      it 'returns only downvotes' do
        expect(answer.answer_likes.downvotes.count).to eq(1)
        expect(answer.answer_likes.downvotes).to include(downvote1)
        expect(answer.answer_likes.downvotes).not_to include(upvote1, upvote2)
      end
    end
  end

  describe 'Answer voting methods' do
    let(:user) { create(:user) }
    let(:answer) { create(:answer) }

    describe '#find_vote_by' do
      it 'returns the vote when user has voted' do
        like = create(:answer_like, user: user, answer: answer)
        expect(answer.find_vote_by(user)).to eq(like)
      end

      it 'returns nil when user has not voted' do
        expect(answer.find_vote_by(user)).to be_nil
      end

      it 'returns nil when user is nil' do
        expect(answer.find_vote_by(nil)).to be_nil
      end
    end

    describe '#upvotes_count and #downvotes_count' do
      it 'counts votes correctly' do
        create(:answer_like, :upvote, answer: answer)
        create(:answer_like, :upvote, answer: answer)
        create(:answer_like, :downvote, answer: answer)

        expect(answer.upvotes_count).to eq(2)
        expect(answer.downvotes_count).to eq(1)
      end
    end

    describe '#net_score' do
      it 'calculates net score correctly' do
        create(:answer_like, :upvote, answer: answer)
        create(:answer_like, :upvote, answer: answer)
        create(:answer_like, :downvote, answer: answer)

        expect(answer.net_score).to eq(1)
      end
    end
  end
end
