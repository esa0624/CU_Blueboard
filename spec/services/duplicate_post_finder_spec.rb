require 'rails_helper'

RSpec.describe DuplicatePostFinder do
  let!(:existing_post) { create(:post, title: 'Existing Post', body: 'Existing body content') }

  describe '#call' do
    it 'returns empty relation if title and body are blank' do
      finder = described_class.new(title: '', body: '')
      expect(finder.call).to be_empty
    end

    it 'finds exact title match' do
      finder = described_class.new(title: 'Existing Post', body: 'Different body')
      expect(finder.call).to include(existing_post)
    end

    it 'finds body snippet match' do
      finder = described_class.new(title: 'Different Title', body: 'Existing body content')
      expect(finder.call).to include(existing_post)
    end

    it 'finds keyword match' do
      # "Existing" is > 3 chars
      finder = described_class.new(title: 'Existing Stuff', body: 'Different body')
      expect(finder.call).to include(existing_post)
    end

    it 'handles short titles (no keyword extraction)' do
      finder = described_class.new(title: 'Hi', body: 'Existing body content')
      expect(finder.call).to include(existing_post)
    end

    it 'excludes specified id' do
      finder = described_class.new(title: 'Existing Post', body: 'Existing body content', exclude_id: existing_post.id)
      expect(finder.call).not_to include(existing_post)
    end

    it 'limits results' do
      create_list(:post, 6, title: 'Existing Post')
      finder = described_class.new(title: 'Existing Post', body: '')
      expect(finder.call.count).to eq(5)
    end
  end
end
