require 'rails_helper'

RSpec.describe PostsHelper, type: :helper do
  describe '#count_active_filters' do
    it 'returns 0 for empty filter form' do
      filter_form = {}
      expect(helper.count_active_filters(filter_form)).to eq(0)
    end

    it 'counts topic_id filter' do
      filter_form = { topic_id: '1' }
      expect(helper.count_active_filters(filter_form)).to eq(1)
    end

    it 'counts status filter' do
      filter_form = { status: 'open' }
      expect(helper.count_active_filters(filter_form)).to eq(1)
    end

    it 'counts school filter' do
      filter_form = { school: 'Columbia' }
      expect(helper.count_active_filters(filter_form)).to eq(1)
    end

    it 'counts course_code filter' do
      filter_form = { course_code: 'COMS W4152' }
      expect(helper.count_active_filters(filter_form)).to eq(1)
    end

    it 'counts timeframe filter' do
      filter_form = { timeframe: '7d' }
      expect(helper.count_active_filters(filter_form)).to eq(1)
    end

    it 'counts multiple tag_ids' do
      filter_form = { tag_ids: %w[1 2 3] }
      expect(helper.count_active_filters(filter_form)).to eq(3)
    end

    it 'ignores blank tag_ids' do
      filter_form = { tag_ids: ['1', '', '2', ''] }
      expect(helper.count_active_filters(filter_form)).to eq(2)
    end

    it 'counts all active filters together' do
      filter_form = {
        topic_id: '1',
        status: 'open',
        school: 'Barnard',
        course_code: 'COMS',
        timeframe: '24h',
        tag_ids: %w[1 2]
      }
      expect(helper.count_active_filters(filter_form)).to eq(7)
    end
  end

  describe '#has_active_filters?' do
    it 'returns false for empty filter form' do
      filter_form = {}
      expect(helper.has_active_filters?(filter_form)).to be false
    end

    it 'returns true when q is present' do
      filter_form = { q: 'search term' }
      expect(helper.has_active_filters?(filter_form)).to be true
    end

    it 'returns true when topic_id is present' do
      filter_form = { topic_id: '1' }
      expect(helper.has_active_filters?(filter_form)).to be true
    end

    it 'returns true when status is present' do
      filter_form = { status: 'solved' }
      expect(helper.has_active_filters?(filter_form)).to be true
    end

    it 'returns true when school is present' do
      filter_form = { school: 'Columbia' }
      expect(helper.has_active_filters?(filter_form)).to be true
    end

    it 'returns true when course_code is present' do
      filter_form = { course_code: 'COMS' }
      expect(helper.has_active_filters?(filter_form)).to be true
    end

    it 'returns true when timeframe is present' do
      filter_form = { timeframe: '30d' }
      expect(helper.has_active_filters?(filter_form)).to be true
    end

    it 'returns true when tag_ids has non-blank values' do
      filter_form = { tag_ids: ['1'] }
      expect(helper.has_active_filters?(filter_form)).to be true
    end

    it 'returns false when tag_ids only has blank values' do
      filter_form = { tag_ids: ['', ''] }
      expect(helper.has_active_filters?(filter_form)).to be false
    end
  end
end
